from langchain_core.tools import tool


@tool
def update_patient_memory(key: str, value: str, confidence: float = 0.9) -> str:
    """Ghi nho dai han ve benh nhan (server-side). key: current_medications|allergies|chronic_conditions|reminder_preferences|lifestyle_notes."""
    return f"Da cap nhat bo nho: {key} = {value[:100]}"
