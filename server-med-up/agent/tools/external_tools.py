from langchain_core.tools import tool


@tool
def tavily_search(query: str) -> str:
    """Tim kiem thong tin y te ben ngoai (Tavily) khi RAG noi bo khong du."""
    return f"[placeholder] Ket qua Tavily cho: {query}"
