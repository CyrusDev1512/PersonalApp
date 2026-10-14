"""Đánh giá lại sau mỗi thay đổi và ghi cảnh báo vào outbox (bảng Alert).

Mọi đường thay đổi dữ liệu (webhook, email, API, bot, job) đều gọi `reevaluate_and_notify` dưới `write_lock`.
Việc gửi Telegram do outbox sender làm riêng, nên ở đây chỉ ghi DB.
"""

from __future__ import annotations

import json
from dataclasses import asdict
from datetime import date, datetime, timedelta

from sqlmodel import Session, select

from app import clock
from app.engine.alerts import FloorDecision, FloorState, ForecastState, decide_budget, decide_floor, decide_forecast
from app.engine.evaluator import Evaluation, GoalView
from app.engine.forecast import Forecast
from app.engine.messages import (
    TxInfo,
    compose_budget_message,
    compose_floor_message,
    compose_forecast_message,
    compose_tx_message,
)
from app.models import Account, Alert, AlertState, Category, Goal, Transaction
from app.services import runtime_settings
from app.services.forecast import build_forecast
from app.services.summary import build_evaluation

OUTBOX_SEND_WINDOW = timedelta(hours=24)  # khớp outbox.MAX_AGE

# Danh mục hiện thành nút bấm trong Telegram (theo system_key)
BUTTON_CATEGORIES = ("food", "rent", "transport", "shopping", "bills", "savings", "other")

REASON_LABELS = {
    "api_goal": "mục tiêu vừa thay đổi",
    "api_account": "số dư tài khoản vừa được cập nhật",
    "api_settings": "cài đặt cảnh báo vừa thay đổi",
    "api_tx": "giao dịch vừa được cập nhật",
    "rollover": "bắt đầu tháng mới",
    "merge": "số dư vừa được ngân hàng xác nhận",
    "backfill": "vừa nhập các giao dịch cũ",
    "pair": "vừa ghép chuyển khoản nội bộ",
}


# ---- trạng thái -------------------------------------------------------------------------------------


def _load_floor_state(session: Session, month: str) -> FloorState:
    row = session.get(AlertState, f"floor:{month}")
    if row is None:
        return FloorState()
    notified = {}
    for k, v in json.loads(row.notified_json or "{}").items():
        try:
            notified[k] = clock.ensure_utc(datetime.fromisoformat(v))
        except (TypeError, ValueError):
            continue
    return FloorState(last_level=row.last_level, last_deficit=row.last_deficit, notified=notified)


def _save_floor_state(session: Session, month: str, st: FloorState) -> None:
    key = f"floor:{month}"
    row = session.get(AlertState, key) or AlertState(key=key)
    row.last_level = st.last_level
    row.last_deficit = st.last_deficit
    row.notified_json = json.dumps({k: v.isoformat() for k, v in st.notified.items()})
    row.last_sent_at = max(st.notified.values(), default=row.last_sent_at)
    session.add(row)


def _load_forecast_state(session: Session, month: str) -> ForecastState:
    row = session.get(AlertState, f"forecast:{month}")
    if row is None:
        return ForecastState()
    data = json.loads(row.notified_json or "{}")
    hit = data.get("hit")
    return ForecastState(armed=row.armed, last_sent_at=row.last_sent_at,
                         last_hit=date.fromisoformat(hit) if hit else None)


def _save_forecast_state(session: Session, month: str, st: ForecastState) -> None:
    key = f"forecast:{month}"
    row = session.get(AlertState, key) or AlertState(key=key)
    row.armed, row.last_sent_at = st.armed, st.last_sent_at
    row.notified_json = json.dumps({"hit": st.last_hit.isoformat() if st.last_hit else None})
    session.add(row)


def check_forecast(session: Session, ev: Evaluation, now: datetime) -> tuple[Forecast | None, bool]:
    """Tính dự báo và quyết định có báo "sắp chạm mức sàn" không (đã lưu trạng thái chống spam)."""
    fc = build_forecast(session, ev, now)
    fire, st = decide_forecast(_load_forecast_state(session, ev.month), fc, ev, now)
    _save_forecast_state(session, ev.month, st)
    return fc, fire


def _budget_key(goal_id: int, th: int, month: str) -> str:
    return f"budget:{goal_id}:{th}:{month}"


def _decide_budgets(session: Session, ev: Evaluation) -> list[tuple[GoalView, int]]:
    fired: list[tuple[GoalView, int]] = []
    for g in ev.goals:
        if g.type != "budget":
            continue
        rows = {th: session.get(AlertState, _budget_key(g.id, th, ev.month)) for th in (80, 100)}
        armed = {th: (row.armed if row is not None else True) for th, row in rows.items()}
        th, new = decide_budget(g, armed)
        for t, value in new.items():
            row = rows[t] or AlertState(key=_budget_key(g.id, t, ev.month))
            if row.armed != value or rows[t] is None:
                row.armed = value
                if not value:
                    row.last_sent_at = clock.now()
                session.add(row)
        if th is not None:
            fired.append((g, th))
    return fired


# ---- thông tin giao dịch ------------------------------------------------------------------------------


def account_label(acc: Account | None) -> str:
    if acc is None:
        return "?"
    if acc.name:
        return acc.name
    return f"{acc.bank} …{acc.last4}" if acc.last4 else acc.bank


def is_internal(session: Session, tx: Transaction) -> bool:
    if tx.category_id is None:
        return False
    cat = session.get(Category, tx.category_id)
    return cat is not None and cat.kind == "transfer"


def tx_info(session: Session, tx: Transaction) -> TxInfo:
    cat = session.get(Category, tx.category_id) if tx.category_id else None
    goal = session.get(Goal, tx.goal_id) if tx.goal_id else None
    label = f"{cat.icon or ''} {cat.name}".strip() if cat else None
    goal_name = f"{goal.name} ({goal.month[5:]}/{goal.month[:4]})" if goal else None
    return TxInfo(
        id=tx.id, direction=tx.direction, amount=tx.amount,
        account_label=account_label(session.get(Account, tx.account_id)), bank_time=tx.bank_time,
        description=tx.description, category_label=label, balance_after=tx.balance_after, goal_name=goal_name,
        internal=cat is not None and cat.kind == "transfer",
    )


def category_buttons(session: Session, tx_id: int) -> list[list[dict]]:
    cats = session.exec(select(Category).where(Category.kind == "expense").order_by(Category.sort_order)).all()
    by_key = {c.system_key: c for c in cats if c.system_key}
    ordered = [by_key[k] for k in BUTTON_CATEGORIES if k in by_key]
    ordered += [c for c in cats if c not in ordered]
    buttons = [{"text": f"{c.icon or ''} {c.name}".strip(), "callback_data": f"c:{tx_id}:{c.id}"} for c in ordered]
    return [buttons[i:i + 3] for i in range(0, len(buttons), 3)]


def tx_markup(session: Session, tx: Transaction) -> dict | None:
    if tx.pair_id is not None or is_internal(session, tx):
        return None
    if tx.direction == "out" and tx.category_id is None and tx.goal_id is None:
        rows = category_buttons(session, tx.id)
        rows.append([{"text": "↔️ Chuyển nội bộ", "callback_data": f"t:{tx.id}"}])
        return {"inline_keyboard": rows}
    row = [{"text": "🏷️ Đổi danh mục", "callback_data": f"r:{tx.id}"}]
    if tx.direction == "out" and (tx.category_id is not None or tx.goal_id is not None):
        row.append({"text": "📅 Tính cho tháng sau", "callback_data": f"n:{tx.id}"})
    return {"inline_keyboard": [row]}


def _snapshot(ev: Evaluation) -> str:
    data = asdict(ev)
    data.pop("goals", None)
    data["goals"] = [{"id": g.id, "name": g.name, "spent": g.spent, "remaining": g.remaining} for g in ev.goals]
    return json.dumps(data, ensure_ascii=False, default=str)


def _add_alert(session: Session, **kw) -> Alert:
    alert = Alert(**kw)
    session.add(alert)
    return alert


# ---- API chính ----------------------------------------------------------------------------------------


def reevaluate_and_notify(
    session: Session,
    *,
    reason: str,
    tx: Transaction | None = None,
    edit_tx: Transaction | None = None,
    now: datetime | None = None,
) -> Evaluation:
    """Đánh giá tháng hiện tại, áp chính sách cảnh báo, ghi Alert. Caller tự commit.

    - `tx`: giao dịch mới cần thông báo (1 tin cho mỗi giao dịch, gộp luôn cảnh báo mức sàn / ngân sách).
    - `edit_tx`: giao dịch vừa được phân loại lại -> sửa tin Telegram cũ tại chỗ.
    """
    now = now or clock.now()
    ev = build_evaluation(session, now=now)
    floor_reason = reason
    if tx is not None and tx.direction == "in" and not is_internal(session, tx):
        floor_reason = "inflow"
    state = _load_floor_state(session, ev.month)
    dec = decide_floor(state, ev, floor_reason, now)
    _save_floor_state(session, ev.month, dec.state)
    budget_fired = _decide_budgets(session, ev)
    fc, forecast_fire = check_forecast(session, ev, now)
    fc_fired = fc if forecast_fire else None
    _maybe_unknown_notice(session, ev)
    rs = runtime_settings.load(session)
    snap = _snapshot(ev)

    if tx is not None:
        loud = dec.notify or bool(budget_fired) or forecast_fire
        info = tx_info(session, tx)
        if loud or rs.notify_every_tx:
            title, message = compose_tx_message(info, ev, dec, budget_fired, fc_fired)
            markup = tx_markup(session, tx)
            _add_alert(
                session, kind="tx", level=dec.level if dec.notify else ev.level, month=ev.month,
                transaction_id=tx.id, title=title, message=message, snapshot_json=snap, loud=loud,
                read=not loud, reply_markup_json=json.dumps(markup, ensure_ascii=False) if markup else None,
            )
        tx.evaluated = True
        session.add(tx)
        return ev

    if edit_tx is not None:
        info = tx_info(session, edit_tx)
        title, message = compose_tx_message(info, ev, dec, budget_fired)
        markup = tx_markup(session, edit_tx)
        existing = session.exec(
            select(Alert).where(Alert.kind == "tx", Alert.transaction_id == edit_tx.id).order_by(Alert.id.desc())
        ).first()
        reachable = False
        if existing is not None:
            existing.title, existing.message = title, message
            existing.reply_markup_json = json.dumps(markup, ensure_ascii=False) if markup else None
            existing.snapshot_json = snap
            existing.revision += 1
            if existing.telegram_message_id is not None:
                existing.needs_edit = True
                reachable = True
            elif not existing.telegram_sent and existing.created_at >= now - OUTBOX_SEND_WINDOW:
                reachable = True  # tin chưa gửi: sẽ được gửi với nội dung mới này
            session.add(existing)
        # Có tin để sửa tại chỗ thì cảnh báo mới chỉ lưu trong app; không có thì gửi thành tin riêng.
        _separate_alerts(session, ev, dec, budget_fired, reason, snap, deliver=not reachable, forecast=fc_fired)
        return ev

    _separate_alerts(session, ev, dec, budget_fired, reason, snap, deliver=True, forecast=fc_fired)
    return ev


def _separate_alerts(
    session: Session,
    ev: Evaluation,
    dec: FloorDecision,
    budget_fired: list[tuple[GoalView, int]],
    reason: str,
    snap: str,
    *,
    deliver: bool,
    forecast: Forecast | None = None,
) -> None:
    if forecast is not None:
        title, message = compose_forecast_message(forecast, ev)
        _add_alert(session, kind="forecast", level="WARNING", month=ev.month, title=title, message=message,
                   snapshot_json=snap, deliver_telegram=deliver)
    if dec.notify:
        title, message = compose_floor_message(dec, ev, REASON_LABELS.get(reason))
        kind = "safe" if dec.kind == "safe" else "floor"
        _add_alert(session, kind=kind, level=dec.level, month=ev.month, title=title, message=message,
                   snapshot_json=snap, deliver_telegram=deliver)
    for goal, th in budget_fired:
        title, message = compose_budget_message(goal, th, ev)
        _add_alert(session, kind="budget", level="WARNING", month=ev.month, goal_id=goal.id, title=title,
                   message=message, snapshot_json=snap, deliver_telegram=deliver)


def _maybe_unknown_notice(session: Session, ev: Evaluation) -> None:
    if ev.level != "UNKNOWN":
        # Đã biết số dư -> nhắc "chưa biết số dư" cũ không còn ý nghĩa
        for a in session.exec(
            select(Alert).where(Alert.kind == "account", Alert.level == "UNKNOWN", Alert.read == False)  # noqa: E712
        ).all():
            a.read = True
            session.add(a)
        return
    key = f"unknown:{ev.month}"
    if session.get(AlertState, key) is not None:
        return
    session.add(AlertState(key=key, last_level="UNKNOWN", last_sent_at=clock.now()))
    _add_alert(
        session, kind="account", level="UNKNOWN", month=ev.month, title="❔ Chưa biết số dư",
        message="App chưa biết số dư hiện tại của tài khoản được tính vào tổng. "
                "Mở app → Cài đặt → Tài khoản để nhập số dư, khi đó cảnh báo mức sàn mới hoạt động.",
    )


def notify_new_account(session: Session, acc: Account) -> None:
    markup = {"inline_keyboard": [[
        {"text": "✅ Tính vào tổng", "callback_data": f"a:{acc.id}:1"},
        {"text": "🚫 Bỏ qua", "callback_data": f"a:{acc.id}:0"},
    ]]}
    _add_alert(
        session, kind="account", level="INFO", title="🆕 Phát hiện tài khoản mới",
        message=f"Nhận được giao dịch của tài khoản {account_label(acc)} ({acc.bank}) chưa có trong app. "
                "Tài khoản này đang KHÔNG được tính vào tổng số dư. Xác nhận nếu đây là tài khoản của bạn.",
        reply_markup_json=json.dumps(markup, ensure_ascii=False),
    )


def add_info_alert(session: Session, title: str, message: str, *, kind: str = "info", loud: bool = False) -> Alert:
    return _add_alert(session, kind=kind, level="INFO", title=title, message=message, loud=loud, read=not loud)
