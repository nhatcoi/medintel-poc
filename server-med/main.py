"""Điểm vào FastAPI MedIntel — chạy: uvicorn main:app --reload --app-dir ."""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.utils import get_openapi
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session

from app.api.v1.router import api_router
from app.core.config import settings
from app.core.db_bootstrap import ensure_postgres_database
from app.core.startup_seed import seed_reference_data
from app.middleware.http_logging import HttpLoggingMiddleware
import app.models  # noqa: F401 — đăng ký metadata

from database.session import Base, engine

_log = logging.getLogger("uvicorn.error")
logging.getLogger("medintel.http").setLevel(logging.INFO)
logging.getLogger("medintel.welcome_hints").setLevel(logging.INFO)
logging.getLogger("medintel.chat").setLevel(logging.INFO)
# Giảm log "BertModel LOAD REPORT" / position_ids khi nạp sentence-transformers
logging.getLogger("sentence_transformers").setLevel(logging.WARNING)
logging.getLogger("transformers").setLevel(logging.WARNING)
logging.getLogger("transformers.modeling_utils").setLevel(logging.ERROR)


@asynccontextmanager
async def lifespan(app: FastAPI):
    ensure_postgres_database(settings.database_url)
    if settings.create_tables_on_startup:
        Base.metadata.create_all(bind=engine)
        with Session(engine) as session:
            seed_reference_data(session)

    if settings.embedding_warmup_on_startup:
        import asyncio

        from ai.rag.embedding import warmup_embedding_model

        try:
            loop = asyncio.get_running_loop()
            await loop.run_in_executor(None, warmup_embedding_model)
            _log.info("Embedding model warmup done")
        except Exception as e:
            _log.warning("Embedding warmup failed (RAG sẽ nạp lần đầu khi cần): %s", e)

    yield
    try:
        from ai.chatbot.llm_client import close_llm_http_client

        await close_llm_http_client()
    except Exception:
        pass


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
