from fastapi import APIRouter

from api.deps import DbSession
from rag.retrieval import hybrid_search
from schemas.rag import (
    DrugInteractionCheckRequest,
    DrugInteractionCheckResponse,
    DrugInteractionPair,
    RagChunkResult,
    RagSearchRequest,
    RagSearchResponse,
)

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


_HIGH_KEYWORDS = ("chống chỉ định", "không được dùng chung", "nguy hiểm", "nghiêm trọng")
_MED_KEYWORDS = ("thận trọng", "cân nhắc", "theo dõi", "tăng nguy cơ", "giảm hiệu quả")


def _classify_severity(text: str) -> str:
    lower = text.lower()
    if any(k in lower for k in _HIGH_KEYWORDS):
        return "high"
    if any(k in lower for k in _MED_KEYWORDS):
        return "medium"
    return "low"


@router.post("/drug-interactions", response_model=DrugInteractionCheckResponse)
async def check_drug_interactions(body: DrugInteractionCheckRequest, db: DbSession):
    """Kiểm tra tương tác giữa các thuốc trong tủ thuốc qua RAG (pgvector).

    Chiến lược: với mỗi cặp thuốc, thực hiện semantic search truy vấn
    "tương tác thuốc {A} và {B}", lọc các chunk có nhắc tên thuốc còn lại,
    phân loại mức độ theo từ khóa lâm sàng. Nếu không có bằng chứng nội bộ,
    trả severity="unknown" + gợi ý fallback tavily (thực thi ở client/agent).
    """
    drugs = [d.strip() for d in body.drugs if d and d.strip()]
    # deduplicate giữ nguyên thứ tự
    seen: set[str] = set()
    unique: list[str] = []
    for d in drugs:
        key = d.lower()
        if key in seen:
            continue
        seen.add(key)
        unique.append(d)

    interactions: list[DrugInteractionPair] = []
    pairs = 0
    for i in range(len(unique)):
        for j in range(i + 1, len(unique)):
            a, b = unique[i], unique[j]
            pairs += 1
            query = f"tương tác thuốc {a} và {b}"
            try:
                rag_results = await hybrid_search(db, query, top_k=4)
            except Exception:
                rag_results = []

            # Lọc chunk nhắc cả hai tên (hoặc tên B xuất hiện trong nội dung của A)
            a_low = a.lower()
            b_low = b.lower()
            relevant = [
                r for r in rag_results
                if (a_low in r.content.lower() or a_low in r.drug_name.lower())
                and (b_low in r.content.lower() or b_low in r.drug_name.lower())
            ]
            if not relevant and rag_results:
                # nới lỏng: chấp nhận chunk liên quan tới 1 trong 2 thuốc với sim cao
                relevant = [r for r in rag_results[:2] if r.similarity >= 0.55]

            if relevant:
                joined = "\n".join(r.content for r in relevant[:2])
                severity = _classify_severity(joined)
                first = relevant[0]
                summary = first.content.strip().split("\n")[0]
                if len(summary) > 220:
                    summary = summary[:217] + "..."
                interactions.append(
                    DrugInteractionPair(
                        drug_a=a,
                        drug_b=b,
                        severity=severity,
                        summary=summary,
                        evidence=[
                            RagChunkResult(
                                drug_name=r.drug_name,
                                section=r.section,
                                content=r.content[:400],
                                similarity=r.similarity,
                            )
                            for r in relevant[:3]
                        ],
                        source="rag",
                    )
                )
            else:
                interactions.append(
                    DrugInteractionPair(
                        drug_a=a,
                        drug_b=b,
                        severity="unknown",
                        summary=(
                            "Chưa có bằng chứng tương tác trong kho tri thức nội bộ. "
                            "Nên kiểm tra thêm nguồn ngoài hoặc hỏi dược sĩ."
                        ),
                        evidence=[],
                        source="none",
                    )
                )
    return DrugInteractionCheckResponse(checked_pairs=pairs, interactions=interactions)
