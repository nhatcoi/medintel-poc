from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from core.database import Base, GUID
from models.base import TimestampMixin, utc_now


class ComplianceReport(Base):
    __tablename__ = "compliance_reports"

    id: Mapped[uuid.UUID] = mapped_column("report_id", GUID, primary_key=True, default=uuid.uuid4)
    profile_id: Mapped[uuid.UUID | None] = mapped_column(GUID, ForeignKey("profiles.profile_id"), nullable=True, index=True)
    report_type: Mapped[str] = mapped_column(String(64))
    period_start: Mapped[date] = mapped_column(Date, nullable=False)
    period_end: Mapped[date] = mapped_column(Date, nullable=False)
    total_scheduled: Mapped[int | None] = mapped_column(Integer, nullable=True)
    total_completed: Mapped[int | None] = mapped_column(Integer, nullable=True)
    total_missed: Mapped[int | None] = mapped_column(Integer, nullable=True)
    total_skipped: Mapped[int | None] = mapped_column(Integer, nullable=True)
    compliance_rate: Mapped[float | None] = mapped_column(Numeric(5, 2), nullable=True)
    generated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)


class SystemStatistic(Base, TimestampMixin):
    __tablename__ = "system_statistics"

    id: Mapped[uuid.UUID] = mapped_column("stat_id", GUID, primary_key=True, default=uuid.uuid4)
    stat_date: Mapped[date] = mapped_column(Date, unique=True, nullable=False)
    total_profiles: Mapped[int | None] = mapped_column(Integer, nullable=True)
    active_profiles: Mapped[int | None] = mapped_column(Integer, nullable=True)
    new_profiles: Mapped[int | None] = mapped_column(Integer, nullable=True)
    total_medical_records: Mapped[int | None] = mapped_column(Integer, nullable=True)
    total_medications: Mapped[int | None] = mapped_column(Integer, nullable=True)
    average_compliance_rate: Mapped[float | None] = mapped_column(Numeric(5, 2), nullable=True)


class Notification(Base, TimestampMixin):
    __tablename__ = "notifications"

    id: Mapped[uuid.UUID] = mapped_column("notification_id", GUID, primary_key=True, default=uuid.uuid4)
    profile_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.profile_id"), index=True)
    notification_type: Mapped[str] = mapped_column(String(64))
    title: Mapped[str] = mapped_column(String(255))
    message: Mapped[str] = mapped_column(Text)
    related_id: Mapped[uuid.UUID | None] = mapped_column(GUID, nullable=True)
    is_read: Mapped[bool] = mapped_column(Boolean, default=False)
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    scheduled_for: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    sent_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class SystemConfig(Base):
    __tablename__ = "system_configs"

    id: Mapped[uuid.UUID] = mapped_column("config_id", GUID, primary_key=True, default=uuid.uuid4)
    config_key: Mapped[str] = mapped_column(String(100), unique=True)
    config_value: Mapped[str | None] = mapped_column(Text, nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)
