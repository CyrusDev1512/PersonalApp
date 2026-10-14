"""Soạn nội dung cảnh báo (văn bản thuần, có emoji). Telegram sẽ escape HTML khi gửi."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime

from app import clock
from app.engine.alerts import FloorDecision
from app.engine.evaluator import Evaluation, GoalView
from app.money import format_vnd

LEVEL_TITLES = {
    "OK": "✅ An toàn",
    "WARNING": "⚠️ Sắp chạm mức mục tiêu",
    "DANGER": "🔴 Đã lấn vào tiền mục tiêu",
    "UNKNOWN": "❔ Chưa biết số dư",
}


@dataclass
class TxInfo:
    id: int
    direction: str
    amount: int
    account_label: str
    bank_time: datetime
    description: str
    category_label: str | None
    balance_after: int | None
    goal_name: str | None = None
    internal: bool = False


def status_lines(ev: Evaluation) -> list[str]:
    if not ev.balance_known:
        return ["❔ Chưa biết số dư — mở app và nhập số dư hiện tại."]
    lines = [f"Số dư: {format_vnd(ev.balance)}"]
    if ev.in_transit:
        lines.append(f"Đang chờ ghép chuyển nội bộ: {format_vnd(abs(ev.in_transit))}")
    if ev.goals:
        lines.append(f"Mức sàn: {format_vnd(ev.floor)} · Được tiêu: {format_vnd(ev.free)}")
    return lines


def budget_line(goal: GoalView, threshold: int, days_left: int) -> str:
    icon = goal.category_icon or "📊"
    left = goal.amount - goal.spent
    head = f"{icon} {goal.name} đã dùng {goal.usage_pct:.0f}% ({format_vnd(goal.spent)}/{format_vnd(goal.amount)})"
    if left <= 0:
        return f"{head} — đã vượt {format_vnd(-left)}" if left < 0 else f"{head} — đã hết ngân sách"
    if days_left > 0:
        return f"{head} — còn {format_vnd(left)} cho {days_left} ngày (~{format_vnd(left // days_left)}/ngày)"
    return f"{head} — còn {format_vnd(left)}"


def decision_line(dec: FloorDecision, ev: Evaluation) -> str | None:
    if not dec.notify:
        return None
    if dec.kind == "safe":
        return f"✅ An toàn trở lại: {ev.level_reason}"
    if dec.kind == "escalate":
        return f"🔴 Thâm hụt tăng lên {format_vnd(ev.deficit)} so với mức sàn"
    return f"{LEVEL_TITLES.get(dec.level, '')}: {ev.level_reason}"


def tx_title(tx: TxInfo, dec: FloorDecision | None, budget_fired: list[tuple[GoalView, int]]) -> str:
    if dec is not None and dec.notify:
        if dec.kind == "safe":
            return "✅ An toàn trở lại"
        return LEVEL_TITLES.get(dec.level, "Cảnh báo")
    if budget_fired:
        return "📊 Ngân sách sắp hết" if all(t < 100 for _, t in budget_fired) else "📊 Đã dùng hết ngân sách"
    if tx.internal:
        return "↔️ Chuyển nội bộ"
    return f"💸 Chi {format_vnd(tx.amount)}" if tx.direction == "out" else f"💰 Nhận {format_vnd(tx.amount)}"


def compose_tx_message(
    tx: TxInfo,
    ev: Evaluation,
    dec: FloorDecision | None,
    budget_fired: list[tuple[GoalView, int]],
) -> tuple[str, str]:
    sign = "−" if tx.direction == "out" else "+"
    when = clock.to_ict(tx.bank_time).strftime("%H:%M %d/%m")
    lines = [f"{sign}{format_vnd(tx.amount)} · {tx.account_label} · {when}"]
    if tx.description:
        lines.append(f"Nội dung: {tx.description[:200]}")
    if tx.internal:
        lines.append("Danh mục: ↔️ Chuyển nội bộ (không tính chi tiêu)")
    else:
        lines.append(f"Danh mục: {tx.category_label or '(chưa phân loại)'}")
    if tx.goal_name:
        lines.append(f"Tính cho mục tiêu: {tx.goal_name}")
    lines.extend(status_lines(ev))
    dl = decision_line(dec, ev) if dec is not None else None
    if dl:
        lines.append(dl)
    elif ev.level in ("WARNING", "DANGER"):
        lines.append(f"{LEVEL_TITLES[ev.level]}: {ev.level_reason}")
    for goal, th in budget_fired:
        lines.append(budget_line(goal, th, ev.days_left))
    return tx_title(tx, dec, budget_fired), "\n".join(lines)


def compose_floor_message(dec: FloorDecision, ev: Evaluation, reason_label: str | None = None) -> tuple[str, str]:
    title = "✅ An toàn trở lại" if dec.kind == "safe" else LEVEL_TITLES.get(dec.level, "Cảnh báo")
    lines = [ev.level_reason]
    lines.extend(status_lines(ev))
    if reason_label:
        lines.append(f"Lý do: {reason_label}")
    return title, "\n".join(lines)


def compose_budget_message(goal: GoalView, threshold: int, ev: Evaluation) -> tuple[str, str]:
    title = "📊 Đã dùng hết ngân sách" if threshold >= 100 else "📊 Ngân sách sắp hết"
    return title, budget_line(goal, threshold, ev.days_left)


def compose_digest(ev: Evaluation, uncategorized: int, health_lines: list[str]) -> tuple[str, str]:
    title = f"☀️ Bản tin tài chính {clock.to_ict(clock.now()).strftime('%d/%m')}"
    lines = [f"{LEVEL_TITLES.get(ev.level, ev.level)} — {ev.level_reason}"]
    lines.extend(status_lines(ev))
    for g in ev.goals:
        kind = "Quỹ giữ" if g.type == "reserve" else "Ngân sách"
        lines.append(
            f"• {g.category_icon or '🎯'} {g.name} ({kind}): {format_vnd(g.spent)}/{format_vnd(g.amount)}"
            f" · còn cần {format_vnd(g.remaining)}"
        )
    if ev.days_left:
        lines.append(f"Còn {ev.days_left} ngày trong tháng.")
    if uncategorized:
        lines.append(f"🏷️ {uncategorized} giao dịch chưa phân loại — gõ /uncat để phân loại.")
    lines.extend(health_lines)
    return title, "\n".join(lines)
