"""Hybrid search (vector + text fallback) on tbdf_drug_chunks."""

from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import text as sa_text
from sqlalchemy.orm import Session

from core.config import settings
from rag.embedding import embed_async


@dataclass
class RagResult:
    drug_name: str
    section: str
    content: str
    similarity: float


async def hybrid_search(db: Session, query: str, top_k: int | None = None) -> list[RagResult]:
    k = top_k or settings.rag_top_k
    vectors = await embed_async([query])
    vec = vectors[0]
    vec_str = "[" + ",".join(str(v) for v in vec) + "]"

    sql = sa_text("""
        SELECT d.name_display, c.section, c.content,
               1 - (c.embedding <=> :vec ::vector) AS similarity
        FROM tbdf_drug_chunks c
        JOIN tbdf_drugs d ON d.drug_id = c.drug_id
        WHERE c.embedding IS NOT NULL
        ORDER BY c.embedding <=> :vec ::vector
        LIMIT :k
    """)

    try:
        rows = db.execute(sql, {"vec": vec_str, "k": k}).fetchall()
    except Exception:
        return []

    return [
        RagResult(drug_name=r[0], section=r[1], content=r[2], similarity=float(r[3]))
        for r in rows
    ]


def build_rag_context(results: list[RagResult], max_chars: int | None = None) -> str:
    limit = max_chars or settings.rag_context_max_chars
    parts: list[str] = []
    total = 0
    for r in results:
        if total + len(r.content) > limit:
            break
        parts.append(f"**{r.drug_name}** ({r.section}, sim={r.similarity:.2f}):\n{r.content}")
        total += len(r.content)
    return "\n\n---\n\n".join(parts)
