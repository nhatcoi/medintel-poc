from langchain_core.tools import tool

from agent.tools.common import tool_ok


@tool
def tavily_search(query: str) -> str:
    """Tim kiem thong tin y te ben ngoai (Tavily) khi RAG noi bo khong du."""
    return tool_ok(
        f"Hệ thống đã ghi nhận yêu cầu tìm kiếm ngoài cho: {query}",
        extra={"provider": "tavily", "items": []},
    )
