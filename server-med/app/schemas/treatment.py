"""Schema API điều trị / thuốc."""

from __future__ import annotations

from datetime import date, datetime
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
    status: str | None = None
    remaining_quantity: float | None = None
    quantity_unit: str | None = None
    schedule_times: list[MedicationScheduleSlot] = Field(default_factory=list)


class MedicationListResponse(BaseModel):
    profile_id: uuid.UUID
    items: list[MedicationListItem] = Field(default_factory=list)


class MedicationCreateRequest(BaseModel):
    profile_id: uuid.UUID
    medication_name: str
    dosage: str | None = None
    frequency: str | None = None
    instructions: str | None = None
    start_date: date | None = None
    end_date: date | None = None
    status: str = "active"
    remaining_quantity: float | None = None
    quantity_unit: str | None = None
    schedule_times: list[str] = Field(default_factory=list, description="Danh sách HH:MM")


class MedicationUpdateRequest(BaseModel):
    medication_name: str | None = None
    dosage: str | None = None
    frequency: str | None = None
    instructions: str | None = None
    status: str | None = None
    end_date: date | None = None
    remaining_quantity: float | None = None
    quantity_unit: str | None = None
    schedule_times: list[str] | None = Field(default=None, description="Ghi đè danh sách HH:MM")


class MedicationLogCreateRequest(BaseModel):
    profile_id: uuid.UUID
    status: str = Field(default="taken", description="taken | missed | skipped | late")
    scheduled_datetime: datetime | None = None
    actual_datetime: datetime | None = None
    notes: str | None = None


class MedicationLogItem(BaseModel):
    log_id: uuid.UUID
    schedule_id: uuid.UUID
    medication_id: uuid.UUID
    medication_name: str
    status: str
    scheduled_datetime: datetime
    actual_datetime: datetime | None = None
    notes: str | None = None


class MedicationLogListResponse(BaseModel):
    medication_id: uuid.UUID
    items: list[MedicationLogItem] = Field(default_factory=list)


class AdherenceSummaryResponse(BaseModel):
    profile_id: uuid.UUID
    days: int = 7
    total: int = 0
    taken: int = 0
    missed: int = 0
    skipped: int = 0
    late: int = 0
