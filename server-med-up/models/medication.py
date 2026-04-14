from __future__ import annotations

import uuid
from datetime import date, datetime, time
from typing import TYPE_CHECKING

from sqlalchemy import Date, DateTime, ForeignKey, Numeric, String, Text, Time
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.database import Base, GUID
from models.base import TimestampMixin

if TYPE_CHECKING:
    from models.medical import TreatmentPeriod


class Medication(Base, TimestampMixin):
    __tablename__ = "medications"

    id: Mapped[uuid.UUID] = mapped_column("medication_id", GUID, primary_key=True, default=uuid.uuid4)
    period_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("treatment_periods.period_id"), nullable=False, index=True)
    medication_name: Mapped[str] = mapped_column(String(255))
    dosage: Mapped[str | None] = mapped_column(String(100), nullable=True)
    frequency: Mapped[str | None] = mapped_column(String(100), nullable=True)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    instructions: Mapped[str | None] = mapped_column(Text, nullable=True)
    quantity_unit: Mapped[str | None] = mapped_column(String(50), nullable=True)
    remaining_quantity: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str | None] = mapped_column(String(64), nullable=True)

    treatment_period: Mapped[TreatmentPeriod] = relationship("TreatmentPeriod", back_populates="medications")
    schedules: Mapped[list[MedicationSchedule]] = relationship(
        "MedicationSchedule", back_populates="medication", cascade="all, delete-orphan"
    )


class MedicationSchedule(Base, TimestampMixin):
    __tablename__ = "medication_schedules"

    id: Mapped[uuid.UUID] = mapped_column("schedule_id", GUID, primary_key=True, default=uuid.uuid4)
    medication_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("medications.medication_id"), nullable=False, index=True)
    scheduled_time: Mapped[time] = mapped_column(Time, nullable=False)
    status: Mapped[str | None] = mapped_column(String(64), nullable=True)

    medication: Mapped[Medication] = relationship("Medication", back_populates="schedules")
    logs: Mapped[list[MedicationLog]] = relationship(
        "MedicationLog", back_populates="schedule", cascade="all, delete-orphan"
    )


class MedicationLog(Base, TimestampMixin):
    __tablename__ = "medication_logs"

    id: Mapped[uuid.UUID] = mapped_column("log_id", GUID, primary_key=True, default=uuid.uuid4)
    schedule_id: Mapped[uuid.UUID] = mapped_column(
        GUID, ForeignKey("medication_schedules.schedule_id", use_alter=True), nullable=False, index=True
    )
    profile_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.profile_id"), nullable=False, index=True)
    scheduled_datetime: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    actual_datetime: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[str] = mapped_column(String(32), default="taken")
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    logged_by_profile_id: Mapped[uuid.UUID | None] = mapped_column(GUID, ForeignKey("profiles.profile_id"), nullable=True)

    schedule: Mapped[MedicationSchedule] = relationship("MedicationSchedule", back_populates="logs")
