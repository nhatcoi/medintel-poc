"""Tạo database PostgreSQL nếu chưa tồn tại (user chạy Postgres có sẵn nhưng chưa có medintel_orm)."""

from __future__ import annotations

import re

from sqlalchemy import create_engine, text
from sqlalchemy.engine.url import make_url
from sqlalchemy.exc import SQLAlchemyError


def ensure_postgres_database(database_url: str) -> None:
    if not database_url.startswith("postgresql"):
        return
    url = make_url(database_url)
    target = url.database
    if not target:
        return
    if not re.fullmatch(r"[A-Za-z0-9_]+", target):
        raise ValueError(f"Tên database không hợp lệ cho bootstrap: {target!r}")

    admin = url.set(database="postgres")
    eng = create_engine(admin, isolation_level="AUTOCOMMIT")
    try:
        with eng.connect() as conn:
            row = conn.execute(
                text("SELECT 1 FROM pg_database WHERE datname = :n"),
                {"n": target},
            ).fetchone()
            if row is None:
                try:
                    conn.execute(text(f'CREATE DATABASE "{target}"'))
                    print(f"[db_bootstrap] Created PostgreSQL database: {target}")
                except SQLAlchemyError as e:
                    print(
                        "[db_bootstrap] Không thể CREATE DATABASE (cần quyền trên DB postgres). "
                        f"Tạo thủ công: createdb {target} hoặc dùng docker compose trong server-med. Lỗi: {e}"
                    )
                    raise
    finally:
        eng.dispose()
