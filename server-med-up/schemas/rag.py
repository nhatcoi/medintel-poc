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


class DrugInteractionCheckRequest(BaseModel):
    drugs: list[str]


class DrugInteractionPair(BaseModel):
    drug_a: str
    drug_b: str
    severity: str  # "high" | "medium" | "low" | "unknown"
    summary: str
    evidence: list[RagChunkResult] = Field(default_factory=list)
    source: str = "rag"  # "rag" | "tavily" | "none"


class DrugInteractionCheckResponse(BaseModel):
    checked_pairs: int
    interactions: list[DrugInteractionPair] = Field(default_factory=list)
