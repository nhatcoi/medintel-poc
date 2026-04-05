"""RAG retrieval: vector search + hybrid text search → context builder."""

from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import text as sa_text
from sqlalchemy.orm import Session

from app.core.config import settings
from ai.rag.embedding import get_embedding


@dataclass
class RagResult:
    chunk_id: str
    drug_id: str
    drug_name: str
    section: str
    content: str
    similarity: float


async def vector_search(
    db: Session,
    query: str,
    *,
    top_k: int | None = None,
) -> list[RagResult]:
    """Embed query → cosine similarity search trên tbdf_drug_chunks."""
    top_k = top_k or settings.rag_top_k
    query_vec = await get_embedding(query)
    vec_literal = "[" + ",".join(str(v) for v in query_vec) + "]"

    sql = sa_text("""
        SELECT
            c.chunk_id,
            c.drug_id,
            d.name_display,
            c.section,
            c.content,
            1 - (c.embedding <=> :vec ::vector) AS similarity
        FROM tbdf_drug_chunks c
        JOIN tbdf_drugs d ON d.drug_id = c.drug_id
        WHERE c.embedding IS NOT NULL
        ORDER BY c.embedding <=> :vec ::vector
        LIMIT :k
    """)

    rows = db.execute(sql, {"vec": vec_literal, "k": top_k}).fetchall()
    return [
        RagResult(
            chunk_id=str(r[0]),
            drug_id=str(r[1]),
            drug_name=r[2],
            section=r[3],
            content=r[4],
            similarity=float(r[5]),
        )
        for r in rows
    ]


def text_search(
    db: Session,
    query: str,
    *,
    top_k: int | None = None,
) -> list[RagResult]:
    """Full-text search fallback (tsvector, không cần embedding)."""
    top_k = top_k or settings.rag_top_k

    sql = sa_text("""
        SELECT
            c.chunk_id,
            c.drug_id,
            d.name_display,
            c.section,
            c.content,
            ts_rank(c.content_tsv, plainto_tsquery('simple', :q)) AS rank
        FROM tbdf_drug_chunks c
        JOIN tbdf_drugs d ON d.drug_id = c.drug_id
        WHERE c.content_tsv @@ plainto_tsquery('simple', :q)
        ORDER BY rank DESC
        LIMIT :k
    """)

    rows = db.execute(sql, {"q": query, "k": top_k}).fetchall()
    return [
        RagResult(
            chunk_id=str(r[0]),
            drug_id=str(r[1]),
            drug_name=r[2],
            section=r[3],
            content=r[4],
            similarity=float(r[5]),
        )
        for r in rows
    ]


async def hybrid_search(
    db: Session,
    query: str,
    *,
    top_k: int | None = None,
) -> list[RagResult]:
    """Vector search chính, fallback text search nếu vector trả ít kết quả."""
    top_k = top_k or settings.rag_top_k

    try:
        results = await vector_search(db, query, top_k=top_k)
    except Exception:
        results = []

    if len(results) < 3:
        text_results = text_search(db, query, top_k=top_k)
        seen = {r.chunk_id for r in results}
        for tr in text_results:
            if tr.chunk_id not in seen:
                results.append(tr)
                seen.add(tr.chunk_id)
            if len(results) >= top_k:
                break

    return results[:top_k]


def build_rag_context(results: list[RagResult], *, max_chars: int = 6000) -> str:
    """Ghép kết quả RAG thành block text cho system prompt."""
    if not results:
        return ""

    lines: list[str] = [
        "### Kiến thức dược từ cơ sở dữ liệu (RAG)",
        "Dùng thông tin dưới đây để trả lời chính xác hơn. Trích dẫn tên thuốc khi liên quan.",
        "",
    ]
    total = 0
    for r in results:
        entry = f"**[{r.drug_name}] ({r.section})** (sim={r.similarity:.2f}):\n{r.content}\n"
        if total + len(entry) > max_chars:
            break
        lines.append(entry)
        total += len(entry)

    return "\n".join(lines)
