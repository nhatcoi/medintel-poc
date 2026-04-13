"""Entry point: uvicorn main:app --reload --app-dir ."""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session

from api.v1.router import api_router
from core.config import settings
from core.database import Base, engine, ensure_postgres_database
from core.middleware import HttpLoggingMiddleware
import models  # noqa: F401 — register ORM metadata

logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)s:%(name)s:%(message)s",
)

_log = logging.getLogger("uvicorn.error")
logging.getLogger("sentence_transformers").setLevel(logging.WARNING)
logging.getLogger("transformers").setLevel(logging.WARNING)
logging.getLogger("medintel.http").setLevel(logging.INFO)
logging.getLogger("medintel.chat").setLevel(logging.INFO)
logging.getLogger("medintel.agent").setLevel(logging.INFO)


def _seed_defaults(session: Session) -> None:
    """Seed default DiseaseCategory + demo profile."""
    import uuid
    from sqlalchemy import select
    from models.medical import DiseaseCategory
    from models.profile import Profile

    if not session.scalars(select(DiseaseCategory).limit(1)).first():
        session.add(DiseaseCategory(category_name="Chua phan loai", description="Mac dinh he thong"))
        session.commit()

    raw = settings.default_prescription_user_id.strip()
    if raw:
        try:
            uid = uuid.UUID(raw)
            if not session.get(Profile, uid):
                session.add(Profile(id=uid, full_name="Demo User", role="patient"))
                session.commit()
        except Exception:
            session.rollback()


@asynccontextmanager
async def lifespan(app: FastAPI):
    ensure_postgres_database(settings.database_url)

    if settings.create_tables_on_startup:
        Base.metadata.create_all(bind=engine)
        with Session(engine) as session:
            _seed_defaults(session)

    if settings.embedding_warmup_on_startup:
        import asyncio
        from rag.embedding import warmup_embedding_model
        try:
            loop = asyncio.get_running_loop()
            await loop.run_in_executor(None, warmup_embedding_model)
            _log.info("Embedding model warmup done")
        except Exception as e:
            _log.warning("Embedding warmup failed: %s", e)

    yield


app = FastAPI(
    title="MedIntel API (LangGraph)",
    description="Backend tuan thu dieu tri — FastAPI + LangGraph + PostgreSQL",
    version="0.2.0",
    lifespan=lifespan,
    docs_url="/docs" if settings.docs_enabled else None,
    redoc_url="/redoc" if settings.docs_enabled else None,
    openapi_url="/openapi.json" if settings.docs_enabled else None,
)

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
    if settings.docs_enabled:
        return RedirectResponse(url="/docs", status_code=307)
    return {"service": "medintel-api-up"}


@app.get("/health")
def health():
    return {"status": "ok", "service": "medintel-api-up", "version": "0.2.0"}
