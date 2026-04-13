from __future__ import annotations

import uuid
from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from core.database import Base, GUID
from models.base import TimestampMixin

if TYPE_CHECKING:
    from models.profile import Profile


class PatientAgentContext(Base, TimestampMixin):
    __tablename__ = "patient_agent_context"

    profile_id: Mapped[uuid.UUID] = mapped_column(
        GUID, ForeignKey("profiles.profile_id", ondelete="CASCADE"), primary_key=True
    )
    content_markdown: Mapped[str] = mapped_column(Text, nullable=False)
    source: Mapped[str] = mapped_column(String(32), default="snapshot_derived", nullable=False)
    format_version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)

    profile: Mapped[Profile] = relationship("Profile", back_populates="agent_knowledge_doc")
