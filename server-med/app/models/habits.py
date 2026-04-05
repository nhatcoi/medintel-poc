"""§5 db-design: health_habits, habit_categories, habit_reminders, habit_logs."""

from __future__ import annotations

import uuid
from datetime import date, datetime, time

from sqlalchemy import Date, DateTime, ForeignKey, Integer, String, Text, Time
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database.session import Base, GUID

from app.models.mixins import TimestampMixin, utc_now


class HabitCategory(Base, TimestampMixin):
    __tablename__ = "habit_categories"

    id: Mapped[uuid.UUID] = mapped_column("category_id", GUID, primary_key=True, default=uuid.uuid4)
    category_name: Mapped[str] = mapped_column(String(100))
    description: Mapped[str | None] = mapped_column(Text, nullable=True)


class HealthHabit(Base, TimestampMixin):
    __tablename__ = "health_habits"

    id: Mapped[uuid.UUID] = mapped_column("habit_id", GUID, primary_key=True, default=uuid.uuid4)
    profile_id: Mapped[uuid.UUID] = mapped_column(
        GUID, ForeignKey("profiles.profile_id"), nullable=False, index=True
    )
    habit_name: Mapped[str] = mapped_column(String(255))
    category_id: Mapped[uuid.UUID | None] = mapped_column(
        GUID, ForeignKey("habit_categories.category_id"), nullable=True
    )
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    target_time: Mapped[time | None] = mapped_column(Time, nullable=True)
    status: Mapped[str | None] = mapped_column(String(64), nullable=True)

    reminders: Mapped[list[HabitReminder]] = relationship(
        "HabitReminder", back_populates="habit", cascade="all, delete-orphan"
    )


class HabitReminder(Base, TimestampMixin):
    __tablename__ = "habit_reminders"

    id: Mapped[uuid.UUID] = mapped_column("reminder_id", GUID, primary_key=True, default=uuid.uuid4)
    habit_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("health_habits.habit_id"), index=True)
    reminder_time: Mapped[time] = mapped_column(Time, nullable=False)
    repeat_frequency: Mapped[str] = mapped_column(String(50))
    repeat_interval: Mapped[int | None] = mapped_column(Integer, nullable=True)
    repeat_days: Mapped[str | None] = mapped_column(String(50), nullable=True)
    first_reminder_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    reminder_sound: Mapped[str | None] = mapped_column(String(100), nullable=True)
    status: Mapped[str | None] = mapped_column(String(64), nullable=True)

    habit: Mapped[HealthHabit] = relationship("HealthHabit", back_populates="reminders")


class HabitLog(Base):
    __tablename__ = "habit_logs"

    id: Mapped[uuid.UUID] = mapped_column("log_id", GUID, primary_key=True, default=uuid.uuid4)
    habit_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("health_habits.habit_id"), index=True)
    profile_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.profile_id"), index=True)
    scheduled_datetime: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    actual_datetime: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[str | None] = mapped_column(String(64), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)
