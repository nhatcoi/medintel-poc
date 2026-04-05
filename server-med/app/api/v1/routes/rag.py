"""API endpoint tìm kiếm RAG dược liệu."""

from fastapi import APIRouter, HTTPException

from ai.rag.retrieval import build_rag_context, hybrid_search
from app.api.deps import DbSession
from app.schemas.rag import RagChunkResult, RagSearchRequest, RagSearchResponse

router = APIRouter()


@router.post("/search", response_model=RagSearchResponse)
async def rag_search(body: RagSearchRequest, db: DbSession):
    """Tìm kiến thức dược liệu qua hybrid search (vector + text)."""
    try:
        results = await hybrid_search(db, body.query, top_k=body.top_k)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"RAG search error: {exc}") from exc

    chunks = [
        RagChunkResult(
            chunk_id=r.chunk_id,
            drug_id=r.drug_id,
            drug_name=r.drug_name,
            section=r.section,
            content=r.content,
            similarity=r.similarity,
        )
        for r in results
    ]
    context = build_rag_context(results)
    return RagSearchResponse(query=body.query, results=chunks, context=context)
