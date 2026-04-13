"""Node 3: RAG retrieval from drug knowledge base (pgvector)."""

from __future__ import annotations

from langchain_core.messages import HumanMessage

from agent.state import PatientState


async def rag_retriever(state: PatientState) -> dict:
    last_msg = ""
    for msg in reversed(state.get("messages", [])):
        if isinstance(msg, HumanMessage):
            last_msg = msg.content
            break

    if not last_msg:
        return {"retrieved_context": "", "rag_results": []}

    try:
        from rag.retrieval import hybrid_search, build_rag_context
        from core.database import SessionLocal

        db = SessionLocal()
        try:
            results = await hybrid_search(db, last_msg)
            context = build_rag_context(results)
            return {
                "retrieved_context": context,
                "rag_results": [
                    {"drug": r.drug_name, "section": r.section, "similarity": r.similarity}
                    for r in results
                ],
            }
        finally:
            db.close()
    except Exception:
        return {"retrieved_context": "", "rag_results": []}
