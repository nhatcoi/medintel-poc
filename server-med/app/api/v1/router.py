from fastapi import APIRouter

from app.api.v1.routes import auth, chat, health, ocr, scan

api_router = APIRouter()
api_router.include_router(health.router, tags=["health"])
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(chat.router, prefix="/chat", tags=["chat"])
api_router.include_router(ocr.router, prefix="/ocr", tags=["ocr"])
api_router.include_router(scan.router, prefix="/scan", tags=["scan"])
