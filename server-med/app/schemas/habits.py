"""Schema: thói quen sức khỏe, reminders, logs."""

from __future__ import annotations

import uuid
from datetime import date, datetime, time

from pydantic import BaseModel, Field


# ── HabitCategory ────────────────────────────────────────────────────────

class HabitCategoryCreate(BaseModel):
    category_name: str
    description: str | None = None


class HabitCategoryRead(BaseModel):
    category_id: uuid.UUID
    category_name: str
    description: str | None = None

    model_config = {"from_attributes": True}


# ── HealthHabit ──────────────────────────────────────────────────────────

class HabitReminderSlot(BaseModel):
    reminder_time: str = Field(..., description="HH:MM")
    repeat_frequency: str = "daily"
    repeat_interval: int | None = None
    repeat_days: str | None = None
    first_reminder_date: date | None = None
    end_date: date | None = None


class HabitCreate(BaseModel):
    profile_id: uuid.UUID
    habit_name: str
    category_id: uuid.UUID | None = None
    description: str | None = None
    target_time: str | None = Field(None, description="HH:MM")
    status: str = "active"
    reminders: list[HabitReminderSlot] = Field(default_factory=list)


class HabitUpdate(BaseModel):
    habit_name: str | None = None
    category_id: uuid.UUID | None = None
    description: str | None = None
    target_time: str | None = None
    status: str | None = None
    reminders: list[HabitReminderSlot] | None = None


class HabitReminderRead(BaseModel):
    reminder_id: uuid.UUID
    reminder_time: time
    repeat_frequency: str
    repeat_interval: int | None = None
    repeat_days: str | None = None
    first_reminder_date: date
    end_date: date | None = None
    status: str | None = None

    model_config = {"from_attributes": True}


class HabitRead(BaseModel):
    habit_id: uuid.UUID
    profile_id: uuid.UUID
    habit_name: str
    category_id: uuid.UUID | None = None
    description: str | None = None
    target_time: time | None = None
    status: str | None = None
    reminders: list[HabitReminderRead] = Field(default_factory=list)

    model_config = {"from_attributes": True}


class HabitListResponse(BaseModel):
    profile_id: uuid.UUID
    items: list[HabitRead] = Field(default_factory=list)


# ── HabitLog ─────────────────────────────────────────────────────────────

class HabitLogCreate(BaseModel):
    profile_id: uuid.UUID
    scheduled_datetime: datetime
    actual_datetime: datetime | None = None
    status: str = "completed"
    notes: str | None = None


class HabitLogRead(BaseModel):
    log_id: uuid.UUID
    habit_id: uuid.UUID
    profile_id: uuid.UUID
    scheduled_datetime: datetime
    actual_datetime: datetime | None = None
    status: str | None = None
    notes: str | None = None
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


class HabitLogListResponse(BaseModel):
    habit_id: uuid.UUID
    items: list[HabitLogRead] = Field(default_factory=list)
