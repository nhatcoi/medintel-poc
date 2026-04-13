from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from core.database import Base, GUID
from models.base import utc_now


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id: Mapped[uuid.UUID] = mapped_column("log_id", GUID, primary_key=True, default=uuid.uuid4)
    actor_profile_id: Mapped[uuid.UUID | None] = mapped_column(GUID, ForeignKey("profiles.profile_id"), nullable=True, index=True)
    action_type: Mapped[str] = mapped_column(String(100))
    table_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    record_id: Mapped[uuid.UUID | None] = mapped_column(GUID, nullable=True)
    old_value: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    new_value: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    ip_address: Mapped[str | None] = mapped_column(String(45), nullable=True)
    user_agent: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
