from __future__ import annotations

from typing import Any

from pydantic import BaseModel, Field


class MemoryUpsert(BaseModel):
    key: str
    value: Any
    source: str = "user"
    confidence: float = 1.0


class MemoryRead(BaseModel):
    key: str
    value: Any
    source: str | None = None
    confidence: float = 1.0


class MemoryListResponse(BaseModel):
    profile_id: str
    memories: list[MemoryRead] = Field(default_factory=list)
