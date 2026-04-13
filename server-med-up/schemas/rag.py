from __future__ import annotations

from pydantic import BaseModel, Field


class RagSearchRequest(BaseModel):
    query: str
    top_k: int = 6


class RagChunkResult(BaseModel):
    drug_name: str
    section: str
    content: str
    similarity: float


class RagSearchResponse(BaseModel):
    query: str
    results: list[RagChunkResult] = Field(default_factory=list)
