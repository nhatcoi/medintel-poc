"""Long-term memory: lưu trạng thái bền theo profile (thuốc, dị ứng, thói quen…)."""

from __future__ import annotations

import uuid
from typing import Any

from sqlalchemy import Float, ForeignKey, JSON, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from database.session import Base, GUID

from app.models.mixins import TimestampMixin


class PatientMemory(Base, TimestampMixin):
    """KV bộ nhớ dài hạn theo profile — mỗi `key` là một khía cạnh (current_medications, allergy, …)."""

    __tablename__ = "patient_memory"
    __table_args__ = (
        UniqueConstraint("profile_id", "key", name="uq_patient_memory_profile_key"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        "memory_id", GUID, primary_key=True, default=uuid.uuid4
    )
    profile_id: Mapped[uuid.UUID] = mapped_column(
        GUID,
        ForeignKey("profiles.profile_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    key: Mapped[str] = mapped_column(String(128), nullable=False)
    value: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False)
    source: Mapped[str | None] = mapped_column(String(64), nullable=True)
    confidence: Mapped[float] = mapped_column(Float, default=1.0)
