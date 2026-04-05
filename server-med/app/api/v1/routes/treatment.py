"""API điều trị — đọc thuốc đã lưu (đồng bộ với đơn quét)."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, HTTPException, Query

from app.api.deps import DbSession
from app.repositories.medication_repository import list_medications_for_profile
from app.repositories.profile_repository import get_by_id
from app.schemas.treatment import MedicationListItem, MedicationListResponse, MedicationScheduleSlot

router = APIRouter()


@router.get("/medications", response_model=MedicationListResponse)
def get_profile_medications(
    db: DbSession,
    profile_id: str = Query(..., description="UUID profile (bệnh nhân)"),
):
    raw = profile_id.strip()
    try:
        pid = uuid.UUID(raw)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="profile_id phải là UUID hợp lệ") from exc

    if get_by_id(db, pid) is None:
        raise HTTPException(status_code=404, detail="Không tìm thấy profile")

    meds = list_medications_for_profile(db, pid)
    items: list[MedicationListItem] = []
    for m in meds:
        slots = [
            MedicationScheduleSlot(scheduled_time=f"{t.hour:02d}:{t.minute:02d}") for t in m.schedule_times
        ]
        items.append(
            MedicationListItem(
                medication_id=m.medication_id,
                name=m.name,
                dosage=m.dosage,
                frequency=m.frequency,
                instructions=m.instructions,
                schedule_times=slots,
            )
        )
    return MedicationListResponse(profile_id=pid, items=items)
