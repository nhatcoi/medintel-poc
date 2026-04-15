from __future__ import annotations

from datetime import date, datetime, time

from pydantic import BaseModel, Field


class HabitCategoryCreate(BaseModel):
    category_name: str
    description: str | None = None


class HabitCategoryRead(BaseModel):
    category_id: str
    category_name: str
    description: str | None = None


class HealthHabitCreate(BaseModel):
    profile_id: str
    habit_name: str
    category_id: str | None = None
    description: str | None = None
    target_time: time | None = None
    status: str | None = None


class HealthHabitUpdate(BaseModel):
    habit_name: str | None = None
    category_id: str | None = None
    description: str | None = None
    target_time: time | None = None
    status: str | None = None


class HealthHabitRead(BaseModel):
    habit_id: str
    profile_id: str
    habit_name: str
    category_id: str | None = None
    description: str | None = None
    target_time: time | None = None
    status: str | None = None


class HabitReminderCreate(BaseModel):
    habit_id: str
    reminder_time: time
    repeat_frequency: str
    repeat_interval: int | None = None
    repeat_days: str | None = None
    first_reminder_date: date
    end_date: date | None = None
    reminder_sound: str | None = None
    status: str | None = None


class HabitReminderUpdate(BaseModel):
    reminder_time: time | None = None
    repeat_frequency: str | None = None
    repeat_interval: int | None = None
    repeat_days: str | None = None
    first_reminder_date: date | None = None
    end_date: date | None = None
    reminder_sound: str | None = None
    status: str | None = None


class HabitReminderRead(BaseModel):
    reminder_id: str
    habit_id: str
    reminder_time: time
    repeat_frequency: str
    repeat_interval: int | None = None
    repeat_days: str | None = None
    first_reminder_date: date
    end_date: date | None = None
    reminder_sound: str | None = None
    status: str | None = None


class HabitLogCreate(BaseModel):
    habit_id: str
    profile_id: str
    scheduled_datetime: datetime
    actual_datetime: datetime | None = None
    status: str | None = None
    notes: str | None = None


class HabitLogUpdate(BaseModel):
    actual_datetime: datetime | None = None
    status: str | None = None
    notes: str | None = None


class HabitLogRead(BaseModel):
    log_id: str
    habit_id: str
    profile_id: str
    scheduled_datetime: datetime
    actual_datetime: datetime | None = None
    status: str | None = None
    notes: str | None = None


class HabitListResponse(BaseModel):
    items: list = Field(default_factory=list)

