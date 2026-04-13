from langchain_core.tools import tool


@tool
def check_drug_interaction(drug_a: str, drug_b: str) -> str:
    """Kiem tra tuong tac giua hai loai thuoc."""
    return f"[placeholder] Tuong tac giua {drug_a} va {drug_b}"
