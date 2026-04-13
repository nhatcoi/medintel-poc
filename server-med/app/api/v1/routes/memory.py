"""CRUD bộ nhớ dài hạn bệnh nhân (key-value)."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, HTTPException, Query
from sqlalchemy import select

from app.api.deps import DbSession
from app.models.patient_memory import PatientMemory
from app.services.patient_agent_context_service import refresh_patient_agent_context_best_effort
from app.schemas.memory import MemoryListResponse, MemoryRead, MemoryUpsert

router = APIRouter()


@router.get("", response_model=MemoryListResponse)
def list_memories(db: DbSession, profile_id: uuid.UUID = Query(...)):
    rows = db.scalars(
        select(PatientMemory)
        .where(PatientMemory.profile_id == profile_id)
        .order_by(PatientMemory.key)
    ).all()
    items = [
        MemoryRead(
            memory_id=m.id, profile_id=m.profile_id,
            key=m.key, value=m.value, source=m.source, confidence=m.confidence,
        )
        for m in rows
    ]
    return MemoryListResponse(profile_id=profile_id, items=items)


@router.put("/{key}", response_model=MemoryRead)
def upsert_memory(key: str, profile_id: uuid.UUID, body: MemoryUpsert, db: DbSession):
    """Tạo hoặc cập nhật bộ nhớ theo (profile_id, key)."""
    existing = db.scalars(
        select(PatientMemory).where(
            PatientMemory.profile_id == profile_id, PatientMemory.key == key
        )
    ).first()
    if existing:
        existing.value = body.value
        existing.source = body.source
        existing.confidence = body.confidence
        db.commit()
        db.refresh(existing)
        m = existing
        refresh_patient_agent_context_best_effort(db, profile_id)
    else:
        m = PatientMemory(
            profile_id=profile_id, key=key,
            value=body.value, source=body.source, confidence=body.confidence,
        )
        db.add(m)
        db.commit()
        db.refresh(m)
        refresh_patient_agent_context_best_effort(db, profile_id)
    return MemoryRead(
        memory_id=m.id, profile_id=m.profile_id,
        key=m.key, value=m.value, source=m.source, confidence=m.confidence,
    )


@router.get("/{key}", response_model=MemoryRead)
def get_memory(key: str, profile_id: uuid.UUID, db: DbSession):
    m = db.scalars(
        select(PatientMemory).where(
            PatientMemory.profile_id == profile_id, PatientMemory.key == key
        )
    ).first()
    if not m:
        raise HTTPException(404, f"Không tìm thấy memory key '{key}'")
    return MemoryRead(
        memory_id=m.id, profile_id=m.profile_id,
        key=m.key, value=m.value, source=m.source, confidence=m.confidence,
    )


@router.delete("/{key}", status_code=204)
def delete_memory(key: str, profile_id: uuid.UUID, db: DbSession):
    m = db.scalars(
        select(PatientMemory).where(
            PatientMemory.profile_id == profile_id, PatientMemory.key == key
        )
    ).first()
    if not m:
        raise HTTPException(404, f"Không tìm thấy memory key '{key}'")
    db.delete(m)
    db.commit()
    refresh_patient_agent_context_best_effort(db, profile_id)
