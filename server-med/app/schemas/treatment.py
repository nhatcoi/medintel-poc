"""Schema API điều trị / thuốc."""

from __future__ import annotations

import uuid

from pydantic import BaseModel, Field


class MedicationScheduleSlot(BaseModel):
    scheduled_time: str = Field(..., description="HH:MM")


class MedicationListItem(BaseModel):
    medication_id: uuid.UUID
    name: str
    dosage: str | None = None
    frequency: str | None = None
    instructions: str | None = None
    schedule_times: list[MedicationScheduleSlot] = Field(default_factory=list)


class MedicationListResponse(BaseModel):
    profile_id: uuid.UUID
    items: list[MedicationListItem] = Field(default_factory=list)
