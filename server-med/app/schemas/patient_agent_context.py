"""API đọc / làm mới markdown ngữ cảnh agent."""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class PatientAgentContextRead(BaseModel):
    profile_id: uuid.UUID
    content_markdown: str
    source: str
    format_version: int
    updated_at: datetime | None = None
    char_count: int = Field(..., description="Độ dài nội dung markdown")
