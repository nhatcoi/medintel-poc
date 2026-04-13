import uuid

from fastapi import APIRouter, HTTPException, Query

from api.deps import DbSession
from repositories import memory_repo
from schemas.memory import MemoryListResponse, MemoryRead, MemoryUpsert

router = APIRouter(prefix="/memory", tags=["memory"])


@router.get("/", response_model=MemoryListResponse)
def list_memory(db: DbSession, profile_id: str = Query(...)):
    try:
        pid = uuid.UUID(profile_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid UUID") from exc
    mem = memory_repo.get_all(db, pid)
    return MemoryListResponse(
        profile_id=profile_id,
        memories=[MemoryRead(key=k, value=v) for k, v in mem.items()],
    )


@router.post("/", response_model=MemoryRead)
def upsert_memory(profile_id: str, body: MemoryUpsert, db: DbSession):
    try:
        pid = uuid.UUID(profile_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid UUID") from exc
    row = memory_repo.upsert(db, pid, body.key, body.value, body.source, body.confidence)
    db.commit()
    return MemoryRead(key=row.key, value=row.value, source=row.source, confidence=row.confidence)
