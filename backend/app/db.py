"""Kết nối SQLite, khoá ghi dùng chung và tiện ích KV."""

from __future__ import annotations

import asyncio
import contextlib
import json
import os
from collections.abc import Iterator
from contextlib import contextmanager
from typing import Any

from sqlalchemy import event
from sqlalchemy.engine import Engine
from sqlalchemy.pool import StaticPool
from sqlmodel import Session, SQLModel, create_engine

from app import models  # noqa: F401  (đăng ký bảng)
from app.models import KV

_engine: Engine | None = None

# Mọi đường ghi dữ liệu + đánh giá cảnh báo đều chạy dưới khoá này (1 tiến trình, 1 worker).
write_lock = asyncio.Lock()


def _set_sqlite_pragmas(dbapi_conn, _record) -> None:
    cur = dbapi_conn.cursor()
    cur.execute("PRAGMA foreign_keys=ON")
    cur.execute("PRAGMA busy_timeout=5000")
    with contextlib.suppress(Exception):  # DB in-memory không hỗ trợ WAL
        cur.execute("PRAGMA journal_mode=WAL")
    cur.close()


def make_engine(url: str) -> Engine:
    if url.startswith("sqlite"):
        if url in ("sqlite://", "sqlite:///:memory:"):
            eng = create_engine(url, connect_args={"check_same_thread": False}, poolclass=StaticPool)
        else:
            path = url.split("sqlite:///", 1)[-1]
            directory = os.path.dirname(path)
            if directory:
                os.makedirs(directory, exist_ok=True)
            eng = create_engine(url, connect_args={"check_same_thread": False, "timeout": 5})
        event.listen(eng, "connect", _set_sqlite_pragmas)
        return eng
    return create_engine(url)


def _sql_default(column) -> str:
    """Giá trị mặc định dạng SQL cho cột mới thêm vào bảng đã có dữ liệu."""
    default = column.default.arg if column.default is not None and not callable(column.default.arg) else None
    if default is None:
        if column.nullable:
            return "NULL"
        type_name = type(column.type).__name__.lower()
        default = 0 if ("bool" in type_name or "int" in type_name) else ""
    if isinstance(default, bool):
        return "1" if default else "0"
    if isinstance(default, int | float):
        return str(default)
    return "'" + str(default).replace("'", "''") + "'"


def auto_migrate(engine: Engine) -> list[str]:
    """SQLite: thêm các cột có trong model mà bảng cũ chưa có (create_all không tự làm việc này)."""
    if engine.dialect.name != "sqlite":
        return []
    added: list[str] = []
    with engine.begin() as conn:
        for table in SQLModel.metadata.sorted_tables:
            existing = {row[1] for row in conn.exec_driver_sql(f'PRAGMA table_info("{table.name}")')}
            if not existing:
                continue
            for column in table.columns:
                if column.name in existing:
                    continue
                col_type = column.type.compile(dialect=engine.dialect)
                if not column.nullable:
                    extra = f" NOT NULL DEFAULT {_sql_default(column)}"
                elif column.default is not None:
                    extra = f" DEFAULT {_sql_default(column)}"
                else:
                    extra = ""
                conn.exec_driver_sql(f'ALTER TABLE "{table.name}" ADD COLUMN "{column.name}" {col_type}{extra}')
                added.append(f"{table.name}.{column.name}")
    return added


def init_engine(url: str) -> Engine:
    global _engine
    _engine = make_engine(url)
    SQLModel.metadata.create_all(_engine)
    auto_migrate(_engine)
    from app.seed import seed_defaults

    with Session(_engine) as s:
        seed_defaults(s)
    return _engine


def get_engine() -> Engine:
    if _engine is None:
        raise RuntimeError("Database chưa được khởi tạo")
    return _engine


def set_engine(engine: Engine) -> None:
    global _engine
    _engine = engine


@contextmanager
def session_scope() -> Iterator[Session]:
    with Session(get_engine(), expire_on_commit=False) as s:
        yield s


def get_session() -> Iterator[Session]:
    """Dependency cho FastAPI."""
    with Session(get_engine(), expire_on_commit=False) as s:
        yield s


# ---- KV ---------------------------------------------------------------------------------------------


def kv_get(session: Session, key: str, default: Any = None) -> Any:
    row = session.get(KV, key)
    if row is None:
        return default
    try:
        return json.loads(row.value_json)
    except ValueError:
        return default


def kv_set(session: Session, key: str, value: Any) -> None:
    row = session.get(KV, key)
    data = json.dumps(value, ensure_ascii=False, default=str)
    if row is None:
        session.add(KV(key=key, value_json=data))
    else:
        row.value_json = data
        session.add(row)
