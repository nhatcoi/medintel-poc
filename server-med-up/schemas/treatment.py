from __future__ import annotations

from datetime import date, datetime, time

from pydantic import BaseModel, Field


class MedicationCreate(BaseModel):
    profile_id: str
    period_id: str | None = None
    medication_name: str
    active_ingredient: str | None = None
    strength: str | None = None
    dosage_form: str | None = None
    dosage: str | None = None
    frequency: str | None = None
    route: str | None = None
    duration_days: int | None = None
    start_date: date
    end_date: date | None = None
    instructions: str | None = None
    notes: str | None = None


class MedicationRead(BaseModel):
    medication_id: str
    medication_name: str
    dosage: str | None = None
    frequency: str | None = None
    start_date: date
    end_date: date | None = None
    instructions: str | None = None
    status: str | None = None
    period_id: str | None = None


class MedicationListResponse(BaseModel):
    medications: list[MedicationRead]


class MedicationUpdate(BaseModel):
    medication_name: str | None = None
    dosage: str | None = None
    frequency: str | None = None
    instructions: str | None = None
    start_date: date | None = None
    end_date: date | None = None
    status: str | None = None
    notes: str | None = None


class MedicationSearchItem(BaseModel):
    medication_id: str
    medication_name: str
    active_ingredient: str | None = None
    indications: str | None = None


class MedicationSearchResponse(BaseModel):
    items: list[MedicationSearchItem]


class ScheduleRead(BaseModel):
    schedule_id: str
    medication_id: str
    medication_name: str | None = None
    scheduled_time: time
    reminder_enabled: bool = True
    status: str | None = None


class ScheduleCreate(BaseModel):
    scheduled_time: time
    repeat_pattern: str | None = None
    repeat_days: str | None = None
    start_date: date | None = None
    end_date: date | None = None
    reminder_enabled: bool = True
    reminder_time_before: int | None = None
    reminder_sound: str | None = None
    status: str | None = "active"


class ScheduleUpdate(BaseModel):
    scheduled_time: time | None = None
    repeat_pattern: str | None = None
    repeat_days: str | None = None
    start_date: date | None = None
    end_date: date | None = None
    reminder_enabled: bool | None = None
    reminder_time_before: int | None = None
    reminder_sound: str | None = None
    status: str | None = None


class LogCreate(BaseModel):
    schedule_id: str
    profile_id: str
    status: str = "taken"
    scheduled_datetime: datetime
    actual_datetime: datetime | None = None
    notes: str | None = None


class LogUpdate(BaseModel):
    status: str | None = None
    actual_datetime: datetime | None = None
    notes: str | None = None


class LogRead(BaseModel):
    log_id: str
    schedule_id: str
    medication_id: str | None = None
    medication_name: str | None = None
    status: str
    scheduled_datetime: datetime
    actual_datetime: datetime | None = None
    notes: str | None = None


class AdherenceSummary(BaseModel):
    profile_id: str
    days: int = 7
    total_scheduled: int = 0
    taken: int = 0
    missed: int = 0
    skipped: int = 0
    late: int = 0
    compliance_rate: float = 0.0
    on_time_rate: float = 0.0


class NextDoseResponse(BaseModel):
    medication_id: str
    medication_name: str
    schedule_id: str
    scheduled_datetime: datetime


class MissedDoseItem(BaseModel):
    medication_id: str
    medication_name: str
    schedule_id: str
    scheduled_datetime: datetime
    minutes_overdue: int


class MissedDoseCheckResponse(BaseModel):
    profile_id: str
    items: list[MissedDoseItem]
