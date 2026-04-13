from fastapi import APIRouter

from api.v1.routes import (
    agent,
    auth,
    chat,
    health,
    medical_records,
    memory,
    profiles,
    rag,
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
api_router.include_router(memory.router)
