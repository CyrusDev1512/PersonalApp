"""Pipeline xử lý giao dịch đến từ mọi nguồn.

lưu raw -> idempotency -> xác định TK -> khử trùng lặp / gộp -> ghép chuyển nội bộ -> tính lại số dư
-> phân loại -> đánh giá + ghi cảnh báo (outbox). Mọi hàm ở đây chạy dưới `write_lock`.
"""

from __future__ import annotations

import json
import logging
import traceback
from collections.abc import Callable, Mapping
from dataclasses import dataclass
from datetime import datetime, timedelta

from sqlmodel import Session, select

from app import clock
from app.engine.categorize import RuleIn, categorize
from app.ingest.accounts import resolve_account
from app.ingest.pairing import hold_deadline, looks_internal_in, looks_internal_out, try_pair
from app.ingest.schema import IgnoredPayload, NormalizedTx, ParseError
from app.models import Account, Alert, Category, CategoryRule, IngestEvent, Transaction, TransactionSource
from app.seed import category_by_key
from app.services.balance import has_webhook_coverage, recompute_balance
from app.services.notify import notify_new_account, reevaluate_and_notify

log = logging.getLogger(__name__)

SECRET_HEADERS = {"authorization", "x-sepay-signature", "x-casso-signature", "secure-token", "cookie", "x-api-key"}
PRECISION_RANK = {"second": 3, "minute": 2, "approx": 1, "date": 0}
EMAIL_PENDING_FOR = timedelta(hours=6)
NOTIFY_MAX_AGE = timedelta(hours=2)
MATCH_WINDOW = timedelta(minutes=15)
MATCH_WINDOW_APPROX = timedelta(minutes=60)


@dataclass
class IngestOutcome:
    status: str  # created | merged | duplicate | ignored
    transaction_id: int | None = None
    account_created: bool = False


# ---- raw event ------------------------------------------------------------------------------------------


def store_event(
    session: Session, source: str, headers: Mapping[str, str], payload_text: str, external_id: str | None = None
) -> IngestEvent:
    """Lưu payload gốc trong transaction riêng (đã bỏ header bí mật) trước khi xử lý."""
    safe = {k: v for k, v in headers.items() if k.lower() not in SECRET_HEADERS}
    ev = IngestEvent(source=source, external_id=external_id, headers_json=json.dumps(safe, ensure_ascii=False),
                     payload_text=payload_text)
    session.add(ev)
    session.commit()
    session.refresh(ev)
    return ev


def process_event(
    session: Session,
    event: IngestEvent,
    parse: Callable[[], list[NormalizedTx]],
    *,
    now: datetime | None = None,
    notify: bool = True,
) -> IngestEvent:
    """Parse + ingest một event; lỗi được ghi vào event, không ném ra ngoài."""
    now = now or clock.now()
    event_id = event.id
    try:
        ntxs = parse()
        outcomes = [ingest_tx(session, n, event_id=event_id, now=now, notify=notify) for n in ntxs]
        statuses = {o.status for o in outcomes}
        event = session.get(IngestEvent, event_id)
        if statuses <= {"ignored"}:
            event.status = "ignored"
        elif statuses <= {"duplicate", "ignored"}:
            event.status = "duplicate"
        else:
            event.status = "parsed"
        event.external_id = event.external_id or (ntxs[0].external_id if ntxs else None)
        event.transaction_id = next((o.transaction_id for o in outcomes if o.transaction_id), None)
        event.error = None
        session.add(event)
        session.commit()
    except IgnoredPayload as exc:
        session.rollback()
        mark_event(session, event_id, "ignored", str(exc))
    except ParseError as exc:
        session.rollback()
        mark_event(session, event_id, "unparsed", str(exc))
    except Exception:  # noqa: BLE001 - mọi lỗi khác: lưu traceback, không làm mất event
        session.rollback()
        log.exception("Lỗi xử lý ingest event %s", event_id)
        mark_event(session, event_id, "error", traceback.format_exc(limit=8))
    return session.get(IngestEvent, event_id)


def mark_event(session: Session, event_id: int, status: str, error: str | None) -> None:
    ev = session.get(IngestEvent, event_id)
    if ev is None:
        return
    ev.status = status
    ev.error = (error or "")[:4000] or None
    session.add(ev)
    session.commit()


# ---- ingest một giao dịch -------------------------------------------------------------------------------


def _rules(session: Session) -> list[RuleIn]:
    return [
        RuleIn(id=r.id, category_id=r.category_id, pattern=r.pattern, direction=r.direction, priority=r.priority,
               origin=r.origin)
        for r in session.exec(select(CategoryRule)).all()
    ]


def apply_category_rules(session: Session, tx: Transaction) -> None:
    income = category_by_key(session, "income")
    cat_id, _rule_id = categorize(tx.description, tx.direction, _rules(session), income.id if income else None)
    if cat_id is not None:
        tx.category_id = cat_id
        tx.categorized_by = "rule"


def _sources_of(session: Session, tx_id: int) -> set[str]:
    return set(session.exec(select(TransactionSource.source).where(TransactionSource.transaction_id == tx_id)).all())


def _norm_ref(ref: str | None) -> str | None:
    if not ref:
        return None
    r = "".join(ref.split()).upper()
    return r or None


def _within_window(a: Transaction, ntx: NormalizedTx) -> bool:
    precisions = {a.time_precision, ntx.time_precision}
    if "date" in precisions:
        return clock.to_ict(a.bank_time).date() == clock.to_ict(ntx.bank_time).date()
    window = MATCH_WINDOW_APPROX if "approx" in precisions else MATCH_WINDOW
    return abs(a.bank_time - ntx.bank_time) <= window


def find_match(session: Session, acc: Account, ntx: NormalizedTx) -> Transaction | None:
    """Tìm giao dịch đã có (từ nguồn khác) chính là giao dịch này."""
    cands = session.exec(
        select(Transaction).where(
            Transaction.account_id == acc.id,
            Transaction.direction == ntx.direction,
            Transaction.amount == ntx.amount,
            Transaction.is_manual == False,  # noqa: E712
            Transaction.bank_time >= ntx.bank_time - timedelta(days=1),
            Transaction.bank_time <= ntx.bank_time + timedelta(days=1),
        )
    ).all()
    ref = _norm_ref(ntx.reference_code)
    strong: list[Transaction] = []
    weak: list[Transaction] = []
    for c in cands:
        if ntx.source in _sources_of(session, c.id):
            continue  # mỗi giao dịch có tối đa 1 bản ghi từ mỗi nguồn
        if not _within_window(c, ntx):
            continue
        if c.balance_after is not None and ntx.balance_after is not None and c.balance_after != ntx.balance_after:
            continue  # cả hai đều biết số dư mà khác nhau -> chắc chắn là 2 giao dịch khác nhau
        same_balance = c.balance_after is not None and c.balance_after == ntx.balance_after
        same_ref = ref is not None and _norm_ref(c.reference_code) == ref
        (strong if same_balance or same_ref else weak).append(c)
    pool = strong or weak
    if not pool:
        return None
    return min(pool, key=lambda c: abs(c.bank_time - ntx.bank_time))


def _merge(session: Session, tx: Transaction, ntx: NormalizedTx) -> None:
    if ntx.balance_after is not None and (tx.balance_after is None or tx.balance_source == "email"):
        tx.balance_after = ntx.balance_after
        tx.balance_source = ntx.source
    tx.reference_code = tx.reference_code or ntx.reference_code
    tx.counter_account = tx.counter_account or ntx.counter_account
    tx.counter_name = tx.counter_name or ntx.counter_name
    if PRECISION_RANK.get(ntx.time_precision, 0) > PRECISION_RANK.get(tx.time_precision, 0):
        tx.bank_time = ntx.bank_time
        tx.time_precision = ntx.time_precision
    if ntx.description and (not tx.description or (ntx.source != "email" and "email" in _sources_of(session, tx.id))):
        tx.description = ntx.description
    if tx.categorized_by == "none" and tx.category_id is None:
        apply_category_rules(session, tx)
    tx.updated_at = clock.now()
    session.add(tx)


def _same_source_duplicate(session: Session, acc: Account, ntx: NormalizedTx) -> Transaction | None:
    ref = _norm_ref(ntx.reference_code)
    if ref is None:
        return None
    rows = session.exec(
        select(Transaction)
        .join(TransactionSource, TransactionSource.transaction_id == Transaction.id)
        .where(
            TransactionSource.source == ntx.source,
            Transaction.account_id == acc.id,
            Transaction.amount == ntx.amount,
            Transaction.direction == ntx.direction,
        )
    ).all()
    return next((t for t in rows if _norm_ref(t.reference_code) == ref), None)


def ingest_tx(
    session: Session, ntx: NormalizedTx, *, event_id: int | None, now: datetime | None = None, notify: bool = True
) -> IngestOutcome:
    now = now or clock.now()
    src = session.exec(
        select(TransactionSource).where(TransactionSource.source == ntx.source,
                                        TransactionSource.external_id == ntx.external_id)
    ).first()
    if src is not None:
        return IngestOutcome("duplicate", src.transaction_id)
    if ntx.is_test:
        return IngestOutcome("ignored")

    acc, created = resolve_account(session, ntx)
    if created:
        notify_new_account(session, acc)

    dup = _same_source_duplicate(session, acc, ntx)
    if dup is not None:
        session.add(TransactionSource(transaction_id=dup.id, source=ntx.source, external_id=ntx.external_id,
                                      ingest_event_id=event_id))
        session.commit()
        return IngestOutcome("duplicate", dup.id, created)

    match = find_match(session, acc, ntx)
    if match is not None:
        session.add(TransactionSource(transaction_id=match.id, source=ntx.source, external_id=ntx.external_id,
                                      ingest_event_id=event_id))
        if match.status == "excluded":
            # Người dùng đã loại trừ giao dịch này: bản sao từ nguồn khác cũng bị loại theo.
            session.commit()
            return IngestOutcome("merged", match.id, created)
        was_pending = match.status == "pending"
        _merge(session, match, ntx)
        if was_pending and ntx.source != "email":
            match.status, match.pending_until = "active", None
            match.quiet = match.quiet and not notify
        session.flush()
        if was_pending and match.status == "active":
            _activate(session, match, acc, notify=notify and not match.quiet, now=now)
        else:
            recompute_balance(session, acc, now)
            if not match.evaluated and match.status == "active":
                _evaluate_new(session, match, None, notify=notify and not match.quiet, now=now)
            elif notify:
                reevaluate_and_notify(session, reason="merge", now=now)
        session.commit()
        return IngestOutcome("merged", match.id, created)

    tx = Transaction(
        account_id=acc.id, direction=ntx.direction, amount=ntx.amount, bank_time=ntx.bank_time,
        time_precision=ntx.time_precision, description=ntx.description or "", reference_code=ntx.reference_code,
        counter_account=ntx.counter_account, counter_name=ntx.counter_name, balance_after=ntx.balance_after,
        balance_source=ntx.source if ntx.balance_after is not None else None, quiet=not notify,
    )
    # Email của TK có webhook: chờ webhook khớp (trừ email đã quá cũ, webhook sẽ không bao giờ tới nữa).
    if (ntx.source == "email" and now - ntx.bank_time <= EMAIL_PENDING_FOR
            and has_webhook_coverage(session, acc.id, now)):
        tx.status, tx.pending_until = "pending", now + EMAIL_PENDING_FOR
    apply_category_rules(session, tx)
    session.add(tx)
    session.flush()
    session.add(TransactionSource(transaction_id=tx.id, source=ntx.source, external_id=ntx.external_id,
                                  ingest_event_id=event_id))
    if tx.status == "active":
        _activate(session, tx, acc, notify=notify, now=now)
    else:
        recompute_balance(session, acc, now)
    session.commit()
    return IngestOutcome("created", tx.id, created)


def _activate(session: Session, tx: Transaction, acc: Account, *, notify: bool, now: datetime) -> None:
    """Giao dịch vừa được tính (mới, hoặc email chờ được xác nhận): ghép cặp / hoãn chờ ghép, số dư, thông báo."""
    paired = try_pair(session, tx, now)
    fresh = now - tx.bank_time <= NOTIFY_MAX_AGE
    if paired is None and notify and fresh and acc.include_in_total and acc.confirmed:
        internal = (looks_internal_out(session, tx) if tx.direction == "out"
                    else looks_internal_in(session, tx))
        if internal:
            tx.hold_until = hold_deadline(now)
            tx.category_id, tx.categorized_by = None, "none"
    session.flush()
    recompute_balance(session, acc, now)
    if paired is not None:
        other = session.get(Account, paired.account_id)
        if other is not None and other.id != acc.id:
            recompute_balance(session, other, now)
    _evaluate_new(session, tx, paired, notify=notify, now=now)


def _tx_alert(session: Session, tx_id: int) -> Alert | None:
    return session.exec(
        select(Alert).where(Alert.kind == "tx", Alert.transaction_id == tx_id).order_by(Alert.id.desc())
    ).first()


def _evaluate_new(
    session: Session, tx: Transaction, paired: Transaction | None, *, notify: bool, now: datetime
) -> None:
    """Đánh giá + thông báo cho một giao dịch vừa trở thành 'active'."""
    if tx.status != "active":
        return
    if not notify:
        tx.evaluated = True
        session.add(tx)
        return
    acc = session.get(Account, tx.account_id)
    if acc is None or not acc.include_in_total or not acc.confirmed:
        tx.evaluated = True
        session.add(tx)
        reevaluate_and_notify(session, reason="api_tx", now=now)
        return
    if paired is not None:
        out_half = tx if tx.direction == "out" else paired
        in_half = paired if out_half is tx else tx
        # Nửa nào đã có tin Telegram thì sửa tin đó thành "chuyển nội bộ"; chưa có tin nào thì gửi 1 tin.
        edited = False
        for half in (out_half, in_half):
            if half.evaluated and _tx_alert(session, half.id) is not None:
                reevaluate_and_notify(session, reason="pair", edit_tx=half, now=now)
                edited = True
        if not edited:
            if out_half.quiet and in_half.quiet:
                reevaluate_and_notify(session, reason="pair", now=now)
            else:
                reevaluate_and_notify(session, reason="pair", tx=out_half, now=now)
        for t in (out_half, in_half):
            t.evaluated = True
            session.add(t)
        return
    if tx.hold_until is not None and tx.hold_until > now:
        return  # chờ ghép chuyển nội bộ; job `tick` sẽ xử lý khi hết hạn
    if tx.quiet or now - tx.bank_time > NOTIFY_MAX_AGE:
        tx.evaluated = True
        session.add(tx)
        reevaluate_and_notify(session, reason="backfill", now=now)
        return
    reevaluate_and_notify(session, reason="tx", tx=tx, now=now)


# ---- job định kỳ ------------------------------------------------------------------------------------------


def tick(session: Session, now: datetime | None = None) -> bool:
    """Xử lý khoản chờ ghép cặp đã hết hạn và email đã chờ webhook quá lâu. Trả về True nếu có thay đổi."""
    now = now or clock.now()
    changed = False
    held = session.exec(
        select(Transaction).where(
            Transaction.hold_until != None,  # noqa: E711
            Transaction.hold_until <= now,
            Transaction.evaluated == False,  # noqa: E712
        )
    ).all()
    for tx in held:
        tx.hold_until = None
        session.add(tx)
        if tx.pair_id is None:
            apply_category_rules(session, tx)
        session.flush()
        if tx.status == "active":
            # Hết thời gian chờ mà không ghép được: thông báo như giao dịch thường (được hoãn nên không áp hạn tuổi)
            reevaluate_and_notify(session, reason="tx", tx=tx, now=now)
        changed = True
    pending = session.exec(
        select(Transaction).where(Transaction.status == "pending", Transaction.pending_until <= now)
    ).all()
    for tx in pending:
        tx.status, tx.pending_until = "active", None
        session.add(tx)
        session.flush()
        acc = session.get(Account, tx.account_id)
        if acc is None:
            continue
        if tx.quiet or tx.evaluated:
            _activate(session, tx, acc, notify=False, now=now)
            reevaluate_and_notify(session, reason="backfill", now=now)
        else:
            _activate_promoted(session, tx, acc, now)
        changed = True
    if changed:
        session.commit()
    return changed


def _activate_promoted(session: Session, tx: Transaction, acc: Account, now: datetime) -> None:
    """Email đã chờ webhook 6 giờ: vẫn gửi tin để người dùng phân loại, dù giao dịch đã cũ."""
    paired = try_pair(session, tx, now)
    session.flush()
    recompute_balance(session, acc, now)
    if paired is not None or not acc.include_in_total or not acc.confirmed:
        if paired is not None:
            other = session.get(Account, paired.account_id)
            if other is not None:
                recompute_balance(session, other, now)
        _evaluate_new(session, tx, paired, notify=True, now=now)
        return
    reevaluate_and_notify(session, reason="tx", tx=tx, now=now)


def category_kind(session: Session, category_id: int | None) -> str | None:
    if category_id is None:
        return None
    cat = session.get(Category, category_id)
    return cat.kind if cat else None
