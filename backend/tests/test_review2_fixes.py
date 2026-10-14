"""Hồi quy cho các lỗi tìm thấy ở vòng review thứ hai (dự báo + thông báo đẩy)."""

from __future__ import annotations

import asyncio
import json
from datetime import UTC, date, datetime, timedelta

import httpx
import pytest
from sqlmodel import select

from app.db import kv_get
from app.engine.alerts import decide_forecast
from app.engine.evaluator import EvalSettings, GoalIn, TxIn, evaluate
from app.engine.forecast import OutflowIn, forecast
from app.models import Alert, Device, PushDelivery
from app.notify import push_outbox
from app.notify.fcm import FcmConfigError, ServiceAccount
from tests.test_push import FakeGoogle, _alert, _device, _prime, rsa_key, sa  # noqa: F401  (fixtures)

OCT = "2026-10"


def _goals(food=5_000_000):
    return [GoalIn(id=1, name="Tiền trọ", type="reserve", amount=3_000_000, month=OCT, category_id=2),
            GoalIn(id=2, name="Tiền ăn", type="budget", amount=food, month=OCT, category_id=1, category_icon="🍜")]


def _ev(balance, today, food_spent=0, settings=None):
    txs = [TxIn(id=999, direction="out", amount=food_spent, bank_time=datetime(2026, 10, 1, 5, tzinfo=UTC),
                category_id=1)] if food_spent else []
    return evaluate(month=OCT, goals=_goals(), txs=txs, balance=balance, settings=settings or EvalSettings(),
                    today=today)


def test_safe_daily_respects_floor_until_payday():
    s = EvalSettings(expected_income_amount=10_000_000, expected_income_day=28)
    today = date(2026, 10, 14)
    ev = _ev(8_500_000, today, settings=s)  # free 500k, lương ngày 28
    out = [OutflowIn(id=i, amount=100_000, day=date(2026, 10, 14 - i)) for i in range(14)]
    fc = forecast(ev=ev, outflows=out, today=today, data_since=date(2026, 9, 1), income_day=28)
    # Từ hôm nay tới hết 27/10 là 14 ngày phải sống bằng 500k
    assert fc.safe_daily_spend <= 500_000 // 14
    # Chi đúng mức gợi ý thì không chạm mức sàn trước ngày lương
    again = forecast(ev=ev, outflows=[OutflowIn(id=i, amount=fc.safe_daily_spend, day=date(2026, 10, 14 - i))
                                      for i in range(14)], today=today, data_since=date(2026, 9, 1), income_day=28)
    assert again.floor_hit_date is None or again.floor_hit_date >= date(2026, 10, 28)


def test_last_day_salary_next_month_is_not_counted():
    s = EvalSettings(expected_income_amount=10_000_000, expected_income_day=31)
    today = date(2026, 10, 31)
    ev = _ev(7_000_000, today, settings=s)
    fc = forecast(ev=ev, outflows=[], today=today, data_since=date(2026, 9, 1), income_day=31)
    assert fc.safe_daily_spend == max(0, ev.free)


def test_lumpy_budget_early_month_is_not_a_false_alarm():
    today = date(2026, 10, 3)
    food = [OutflowIn(id=1, amount=2_500_000, day=date(2026, 10, 1), goal_id=2),
            OutflowIn(id=2, amount=50_000, day=date(2026, 10, 2), goal_id=2),
            OutflowIn(id=3, amount=50_000, day=date(2026, 10, 3), goal_id=2)]
    ev = _ev(8_000_000 + 800_000 - 2_600_000, today, food_spent=2_600_000)
    fc = forecast(ev=ev, outflows=food, today=today, data_since=date(2026, 9, 1))
    assert fc.projected_budget_overrun == 0 and fc.floor_hit_date is None
    # ngày 7: đủ dữ liệu, khoản lớn bị giới hạn -> vẫn đúng nhịp
    today = date(2026, 10, 7)
    food += [OutflowIn(id=10 + i, amount=50_000, day=date(2026, 10, 4 + i), goal_id=2) for i in range(4)]
    ev = _ev(8_000_000 + 800_000 - 2_800_000, today, food_spent=2_800_000)
    fc = forecast(ev=ev, outflows=food, today=today, data_since=date(2026, 9, 1))
    assert next(b for b in fc.budgets if b.goal_id == 2).status == "on_track"


def test_single_large_non_goal_purchase_is_capped():
    today = date(2026, 10, 14)
    fc = forecast(ev=_ev(10_000_000, today), outflows=[OutflowIn(id=1, amount=6_000_000, day=date(2026, 10, 10))],
                  today=today, data_since=date(2026, 9, 1))
    assert fc.capped_count == 1 and fc.daily_spend == round(1_000_000 / 14)


def test_refund_offsets_spending_pace():
    today = date(2026, 10, 14)
    out = [OutflowIn(id=i, amount=50_000, day=date(2026, 10, 14 - i)) for i in range(14)]
    out.append(OutflowIn(id=100, amount=950_000, day=today))
    base = forecast(ev=_ev(10_000_000, today), outflows=out, today=today, data_since=date(2026, 9, 1))
    fc = forecast(ev=_ev(10_000_000, today), outflows=out, today=today, data_since=date(2026, 9, 1),
                  refunds=[OutflowIn(id=200, amount=950_000, day=today)])
    assert fc.daily_spend == 50_000 < base.daily_spend


def test_forecast_never_fires_when_already_below_floor():
    from app.engine.forecast import Forecast

    ev = _ev(7_000_000, date(2026, 10, 14))  # free -1tr
    fc = Forecast(status="ok", headline="x", floor_hit_date=date(2026, 10, 14), days_until_floor_hit=0,
                  min_projected_free=-1_000_000)
    fire, st = decide_forecast(None, fc, ev, datetime(2026, 10, 14, 3, tzinfo=UTC))
    assert not fire and st.armed


def test_rollover_sends_one_merged_alert(session, setup, fake_now):
    # tốc độ chi cao -> dự báo chạm sàn sớm; đồng thời rút tiền làm số dư xuống gần sàn
    from app.models import Transaction
    from app.services.notify import reevaluate_and_notify

    for d in range(1, 8):
        session.add(Transaction(account_id=setup["vcb"].id, direction="out", amount=300_000, description="mua",
                                bank_time=fake_now.value - timedelta(days=d), evaluated=True))
    session.commit()
    acc = setup["vcb"]
    acc.manual_balance, acc.manual_balance_at = 6_400_000, fake_now.value
    session.add(acc)
    session.commit()
    from app.services.balance import recompute_balance

    recompute_balance(session, acc)
    reevaluate_and_notify(session, reason="api_account")
    session.commit()
    alerts = session.exec(select(Alert).where(Alert.deliver_telegram == True, Alert.loud == True)).all()  # noqa: E712
    kinds = [a.kind for a in alerts if a.kind in ("floor", "forecast")]
    assert kinds == ["floor"] and "📉 Dự báo" in alerts[-1].message


def test_service_account_key_validation(rsa_key, tmp_path):  # noqa: F811
    from app.config import Settings

    good = {"client_email": "a@b.iam.gserviceaccount.com", "private_key": rsa_key[1], "project_id": "p"}
    assert ServiceAccount.from_dict(good).project_id == "p"
    escaped = dict(good, private_key=rsa_key[1].replace("\n", "\\n"))
    assert ServiceAccount.from_dict(escaped).private_key == rsa_key[1]
    with pytest.raises(FcmConfigError):
        ServiceAccount.from_dict(dict(good, private_key="-----BEGIN PRIVATE KEY-----\nabc\n-----END PRIVATE KEY-----"))
    bom = tmp_path / "bom.json"
    bom.write_text(json.dumps(good), encoding="utf-8-sig")
    assert ServiceAccount.load(Settings(app_token="x" * 32, fcm_service_account_file=str(bom))).project_id == "p"
    utf16 = tmp_path / "u16.json"
    utf16.write_text(json.dumps(good), encoding="utf-16")
    with pytest.raises(FcmConfigError):
        ServiceAccount.load(Settings(app_token="x" * 32, fcm_service_account_file=str(utf16)))


def _fcm_error(status, code, error_code=None):
    err = {"error": {"code": status, "status": code, "message": f"{code} message"}}
    if error_code:
        err["error"]["details"] = [{"@type": "type.googleapis.com/google.firebase.fcm.v1.FcmError",
                                    "errorCode": error_code}]
    return httpx.Response(status, json=err)


def test_config_errors_are_reported_and_keep_device(session, fake_now, sa, rsa_key):  # noqa: F811
    _prime(session)
    dev_id = _device(session).id
    _alert(session)
    g = FakeGoogle(rsa_key, [_fcm_error(403, "PERMISSION_DENIED")])
    asyncio.run(push_outbox.drain_push_once(g.client(sa)))
    session.expire_all()
    assert session.get(Device, dev_id) is not None
    assert "PERMISSION_DENIED" in kv_get(session, "health:push")["error"]
    assert session.exec(select(PushDelivery)).one().status == "failed"
    # Sai project Firebase: báo lỗi cấu hình, không xoá thiết bị
    _alert(session)
    g = FakeGoogle(rsa_key, [_fcm_error(403, "PERMISSION_DENIED", "SENDER_ID_MISMATCH")])
    asyncio.run(push_outbox.drain_push_once(g.client(sa)))
    session.expire_all()
    assert session.get(Device, dev_id) is not None
    # gửi thành công lại -> xoá lỗi
    _alert(session)
    g = FakeGoogle(rsa_key)
    asyncio.run(push_outbox.drain_push_once(g.client(sa)))
    session.expire_all()
    assert kv_get(session, "health:push")["error"] is None


def test_bad_key_at_send_time_fails_delivery_instead_of_looping(session, fake_now, sa, rsa_key):  # noqa: F811
    _prime(session)
    _device(session)
    _alert(session)
    sa.private_key = "not a key"  # hỏng sau khi nạp (mô phỏng)
    g = FakeGoogle(rsa_key)
    asyncio.run(push_outbox.drain_push_once(g.client(sa)))
    session.expire_all()
    assert session.exec(select(PushDelivery)).one().status == "failed"
    assert kv_get(session, "health:push")["error"]
