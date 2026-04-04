from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database.session import Base, GUID


class Prescription(Base):
    __tablename__ = "prescriptions"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("users.id"), index=True)
    image_url: Mapped[str | None] = mapped_column(String(1024), nullable=True)
    raw_ocr_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    doctor_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    issued_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    valid_until: Mapped[date | None] = mapped_column(Date, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    user: Mapped[User] = relationship("User", back_populates="prescriptions")
    medications: Mapped[list[Medication]] = relationship("Medication", back_populates="prescription")
