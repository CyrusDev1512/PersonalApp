"""Điểm vào FastAPI: khởi tạo DB, job nền, Telegram outbox + bot."""

from __future__ import annotations

import asyncio
import contextlib
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app import __version__, clock
from app.api.body_limit import BodyLimitMiddleware
from app.api.ingest_routes import events_router, webhooks
from app.api.routes import router as api_router
from app.api.serialize import iso
from app.config import get_settings
from app.db import init_engine, session_scope, write_lock

log = logging.getLogger("app")


def _setup_logging(debug: bool) -> None:
    logging.basicConfig(level=logging.DEBUG if debug else logging.INFO,
                        format="%(asctime)s %(levelname)s %(name)s: %(message)s")
    # httpx log URL có chứa token Telegram -> chỉ log cảnh báo
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)


async def _startup_evaluate() -> None:
    """Chuyển tháng nếu server tắt đúng lúc mùng 1, rồi đánh giá lại (trạng thái cảnh báo đã lưu nên không spam)."""
    from app.services.goals import ensure_month_goals
    from app.services.notify import reevaluate_and_notify

    async with write_lock:
        with session_scope() as s:
            created = ensure_month_goals(s, clock.current_month())
            reevaluate_and_notify(s, reason="rollover" if created else "startup")
            s.commit()


def _make_fcm(cfg):
    """Nạp service account Firebase; lỗi thì ghi vào health:push (app vẫn chạy, push tắt)."""
    from app.db import kv_set
    from app.notify.fcm import FcmClient, FcmConfigError, ServiceAccount

    try:
        fcm = FcmClient(ServiceAccount.load(cfg), cfg.fcm_project_id or None)
        error = None
    except FcmConfigError as exc:
        fcm, error = None, str(exc)
        log.warning("Thông báo đẩy tắt: %s", error)
    except Exception as exc:  # noqa: BLE001 - cấu hình push hỏng không bao giờ được làm sập server
        fcm, error = None, f"Không nạp được cấu hình Firebase ({type(exc).__name__})"
        log.exception("Thông báo đẩy tắt")
    with session_scope() as s:
        kv_set(s, "health:push", {"error": error})
        s.commit()
    return fcm


def _start_background(app: FastAPI) -> list[asyncio.Task]:
    from apscheduler.schedulers.asyncio import AsyncIOScheduler

    from app import jobs

    cfg = get_settings()
    scheduler = AsyncIOScheduler(timezone=clock.ICT, job_defaults={"coalesce": True, "max_instances": 1,
                                                                     "misfire_grace_time": 300})
    scheduler.add_job(jobs.run_tick, "interval", seconds=30, id="tick")
    scheduler.add_job(jobs.run_digest, "cron", hour=8, minute=0, id="digest")
    scheduler.add_job(jobs.run_rollover, "cron", day=1, hour=0, minute=5, id="rollover")
    if cfg.email_enabled:
        scheduler.add_job(jobs.poll_email_once, "interval", seconds=max(cfg.email_poll_seconds, 30), id="email",
                          next_run_time=clock.now())
    scheduler.start()
    app.state.scheduler = scheduler

    tasks: list[asyncio.Task] = []
    app.state.stop = asyncio.Event()
    if cfg.push_configured:
        fcm = _make_fcm(cfg)
        if fcm is not None:
            from app.notify.push_outbox import run_push

            app.state.fcm = fcm
            tasks.append(asyncio.create_task(run_push(fcm, app.state.stop), name="push-outbox"))
    if cfg.telegram_enabled:
        from app.notify.bot import run_bot
        from app.notify.outbox import run_outbox
        from app.notify.telegram import TelegramClient

        client = TelegramClient(cfg.telegram_bot_token)
        app.state.telegram = client
        tasks.append(asyncio.create_task(run_bot(client, cfg, app.state.stop), name="telegram-bot"))
        if cfg.telegram_chat_id is not None:
            tasks.append(asyncio.create_task(run_outbox(client, cfg.telegram_chat_id, app.state.stop),
                                             name="telegram-outbox"))
        else:
            log.warning("Chưa đặt TELEGRAM_CHAT_ID: nhắn /start cho bot để lấy chat id")
    return tasks


@asynccontextmanager
async def lifespan(app: FastAPI):
    cfg = get_settings()
    _setup_logging(cfg.debug)
    init_engine(cfg.database_url)
    await _startup_evaluate()
    tasks: list[asyncio.Task] = []
    if cfg.enable_background:
        tasks = _start_background(app)
    try:
        yield
    finally:
        stop = getattr(app.state, "stop", None)
        if stop is not None:
            stop.set()
        scheduler = getattr(app.state, "scheduler", None)
        if scheduler is not None:
            scheduler.shutdown(wait=False)
        for t in tasks:
            t.cancel()
        for t in tasks:
            with contextlib.suppress(asyncio.CancelledError, Exception):
                await t
        for name in ("telegram", "fcm"):
            client = getattr(app.state, name, None)
            if client is not None:
                await client.aclose()


def create_app() -> FastAPI:
    cfg = get_settings()
    app = FastAPI(
        title="Personal Finance", version=__version__, lifespan=lifespan,
        docs_url="/docs" if cfg.debug else None, redoc_url=None, openapi_url="/openapi.json" if cfg.debug else None,
    )

    app.add_middleware(BodyLimitMiddleware, max_bytes=cfg.max_body_bytes)

    @app.get("/health")
    def health() -> dict:
        return {"status": "ok", "time": iso(clock.now()), "version": __version__}

    app.include_router(api_router)
    app.include_router(events_router)
    app.include_router(webhooks)
    return app


app = create_app()
