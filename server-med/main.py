"""Điểm vào FastAPI MedIntel — chạy: uvicorn main:app --reload --app-dir ."""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

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
        # Tạo user mặc định cho demo nếu chưa có
        from sqlalchemy.orm import Session
        from app.models.user import User
        import uuid
        with Session(engine) as session:
            try:
                raw_uid = str(settings.default_prescription_user_id).strip()
                if not raw_uid:
                    raise ValueError("default_prescription_user_id trống")
                uid = uuid.UUID(raw_uid)
                if not session.get(User, uid):
                    from app.services.auth_service import hash_password

                    demo_user = User(
                        id=uid,
                        email="demo@medintel.ai",
                        hashed_password=hash_password("demo-password-change-me"),
                        full_name="Demo User",
                    )
                    session.add(demo_user)
                    session.commit()
                    print(f"Created demo user: {uid}")
            except Exception as e:
                print(f"Could not create demo user: {e}")
    yield


app = FastAPI(
    title="MedIntel API",
    description="Backend tuân thủ điều trị — FastAPI + PostgreSQL",
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
# Thêm sau CORS: chạy ngoài cùng, log toàn bộ request/response
app.add_middleware(HttpLoggingMiddleware)

app.include_router(api_router, prefix="/api/v1")


@app.get("/health")
def health():
    return {"status": "ok", "service": "medintel-api"}
