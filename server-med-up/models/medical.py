from __future__ import annotations

import uuid
from datetime import date
from typing import TYPE_CHECKING

from sqlalchemy import Date, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.database import Base, GUID
from models.base import TimestampMixin

if TYPE_CHECKING:
    from models.medication import Medication
    from models.profile import Profile


class DiseaseCategory(Base, TimestampMixin):
    __tablename__ = "disease_categories"

    id: Mapped[uuid.UUID] = mapped_column("category_id", GUID, primary_key=True, default=uuid.uuid4)
    category_name: Mapped[str] = mapped_column(String(255))
    description: Mapped[str | None] = mapped_column(Text, nullable=True)


class MedicalRecord(Base, TimestampMixin):
    __tablename__ = "medical_records"

    id: Mapped[uuid.UUID] = mapped_column("record_id", GUID, primary_key=True, default=uuid.uuid4)
    profile_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.profile_id"), nullable=False, index=True)
    disease_name: Mapped[str] = mapped_column(String(255))
    category_id: Mapped[uuid.UUID | None] = mapped_column(GUID, ForeignKey("disease_categories.category_id"), nullable=True, index=True)
    treatment_start_date: Mapped[date] = mapped_column(Date, nullable=False)
    treatment_status: Mapped[str | None] = mapped_column(String(64), nullable=True)
    treatment_type: Mapped[str | None] = mapped_column(String(64), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    scan_image_url: Mapped[str | None] = mapped_column(String(1024), nullable=True)
    scan_raw_ocr: Mapped[str | None] = mapped_column(Text, nullable=True)

    profile: Mapped[Profile] = relationship("Profile", back_populates="medical_records")
    category: Mapped[DiseaseCategory | None] = relationship("DiseaseCategory")
    treatment_periods: Mapped[list[TreatmentPeriod]] = relationship(
        "TreatmentPeriod", back_populates="medical_record", cascade="all, delete-orphan"
    )


class TreatmentPeriod(Base, TimestampMixin):
    __tablename__ = "treatment_periods"

    id: Mapped[uuid.UUID] = mapped_column("period_id", GUID, primary_key=True, default=uuid.uuid4)
    record_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("medical_records.record_id"), nullable=False, index=True)
    period_name: Mapped[str] = mapped_column(String(255))
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    status: Mapped[str | None] = mapped_column(String(64), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    medical_record: Mapped[MedicalRecord] = relationship("MedicalRecord", back_populates="treatment_periods")
    medications: Mapped[list[Medication]] = relationship(
        "Medication", back_populates="treatment_period", cascade="all, delete-orphan"
    )
