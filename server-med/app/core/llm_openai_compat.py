"""Tham số payload chat completions theo provider (Groq dùng max_completion_tokens)."""


def apply_max_output_tokens(payload: dict, *, base_url: str, limit: int) -> None:
    """Gắn giới hạn độ dài sinh; Groq khuyến nghị max_completion_tokens thay cho max_tokens."""
    if limit <= 0:
        return
    url = (base_url or "").lower()
    if "groq.com" in url:
        payload["max_completion_tokens"] = limit
    else:
        payload["max_tokens"] = limit
