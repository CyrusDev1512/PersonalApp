"""Auto-migrate: DB tạo từ phiên bản cũ (thiếu cột) vẫn chạy được sau khi nâng cấp."""

from __future__ import annotations

import sqlite3

from sqlmodel import Session, select

from app.db import auto_migrate, make_engine
from app.models import Alert, Transaction


def test_adds_missing_columns_and_keeps_data(tmp_path):
    path = tmp_path / "old.db"
    con = sqlite3.connect(path)
    # Bảng như phiên bản đầu: chưa có transactions.quiet và alerts.revision
    con.executescript("""
        CREATE TABLE accounts (id INTEGER PRIMARY KEY, bank VARCHAR NOT NULL, name VARCHAR NOT NULL,
            include_in_total BOOLEAN NOT NULL, confirmed BOOLEAN NOT NULL, balance_derived BOOLEAN NOT NULL,
            created_at DATETIME NOT NULL);
        CREATE TABLE alerts (id INTEGER PRIMARY KEY, created_at DATETIME NOT NULL, kind VARCHAR NOT NULL,
            title VARCHAR NOT NULL, message TEXT NOT NULL, read BOOLEAN NOT NULL, deliver_telegram BOOLEAN NOT NULL,
            loud BOOLEAN NOT NULL, telegram_sent BOOLEAN NOT NULL, telegram_attempts INTEGER NOT NULL,
            needs_edit BOOLEAN NOT NULL, cancelled BOOLEAN NOT NULL);
        INSERT INTO alerts VALUES (1, '2026-10-01 00:00:00', 'info', 'cũ', 'nội dung', 0, 1, 1, 1, 0, 0, 0);
    """)
    con.commit()
    con.close()
    engine = make_engine(f"sqlite:///{path}")
    from sqlmodel import SQLModel

    SQLModel.metadata.create_all(engine)
    added = auto_migrate(engine)
    assert "alerts.revision" in added
    assert "accounts.balance" in added
    with Session(engine) as s:
        a = s.exec(select(Alert)).one()
        assert a.title == "cũ" and a.revision == 0 and a.telegram_message_id is None
        assert s.exec(select(Transaction)).all() == []
    assert auto_migrate(engine) == []  # chạy lại không làm gì
