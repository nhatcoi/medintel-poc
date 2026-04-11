"""Điểm vào FastAPI MedIntel — chạy: uvicorn main:app --reload --app-dir ."""

import logging
import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.utils import get_openapi
from fastapi.responses import RedirectResponse
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.v1.router import api_router
from app.core.config import settings
from app.core.db_bootstrap import ensure_postgres_database
from app.middleware.http_logging import HttpLoggingMiddleware
import app.models  # noqa: F401 — đăng ký metadata

from database.session import Base, engine

_log = logging.getLogger("uvicorn.error")
logging.getLogger("medintel.http").setLevel(logging.INFO)


@asynccontextmanager
async def lifespan(app: FastAPI):
    ensure_postgres_database(settings.database_url)
    if settings.create_tables_on_startup:
        Base.metadata.create_all(bind=engine)
        from app.models.medical import DiseaseCategory
        from app.models.profile import Profile

        with Session(engine) as session:
            try:
                if not session.scalars(select(DiseaseCategory).limit(1)).first():
                    session.add(
                        DiseaseCategory(
                            category_name="Chưa phân loại",
                            description="Mặc định hệ thống / OCR",
                        )
                    )
                    session.commit()
            except Exception as e:
                print(f"Could not seed disease category: {e}")
                session.rollback()

            try:
                raw_uid = str(settings.default_prescription_user_id).strip()
                if not raw_uid:
                    raise ValueError("default_prescription_user_id trống")
                uid = uuid.UUID(raw_uid)
                if not session.get(Profile, uid):
                    session.add(
                        Profile(
                            id=uid,
                            full_name="Demo User",
                            role="patient",
                            email="demo@medintel.local",
                        )
                    )
                    session.commit()
                    print(f"Created demo profile: {uid}")
            except Exception as e:
                print(f"Could not create demo profile: {e}")
                session.rollback()
    yield


_OPENAPI_TAGS = [
    {"name": "health", "description": "Kiểm tra sống"},
    {"name": "auth", "description": "Thiết lập thiết bị / profile (JWT)"},
    {"name": "profiles", "description": "Hồ sơ người dùng"},
    {"name": "chat", "description": "Chat agentic"},
    {"name": "agent", "description": "Registry & validate tool_calls"},
    {"name": "treatment", "description": "Thuốc, lịch uống, log tuân thủ"},
    {"name": "ocr", "description": "Trích xuất ảnh (LLM vision)"},
    {"name": "scan", "description": "Quét đơn thuốc + lưu DB"},
    {"name": "rag", "description": "Tìm kiếm RAG thuốc"},
    {"name": "medical-records", "description": "Hồ sơ bệnh án"},
    {"name": "habits", "description": "Thói quen sức khỏe"},
    {"name": "care", "description": "Caregiver & nhóm chăm sóc"},
    {"name": "notifications", "description": "Thông báo"},
    {"name": "memory", "description": "Bộ nhớ dài hạn bệnh nhân (KV)"},
    {"name": "reports", "description": "Báo cáo tuân thủ"},
]

_docs_on = settings.docs_enabled
app = FastAPI(
    title="MedIntel API",
    description=(
        "Backend tuân thủ điều trị — FastAPI + PostgreSQL/SQLite.\n\n"
        "**Swagger UI:** [`/docs`](/docs) · **ReDoc:** [`/redoc`](/redoc) · **OpenAPI JSON:** [`/openapi.json`](/openapi.json)"
    ),
    version="0.1.0",
    lifespan=lifespan,
    openapi_tags=_OPENAPI_TAGS,
    docs_url="/docs" if _docs_on else None,
    redoc_url="/redoc" if _docs_on else None,
    openapi_url="/openapi.json" if _docs_on else None,
)


def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
        tags=_OPENAPI_TAGS,
    )
    base = settings.openapi_public_url.rstrip("/")
    schema["servers"] = [{"url": base, "description": "Môi trường hiện tại"}]
    app.openapi_schema = schema
    return app.openapi_schema


if _docs_on:
    app.openapi = custom_openapi  # type: ignore[method-assign]

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(HttpLoggingMiddleware)

app.include_router(api_router, prefix="/api/v1")


@app.get("/", include_in_schema=False)
def root():
    """Vào trang chủ → chuyển tới Swagger."""
    if _docs_on:
        return RedirectResponse(url="/docs", status_code=307)
    return {"service": "medintel-api", "docs": "disabled"}


@app.get("/health")
def health():
    return {"status": "ok", "service": "medintel-api"}
