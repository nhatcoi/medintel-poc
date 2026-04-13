from langchain_core.tools import tool


@tool
def append_care_note(text: str) -> str:
    """Ghi chu nhanh vao nhat ky cham soc (trieu chung, cam giac, phan ung phu)."""
    return f"Da ghi chu: {text[:200]}"
