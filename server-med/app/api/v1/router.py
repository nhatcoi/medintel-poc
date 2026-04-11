from fastapi import APIRouter

from app.api.v1.routes import (
    agent,
    auth,
    care_groups,
    chat,
    habits,
    health,
    medical_records,
    memory,
    notifications,
    ocr,
    profiles,
    rag,
    reports,
    scan,
    treatment,
)

api_router = APIRouter()
api_router.include_router(health.router, tags=["health"])
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(profiles.router, prefix="/profiles", tags=["profiles"])
api_router.include_router(chat.router, prefix="/chat", tags=["chat"])
api_router.include_router(agent.router, prefix="/agent", tags=["agent"])
api_router.include_router(treatment.router, prefix="/treatment", tags=["treatment"])
api_router.include_router(ocr.router, prefix="/ocr", tags=["ocr"])
api_router.include_router(scan.router, prefix="/scan", tags=["scan"])
api_router.include_router(rag.router, prefix="/rag", tags=["rag"])
api_router.include_router(medical_records.router, prefix="/medical-records", tags=["medical-records"])
api_router.include_router(habits.router, prefix="/habits", tags=["habits"])
api_router.include_router(care_groups.router, prefix="/care", tags=["care"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["notifications"])
api_router.include_router(memory.router, prefix="/memory", tags=["memory"])
api_router.include_router(reports.router, prefix="/reports", tags=["reports"])
