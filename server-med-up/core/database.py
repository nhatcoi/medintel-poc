"""SQLAlchemy engine, session, Base, GUID type."""

from __future__ import annotations

import re
import uuid
from collections.abc import Generator

from sqlalchemy import CHAR, TypeDecorator, create_engine, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.engine.url import make_url
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from core.config import settings


class GUID(TypeDecorator):
    """Platform-independent UUID: native UUID on Postgres, CHAR(32) elsewhere."""

    impl = CHAR
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == "postgresql":
            return dialect.type_descriptor(UUID())
        return dialect.type_descriptor(CHAR(32))

    def process_bind_param(self, value, dialect):
        if value is None:
            return value
        if dialect.name == "postgresql":
            return str(value)
        if not isinstance(value, uuid.UUID):
            return "%.32x" % uuid.UUID(value).int
        return "%.32x" % value.int

    def process_result_value(self, value, dialect):
        if value is None:
            return None
        if isinstance(value, uuid.UUID):
            return value
        if isinstance(value, int):
            return uuid.UUID(int=value)
        if isinstance(value, bytes):
            return uuid.UUID(bytes=value)
        if isinstance(value, str):
            s = value.strip().replace("-", "")
            if len(s) == 32:
                return uuid.UUID(hex=s)
            return uuid.UUID(value)
        return uuid.UUID(str(value))


class Base(DeclarativeBase):
    pass


_engine_args: dict = {}
if settings.database_url.startswith("sqlite"):
    _engine_args["connect_args"] = {"check_same_thread": False}

engine = create_engine(settings.database_url, pool_pre_ping=True, **_engine_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def ensure_postgres_database(database_url: str) -> None:
    """Create the target Postgres database if it doesn't exist yet."""
    if not database_url.startswith("postgresql"):
        return
    url = make_url(database_url)
    target = url.database
    if not target or not re.fullmatch(r"[A-Za-z0-9_]+", target):
        return
    admin = url.set(database="postgres")
    eng = create_engine(admin, isolation_level="AUTOCOMMIT")
    try:
        with eng.connect() as conn:
            exists = conn.execute(
                text("SELECT 1 FROM pg_database WHERE datname = :n"), {"n": target}
            ).fetchone()
            if exists is None:
                try:
                    conn.execute(text(f'CREATE DATABASE "{target}"'))
                except SQLAlchemyError:
                    pass
    finally:
        eng.dispose()
