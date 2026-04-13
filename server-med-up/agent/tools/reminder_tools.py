from langchain_core.tools import tool


@tool
def save_reminder_intent(title: str, detail: str = "") -> str:
    """Luu y dinh nhac (nhap); bao thuc that do app xu ly."""
    return f"Da luu nhac: {title}" + (f" - {detail}" if detail else "")
