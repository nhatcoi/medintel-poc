"""Schemas cho RAG API."""

from pydantic import BaseModel, Field


class RagSearchRequest(BaseModel):
    query: str = Field(..., min_length=1, max_length=1000)
    top_k: int = Field(default=8, ge=1, le=50)


class RagChunkResult(BaseModel):
    chunk_id: str
    drug_id: str
    drug_name: str
    section: str
    content: str
    similarity: float


class RagSearchResponse(BaseModel):
    query: str
    results: list[RagChunkResult]
    context: str
