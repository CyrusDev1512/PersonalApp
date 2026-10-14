"""Mục tiêu theo tháng: chuyển sang tháng mới (rollover) và tạo trước mục tiêu tháng sau."""

from __future__ import annotations

from sqlalchemy.exc import IntegrityError
from sqlmodel import Session, select

from app import clock
from app.models import Goal


def _clone(src: Goal, month: str) -> Goal:
    return Goal(
        series_id=src.series_id, name=src.name, type=src.type, amount=src.amount, category_id=src.category_id,
        month=month, repeat_monthly=src.repeat_monthly, opening_spent=0, archived=False,
    )


def _latest_before(session: Session, series_id: str, month: str) -> Goal | None:
    return session.exec(
        select(Goal).where(Goal.series_id == series_id, Goal.month < month).order_by(Goal.month.desc())
    ).first()


def _exists(session: Session, series_id: str, month: str) -> Goal | None:
    return session.exec(select(Goal).where(Goal.series_id == series_id, Goal.month == month)).first()


def ensure_month_goals(session: Session, month: str) -> int:
    """Clone các mục tiêu lặp hằng tháng sang `month`. Idempotent nhờ unique(series_id, month).

    Nguồn clone là dòng mới nhất trước `month` của mỗi chuỗi; chuỗi đã "dừng lặp" (repeat_monthly=False)
    thì không clone. Dòng đã xoá (archived) của chính `month` vẫn chặn việc clone lại.
    """
    series_ids = session.exec(select(Goal.series_id).where(Goal.month < month).distinct()).all()
    created = 0
    for sid in series_ids:
        if _exists(session, sid, month):
            continue
        src = _latest_before(session, sid, month)
        if src is None or not src.repeat_monthly:
            continue
        session.add(_clone(src, month))
        created += 1
    if created:
        try:
            session.commit()
        except IntegrityError:  # đã có tiến trình khác tạo trước (không xảy ra khi chạy dưới write_lock)
            session.rollback()
            return 0
    return created


def ensure_goal(session: Session, series_id: str, month: str) -> Goal | None:
    """Lấy (hoặc tạo trước) mục tiêu của chuỗi `series_id` trong `month` — vd. trả trọ tháng sau từ sớm."""
    existing = _exists(session, series_id, month)
    if existing is not None:
        if existing.archived:
            existing.archived = False
            existing.updated_at = clock.now()
            session.add(existing)
        return existing
    src = _latest_before(session, series_id, month)
    if src is None:
        return None
    goal = _clone(src, month)
    session.add(goal)
    session.flush()
    return goal


def goals_for_month(session: Session, month: str) -> list[Goal]:
    return list(session.exec(
        select(Goal).where(Goal.month == month, Goal.archived == False).order_by(Goal.id)  # noqa: E712
    ).all())
