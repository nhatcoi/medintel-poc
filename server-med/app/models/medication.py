from __future__ import annotations

import uuid
from datetime import datetime, time

from sqlalchemy import DateTime, ForeignKey, String, Text, Time
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database.session import Base


class Medication(Base):
    __tablename__ = "medications"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    prescription_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("prescriptions.id"), index=True
    )
    name: Mapped[str] = mapped_column(String(512))
    dosage: Mapped[str | None] = mapped_column(String(255), nullable=True)
    frequency: Mapped[str | None] = mapped_column(String(255), nullable=True)
    instructions: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    prescription: Mapped[Prescription] = relationship("Prescription", back_populates="medications")
    schedules: Mapped[list[MedicationSchedule]] = relationship(
        "MedicationSchedule", back_populates="medication", cascade="all, delete-orphan"
    )
    adherence_logs: Mapped[list[AdherenceLog]] = relationship("AdherenceLog", back_populates="medication")


class MedicationSchedule(Base):
    __tablename__ = "medication_schedules"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    medication_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("medications.id"), index=True
    )
    time_of_day: Mapped[time] = mapped_column(Time, nullable=False)
    days_of_week: Mapped[list[int] | None] = mapped_column(JSONB, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    medication: Mapped[Medication] = relationship("Medication", back_populates="schedules")
