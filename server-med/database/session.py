from collections.abc import Generator
import uuid

from sqlalchemy import create_engine, TypeDecorator, CHAR
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.core.config import settings

class GUID(TypeDecorator):
    """Platform-independent GUID type.
    Uses PostgreSQL's UUID type, otherwise uses CHAR(32), storing as string without hyphens.
    """
    impl = CHAR
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == 'postgresql':
            return dialect.type_descriptor(UUID())
        else:
            return dialect.type_descriptor(CHAR(32))

    def process_bind_param(self, value, dialect):
        if value is None:
            return value
        elif dialect.name == 'postgresql':
            return str(value)
        else:
            if not isinstance(value, uuid.UUID):
                return "%.32x" % uuid.UUID(value).int
            else:
                return "%.32x" % value.int

    def process_result_value(self, value, dialect):
        """SQLite/psycopg có thể trả str, bytes, uuid.UUID hoặc int (UUID 128-bit)."""
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


# SQLite cần check_same_thread=False để chạy được với FastAPI async
engine_args = {}
if settings.database_url.startswith("sqlite"):
    engine_args["connect_args"] = {"check_same_thread": False}

engine = create_engine(settings.database_url, pool_pre_ping=True, **engine_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
