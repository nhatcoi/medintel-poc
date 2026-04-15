from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import TYPE_CHECKING

from sqlalchemy import Date, DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.database import Base, GUID
from models.base import TimestampMixin

if TYPE_CHECKING:
    from models.agent_context import PatientAgentContext
    from models.chat import ChatMessage, ChatSession
    from models.medical import MedicalRecord


class Profile(Base, TimestampMixin):
    __tablename__ = "profiles"

    id: Mapped[uuid.UUID] = mapped_column("profile_id", GUID, primary_key=True, default=uuid.uuid4)
    full_name: Mapped[str] = mapped_column(String(255))
    date_of_birth: Mapped[date | None] = mapped_column(Date, nullable=True)
    emergency_contact: Mapped[str | None] = mapped_column(String(20), nullable=True)
    role: Mapped[str] = mapped_column(String(32), default="patient")
    email: Mapped[str | None] = mapped_column(String(255), nullable=True, index=True)
    phone_number: Mapped[str | None] = mapped_column(String(20), nullable=True)
    last_server_sync_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    medical_records: Mapped[list[MedicalRecord]] = relationship("MedicalRecord", back_populates="profile")
    chat_sessions: Mapped[list[ChatSession]] = relationship(
        "ChatSession", back_populates="profile", cascade="all, delete-orphan"
    )
    chat_messages: Mapped[list[ChatMessage]] = relationship("ChatMessage", back_populates="profile")
    agent_knowledge_doc: Mapped[PatientAgentContext | None] = relationship(
        "PatientAgentContext", back_populates="profile", uselist=False, cascade="all, delete-orphan"
    )

