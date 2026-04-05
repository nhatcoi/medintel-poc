"""Điểm vào FastAPI MedIntel — chạy: uvicorn main:app --reload --app-dir ."""

import logging
import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.v1.router import api_router
from app.core.config import settings
from app.middleware.http_logging import HttpLoggingMiddleware
import app.models  # noqa: F401 — đăng ký metadata

from database.session import Base, engine

_log = logging.getLogger("uvicorn.error")
logging.getLogger("medintel.http").setLevel(logging.INFO)


@asynccontextmanager
async def lifespan(app: FastAPI):
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


app = FastAPI(
    title="MedIntel API",
    description="Backend tuân thủ điều trị — FastAPI + PostgreSQL/SQLite",
    version="0.1.0",
    lifespan=lifespan,
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


@app.get("/health")
def health():
    return {"status": "ok", "service": "medintel-api"}
