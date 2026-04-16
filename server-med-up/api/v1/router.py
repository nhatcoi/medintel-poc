from fastapi import APIRouter

from api.v1.routes import (
    agent,
    auth,
    care,
    chat,
    health,
    habits,
    medical_records,
    notifications,
    profiles,
    rag,
    reminders,
    scan,
    treatment,
)

api_router = APIRouter()

api_router.include_router(health.router)
api_router.include_router(auth.router)
api_router.include_router(profiles.router)
api_router.include_router(chat.router)
api_router.include_router(agent.router)
api_router.include_router(treatment.router)
api_router.include_router(scan.router)
api_router.include_router(rag.router)
api_router.include_router(medical_records.router)
api_router.include_router(care.router)
api_router.include_router(habits.router)
api_router.include_router(notifications.router)
api_router.include_router(reminders.router, prefix="/reminders", tags=["reminders"])
