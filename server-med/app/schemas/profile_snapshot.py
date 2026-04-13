"""Response gom toàn bộ dữ liệu server theo profile (một lần gọi API)."""

from __future__ import annotations

import uuid
from datetime import date, datetime
from pydantic import BaseModel, Field

from app.schemas.medical_records import MedicalRecordRead
from app.schemas.memory import MemoryRead
from app.schemas.treatment import AdherenceSummaryResponse, MedicationScheduleSlot


class ProfileSnapshotProfile(BaseModel):
    profile_id: uuid.UUID
    full_name: str
    date_of_birth: date | None = None
    emergency_contact: str | None = None
    role: str
    email: str | None = None
    phone_number: str | None = None
    last_server_sync_at: datetime | None = None
    created_at: datetime | None = None


class DeviceSnapshotItem(BaseModel):
    device_id: uuid.UUID
    device_label: str | None = None
    platform: str | None = None
    last_seen_at: datetime | None = None


class MedicationScheduleDetail(BaseModel):
    schedule_id: uuid.UUID
    scheduled_time: str = Field(..., description="HH:MM")
    repeat_pattern: str | None = None
    status: str | None = None
    reminder_enabled: bool | None = None


class MedicationCabinetItem(BaseModel):
    """Một thuốc trong tủ (server) — liều, lịch, tồn kho, ghi chú lâm sàng."""

    medication_id: uuid.UUID
    name: str
    dosage: str | None = None
    frequency: str | None = None
    instructions: str | None = None
    status: str | None = None
    start_date: date | None = None
    end_date: date | None = None
    active_ingredient: str | None = None
    strength: str | None = None
    dosage_form: str | None = None
    route: str | None = None
    remaining_quantity: float | None = None
    quantity_unit: str | None = None
    total_quantity: float | None = None
    prescribing_doctor: str | None = None
    prescription_number: str | None = None
    prescription_date: date | None = None
    notes: str | None = None
    schedule_times: list[MedicationScheduleSlot] = Field(default_factory=list)
    schedules_detail: list[MedicationScheduleDetail] = Field(default_factory=list)


class MedicationLogSnapshotItem(BaseModel):
    log_id: uuid.UUID
    schedule_id: uuid.UUID
    medication_id: uuid.UUID
    medication_name: str
    status: str
    scheduled_datetime: datetime
    actual_datetime: datetime | None = None
    notes: str | None = None


class ProfileSnapshotResponse(BaseModel):
    profile: ProfileSnapshotProfile
    devices: list[DeviceSnapshotItem] = Field(default_factory=list)
    medical_records: list[MedicalRecordRead] = Field(default_factory=list)
    medication_cabinet: list[MedicationCabinetItem] = Field(
        default_factory=list,
        description="Thuốc + lịch uống trên server (tủ thuốc đồng bộ)",
    )
    medication_logs_recent: list[MedicationLogSnapshotItem] = Field(
        default_factory=list,
        description="Log liều gần đây (toàn bộ thuốc của profile)",
    )
    memories: list[MemoryRead] = Field(
        default_factory=list,
        description="Bộ nhớ dài hạn (KV) cho AI / ngữ cảnh",
    )
    adherence_summary: AdherenceSummaryResponse
