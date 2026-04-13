from langchain_core.tools import tool


@tool
def search_drug_kb(query: str) -> str:
    """Tim kiem kien thuc thuoc trong co so du lieu RAG (pgvector). Tra ve thong tin lam sang."""
    return f"[placeholder] Ket qua RAG cho: {query}"
