from fastapi import APIRouter

from api.deps import DbSession
from rag.retrieval import hybrid_search
from schemas.rag import RagChunkResult, RagSearchRequest, RagSearchResponse

router = APIRouter(prefix="/rag", tags=["rag"])


@router.post("/search", response_model=RagSearchResponse)
async def search_rag(body: RagSearchRequest, db: DbSession):
    results = await hybrid_search(db, body.query, top_k=body.top_k)
    return RagSearchResponse(
        query=body.query,
        results=[
            RagChunkResult(
                drug_name=r.drug_name,
                section=r.section,
                content=r.content,
                similarity=r.similarity,
            )
            for r in results
        ],
    )
