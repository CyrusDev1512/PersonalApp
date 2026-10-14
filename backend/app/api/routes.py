"""Các endpoint /api/* cho app Flutter (xem docs/api.md)."""

from __future__ import annotations

from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlmodel import Session, func, select

from app import clock
from app.api import serialize as ser
from app.api.deps import require_token
from app.api.schemas import (
    AccountCreate,
    AccountUpdate,
    CategoryCreate,
    GoalCreate,
    GoalUpdate,
    RuleCreate,
    SettingsUpdate,
    TxCreate,
    TxUpdate,
)
from app.db import kv_get, session_scope, write_lock
from app.ingest.accounts import cash_account
from app.ingest.banks import canonical_bank
from app.models import Account, Alert, Category, CategoryRule, Goal, IngestEvent, Transaction, TransactionSource
from app.notify.outbox import wake_outbox
from app.services import runtime_settings, tx_actions
from app.services.balance import recompute_balance
from app.services.notify import reevaluate_and_notify
from app.services.summary import build_evaluation, uncategorized_count
from app.text import digits_only, normalize_pattern

router = APIRouter(prefix="/api", dependencies=[Depends(require_token)])


def _bad(msg: str) -> HTTPException:
    return HTTPException(status.HTTP_400_BAD_REQUEST, msg)


def _404(what: str) -> HTTPException:
    return HTTPException(status.HTTP_404_NOT_FOUND, f"Không tìm thấy {what}")


def _month_param(month: str | None) -> str:
    if month is None:
        return clock.current_month()
    if not clock.is_valid_month(month):
        raise _bad("month phải có dạng YYYY-MM")
    return month


# ---- summary ----------------------------------------------------------------------------------------------


def _last_event(s: Session, source: str) -> str | None:
    return (kv_get(s, f"health:{source}", {}) or {}).get("last_event_at")


def ingest_health(s: Session) -> dict:
    from app.config import get_settings

    cfg = get_settings()
    since = clock.now() - timedelta(days=7)
    counts = dict(s.exec(
        select(IngestEvent.status, func.count(IngestEvent.id))
        .where(IngestEvent.received_at >= since, IngestEvent.status.in_(["error", "unparsed"]))
        .group_by(IngestEvent.status)
    ).all())
    email = kv_get(s, "health:email", {}) or {}
    sources = {
        "sepay": {"enabled": cfg.sepay_enabled, "last_event_at": _last_event(s, "sepay")},
        "casso": {"enabled": cfg.casso_enabled, "last_event_at": _last_event(s, "casso")},
        "email": {"enabled": cfg.email_enabled, "last_success_at": email.get("last_success_at"),
                  "last_error": email.get("last_error")},
    }
    return {
        "stale": bool(email.get("failing_since")),
        "error_events": counts.get("error", 0),
        "unparsed_events": counts.get("unparsed", 0),
        "sources": sources,
    }


def summary_payload(s: Session, month: str | None = None) -> dict:
    ev = build_evaluation(s, month)
    rs = runtime_settings.load(s)
    accounts = s.exec(select(Account).where(Account.bank != "CASH").order_by(Account.id)).all()
    latest = s.exec(select(Alert).where(Alert.read == False).order_by(Alert.id.desc()).limit(5)).all()  # noqa: E712
    if not latest:
        latest = s.exec(select(Alert).where(Alert.kind != "tx").order_by(Alert.id.desc()).limit(5)).all()
    unread = s.exec(select(func.count(Alert.id)).where(Alert.read == False)).one()  # noqa: E712
    balance_as_of = max((a.balance_as_of for a in accounts if a.include_in_total and a.balance_as_of), default=None)
    data = ser.evaluation_dict(ev)
    data.update({
        "generated_at": ser.iso(clock.now()),
        "balance_as_of": ser.iso(balance_as_of) if ev.balance_known else None,
        "expected_income": (
            {"amount": rs.expected_income_amount, "day": rs.expected_income_day, "pending": ev.expected_pending}
            if rs.expected_income_amount > 0 else None
        ),
        "accounts": [ser.account_dict(a) for a in accounts],
        "uncategorized_count": uncategorized_count(s, ev.month),
        "unread_alerts": unread,
        "latest_alerts": [ser.alert_dict(a) for a in latest],
        "ingest_health": ingest_health(s),
    })
    return data


@router.get("/summary")
async def get_summary(month: str | None = None) -> dict:
    month = _month_param(month)
    async with write_lock:  # có thể tạo mục tiêu tháng mới (rollover lười)
        with session_scope() as s:
            data = summary_payload(s, month)
            s.commit()
    return data


# ---- goals ------------------------------------------------------------------------------------------------


def _validate_goal_category(s: Session, goal_type: str, category_id: int | None) -> None:
    if category_id is None:
        if goal_type == "budget":
            raise _bad("Ngân sách chi tiêu cần chọn danh mục")
        return
    cat = s.get(Category, category_id)
    if cat is None:
        raise _bad("Danh mục không tồn tại")
    if cat.kind != "expense":
        raise _bad("Chỉ chọn được danh mục chi tiêu cho mục tiêu")


def _goal_view(s: Session, goal: Goal) -> dict:
    ev = build_evaluation(s, goal.month)
    for g in ev.goals:
        if g.id == goal.id:
            return ser.goal_view_dict(g)
    raise _404("mục tiêu")


@router.get("/goals")
async def list_goals(month: str | None = None) -> list[dict]:
    month = _month_param(month)
    async with write_lock:
        with session_scope() as s:
            ev = build_evaluation(s, month)
            s.commit()
            return [ser.goal_view_dict(g) for g in ev.goals]


@router.post("/goals", status_code=201)
async def create_goal(body: GoalCreate) -> dict:
    async with write_lock:
        with session_scope() as s:
            _validate_goal_category(s, body.type, body.category_id)
            goal = Goal(name=body.name.strip(), type=body.type, amount=body.amount, category_id=body.category_id,
                        month=body.month or clock.current_month(), repeat_monthly=body.repeat_monthly,
                        opening_spent=body.opening_spent)
            s.add(goal)
            s.flush()
            reevaluate_and_notify(s, reason="api_goal")
            s.commit()
            view = _goal_view(s, goal)
    wake_outbox()
    return view


@router.patch("/goals/{goal_id}")
async def update_goal(goal_id: int, body: GoalUpdate) -> dict:
    fields = body.model_fields_set
    async with write_lock:
        with session_scope() as s:
            goal = s.get(Goal, goal_id)
            if goal is None or goal.archived:
                raise _404("mục tiêu")
            new_type = body.type if "type" in fields and body.type else goal.type
            new_cat = body.category_id if "category_id" in fields else goal.category_id
            _validate_goal_category(s, new_type, new_cat)
            goal.type, goal.category_id = new_type, new_cat
            if "name" in fields and body.name:
                goal.name = body.name.strip()
            if "amount" in fields and body.amount:
                goal.amount = body.amount
            if "repeat_monthly" in fields and body.repeat_monthly is not None:
                goal.repeat_monthly = body.repeat_monthly
            if "opening_spent" in fields and body.opening_spent is not None:
                goal.opening_spent = body.opening_spent
            goal.updated_at = clock.now()
            s.add(goal)
            s.flush()
            reevaluate_and_notify(s, reason="api_goal")
            s.commit()
            view = _goal_view(s, goal)
    wake_outbox()
    return view


@router.delete("/goals/{goal_id}", status_code=204)
async def delete_goal(goal_id: int, stop_series: bool = False) -> Response:
    async with write_lock:
        with session_scope() as s:
            goal = s.get(Goal, goal_id)
            if goal is None:
                raise _404("mục tiêu")
            goal.archived = True
            goal.updated_at = clock.now()
            s.add(goal)
            if stop_series:
                later = s.exec(select(Goal).where(Goal.series_id == goal.series_id, Goal.month >= goal.month)).all()
                for g in later:
                    g.repeat_monthly = False
                    g.archived = True
                    s.add(g)
            s.flush()
            reevaluate_and_notify(s, reason="api_goal")
            s.commit()
    wake_outbox()
    return Response(status_code=204)


# ---- categories -------------------------------------------------------------------------------------------


@router.get("/categories")
def list_categories() -> list[dict]:
    with session_scope() as s:
        return [ser.category_dict(c) for c in s.exec(select(Category).order_by(Category.sort_order, Category.id))]


@router.post("/categories", status_code=201)
async def create_category(body: CategoryCreate) -> dict:
    async with write_lock:
        with session_scope() as s:
            if s.exec(select(Category).where(Category.name == body.name.strip())).first():
                raise _bad("Danh mục đã tồn tại")
            cat = Category(name=body.name.strip(), kind=body.kind, icon=body.icon, sort_order=80)
            s.add(cat)
            s.commit()
            return ser.category_dict(cat)


@router.get("/categories/{category_id}/rules")
def list_rules(category_id: int) -> list[dict]:
    with session_scope() as s:
        rules = s.exec(select(CategoryRule).where(CategoryRule.category_id == category_id).order_by(CategoryRule.id))
        return [ser.rule_dict(r) for r in rules]


@router.post("/categories/{category_id}/rules", status_code=201)
async def create_rule(category_id: int, body: RuleCreate) -> dict:
    async with write_lock:
        with session_scope() as s:
            if s.get(Category, category_id) is None:
                raise _404("danh mục")
            pattern = normalize_pattern(body.pattern)
            if len(pattern) < 2:
                raise _bad("Cụm từ quá ngắn")
            rule = CategoryRule(category_id=category_id, pattern=pattern, direction=body.direction, priority=10,
                                origin="user")
            s.add(rule)
            s.commit()
            return ser.rule_dict(rule)


@router.delete("/rules/{rule_id}", status_code=204)
async def delete_rule(rule_id: int) -> Response:
    async with write_lock:
        with session_scope() as s:
            rule = s.get(CategoryRule, rule_id)
            if rule is None:
                raise _404("luật")
            s.delete(rule)
            s.commit()
    return Response(status_code=204)


# ---- transactions -----------------------------------------------------------------------------------------


@router.get("/transactions")
def list_transactions(
    month: str | None = None,
    uncategorized: bool = False,
    limit: int = Query(default=50, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
) -> dict:
    month = _month_param(month)
    start, end = clock.month_bounds_utc(month)
    with session_scope() as s:
        cond = [Transaction.bank_time >= start, Transaction.bank_time < end]
        if uncategorized:
            cond += [Transaction.direction == "out", Transaction.category_id == None,  # noqa: E711
                     Transaction.goal_id == None, Transaction.pair_id == None,  # noqa: E711
                     Transaction.status == "active"]
        total = s.exec(select(func.count(Transaction.id)).where(*cond)).one()
        rows = s.exec(
            select(Transaction).where(*cond).order_by(Transaction.bank_time.desc(), Transaction.id.desc())
            .offset(offset).limit(limit)
        ).all()
        return {"items": [ser.tx_dict(s, t) for t in rows], "total": total}


@router.patch("/transactions/{tx_id}")
async def update_transaction(tx_id: int, body: TxUpdate) -> dict:
    fields = body.model_fields_set
    async with write_lock:
        with session_scope() as s:
            tx = s.get(Transaction, tx_id)
            if tx is None:
                raise _404("giao dịch")
            try:
                if "excluded" in fields and body.excluded is not None:
                    tx_actions.set_excluded(s, tx, body.excluded)
                if "category_id" in fields:
                    pattern = body.rule_pattern if body.remember_rule else None
                    if body.remember_rule and not (pattern and pattern.strip()):
                        raise tx_actions.ActionError("Cần nhập cụm từ (rule_pattern) để nhớ luật")
                    tx_actions.set_category(s, tx, body.category_id, remember_pattern=pattern)
                if "goal_id" in fields:
                    tx_actions.set_goal(s, tx, body.goal_id)
                if body.for_next_month:
                    tx_actions.assign_next_month(s, tx)
            except tx_actions.ActionError as exc:
                s.rollback()
                raise _bad(str(exc)) from None
            tx.updated_at = clock.now()
            s.add(tx)
            s.flush()
            reevaluate_and_notify(s, reason="api_tx", edit_tx=tx)
            s.commit()
            data = {"transaction": ser.tx_dict(s, tx), "summary": summary_payload(s)}
            s.commit()
    wake_outbox()
    return data


@router.post("/transactions", status_code=201)
async def create_transaction(body: TxCreate) -> dict:
    async with write_lock:
        with session_scope() as s:
            if body.account_id is not None:
                acc = s.get(Account, body.account_id)
                if acc is None:
                    raise _bad("Tài khoản không tồn tại")
            else:
                acc = cash_account(s)
            if body.category_id is not None and s.get(Category, body.category_id) is None:
                raise _bad("Danh mục không tồn tại")
            tx = Transaction(
                account_id=acc.id, direction=body.direction, amount=body.amount,
                bank_time=clock.ensure_utc(body.bank_time) if body.bank_time else clock.now(),
                description=body.description.strip(), category_id=body.category_id,
                categorized_by="user" if body.category_id else "none", is_manual=True,
                affects_balance=body.affects_balance and acc.bank != "CASH", evaluated=True,
            )
            s.add(tx)
            s.flush()
            s.add(TransactionSource(transaction_id=tx.id, source="manual", external_id=f"manual-{tx.id}"))
            if tx.affects_balance:
                recompute_balance(s, acc)
            reevaluate_and_notify(s, reason="api_tx")
            s.commit()
            data = ser.tx_dict(s, tx)
    wake_outbox()
    return data


@router.delete("/transactions/{tx_id}", status_code=204)
async def delete_transaction(tx_id: int) -> Response:
    async with write_lock:
        with session_scope() as s:
            tx = s.get(Transaction, tx_id)
            if tx is None:
                raise _404("giao dịch")
            if not tx.is_manual:
                raise _bad("Chỉ xoá được giao dịch nhập tay — giao dịch ngân hàng hãy dùng \"Loại trừ\"")
            for src in s.exec(select(TransactionSource).where(TransactionSource.transaction_id == tx.id)):
                s.delete(src)
            acc = s.get(Account, tx.account_id)
            s.delete(tx)
            s.flush()
            if acc is not None:
                recompute_balance(s, acc)
            reevaluate_and_notify(s, reason="api_tx")
            s.commit()
    wake_outbox()
    return Response(status_code=204)


# ---- accounts ---------------------------------------------------------------------------------------------


def _normalize_bank(bank: str) -> str:
    b = bank.strip()
    if b.upper() in ("OTHER", "KHAC", "KHÁC"):
        return "OTHER"
    return canonical_bank(b) or "OTHER"


@router.get("/accounts")
def list_accounts() -> list[dict]:
    with session_scope() as s:
        return [ser.account_dict(a) for a in s.exec(select(Account).where(Account.bank != "CASH").order_by(Account.id))]


@router.post("/accounts", status_code=201)
async def create_account(body: AccountCreate) -> dict:
    number = digits_only(body.account_number) or None
    async with write_lock:
        with session_scope() as s:
            if number and s.exec(select(Account).where(Account.account_number == number)).first():
                raise _bad("Số tài khoản đã tồn tại")
            acc = Account(bank=_normalize_bank(body.bank), name=body.name.strip(), account_number=number,
                          last4=number[-4:] if number else None, include_in_total=body.include_in_total,
                          confirmed=True)
            if body.balance is not None:
                acc.manual_balance, acc.manual_balance_at = body.balance, clock.now()
            s.add(acc)
            s.flush()
            recompute_balance(s, acc)
            reevaluate_and_notify(s, reason="api_account")
            s.commit()
            data = ser.account_dict(acc)
    wake_outbox()
    return data


@router.patch("/accounts/{account_id}")
async def update_account(account_id: int, body: AccountUpdate) -> dict:
    fields = body.model_fields_set
    async with write_lock:
        with session_scope() as s:
            acc = s.get(Account, account_id)
            if acc is None or acc.bank == "CASH":
                raise _404("tài khoản")
            if "name" in fields and body.name:
                acc.name = body.name.strip()
            if "account_number" in fields:
                number = digits_only(body.account_number) or None
                if number and s.exec(
                    select(Account).where(Account.account_number == number, Account.id != acc.id)
                ).first():
                    raise _bad("Số tài khoản đã tồn tại")
                acc.account_number, acc.last4 = number, (number[-4:] if number else acc.last4)
            if "include_in_total" in fields and body.include_in_total is not None:
                acc.include_in_total = body.include_in_total
            if "confirmed" in fields and body.confirmed is not None:
                acc.confirmed = body.confirmed
            if "balance" in fields and body.balance is not None:
                acc.manual_balance, acc.manual_balance_at = body.balance, clock.now()
            s.add(acc)
            s.flush()
            recompute_balance(s, acc)
            reevaluate_and_notify(s, reason="api_account")
            s.commit()
            data = ser.account_dict(acc)
    wake_outbox()
    return data


@router.delete("/accounts/{account_id}", status_code=204)
async def delete_account(account_id: int) -> Response:
    async with write_lock:
        with session_scope() as s:
            acc = s.get(Account, account_id)
            if acc is None or acc.bank == "CASH":
                raise _404("tài khoản")
            if s.exec(select(Transaction.id).where(Transaction.account_id == acc.id)).first() is not None:
                raise _bad("Tài khoản đã có giao dịch — hãy tắt \"Tính vào tổng\" thay vì xoá")
            s.delete(acc)
            s.flush()
            reevaluate_and_notify(s, reason="api_account")
            s.commit()
    return Response(status_code=204)


# ---- alerts -----------------------------------------------------------------------------------------------


@router.get("/alerts")
def list_alerts(unread: bool = False, limit: int = Query(default=50, ge=1, le=500)) -> list[dict]:
    with session_scope() as s:
        q = select(Alert)
        if unread:
            q = q.where(Alert.read == False)  # noqa: E712
        return [ser.alert_dict(a) for a in s.exec(q.order_by(Alert.id.desc()).limit(limit))]


@router.post("/alerts/read-all")
async def read_all_alerts() -> dict:
    async with write_lock:
        with session_scope() as s:
            rows = s.exec(select(Alert).where(Alert.read == False)).all()  # noqa: E712
            for a in rows:
                a.read = True
                s.add(a)
            s.commit()
            return {"updated": len(rows)}


@router.post("/alerts/{alert_id}/read")
async def read_alert(alert_id: int) -> dict:
    async with write_lock:
        with session_scope() as s:
            a = s.get(Alert, alert_id)
            if a is None:
                raise _404("cảnh báo")
            a.read = True
            s.add(a)
            s.commit()
            return ser.alert_dict(a)


# ---- settings ---------------------------------------------------------------------------------------------


@router.get("/settings")
def get_runtime_settings() -> dict:
    with session_scope() as s:
        return runtime_settings.load(s).to_dict()


@router.put("/settings")
async def put_runtime_settings(body: SettingsUpdate) -> dict:
    async with write_lock:
        with session_scope() as s:
            rs = runtime_settings.save(s, body.model_dump(exclude_unset=True))
            s.flush()
            reevaluate_and_notify(s, reason="api_settings")
            s.commit()
            data = rs.to_dict()
    wake_outbox()
    return data
