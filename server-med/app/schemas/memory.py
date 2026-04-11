"""Schema: patient memory (long-term KV)."""

from __future__ import annotations

import uuid
from typing import Any

from pydantic import BaseModel, Field


class MemoryUpsert(BaseModel):
    key: str
    value: dict[str, Any]
    source: str | None = "manual"
    confidence: float = 1.0


class MemoryRead(BaseModel):
    memory_id: uuid.UUID
    profile_id: uuid.UUID
    key: str
    value: dict[str, Any]
    source: str | None = None
    confidence: float = 1.0

    model_config = {"from_attributes": True}


class MemoryListResponse(BaseModel):
    profile_id: uuid.UUID
    items: list[MemoryRead] = Field(default_factory=list)
