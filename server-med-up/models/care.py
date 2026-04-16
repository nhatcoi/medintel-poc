from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from core.database import Base, GUID
from models.base import TimestampMixin, utc_now


class CaregiverPatientLink(Base, TimestampMixin):
    __tablename__ = "caregiver_patient_links"

    id: Mapped[uuid.UUID] = mapped_column("link_id", GUID, primary_key=True, default=uuid.uuid4)
    patient_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.profile_id"), index=True)
    caregiver_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.profile_id"), index=True)
    relationship: Mapped[str | None] = mapped_column(String(100), nullable=True)
    permission_level: Mapped[str | None] = mapped_column(String(64), nullable=True)
    status: Mapped[str | None] = mapped_column(String(64), nullable=True)
    requested_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    responded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class CareGroup(Base, TimestampMixin):
    __tablename__ = "care_groups"

    id: Mapped[uuid.UUID] = mapped_column("group_id", GUID, primary_key=True, default=uuid.uuid4)
    group_name: Mapped[str] = mapped_column(String(255))
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_by_profile_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.profile_id"), nullable=False)


class CareGroupMember(Base):
    __tablename__ = "care_group_members"

    id: Mapped[uuid.UUID] = mapped_column("member_id", GUID, primary_key=True, default=uuid.uuid4)
    group_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("care_groups.group_id"), index=True)
    profile_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.profile_id"), index=True)
    role: Mapped[str | None] = mapped_column(String(64), nullable=True)
    joined_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)


class CareGroupPatient(Base):
    __tablename__ = "care_group_patients"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True, default=uuid.uuid4)
    group_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("care_groups.group_id"), index=True)
    patient_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.profile_id"), index=True)
    added_by_profile_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("profiles.profile_id"))
    added_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    consent_status: Mapped[str] = mapped_column(String(64), default="granted")
