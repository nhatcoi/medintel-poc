"""LLM chatbot — OpenAI-compatible API (combo-1 model)."""

from __future__ import annotations

import httpx

from app.core.config import settings

SYSTEM_PROMPT = (
    "Bạn là MedIntel Assistant — trợ lý AI y tế thông minh. "
    "Hãy trả lời câu hỏi của người dùng về sức khỏe, thuốc, liều dùng, tác dụng phụ, "
    "và tuân thủ điều trị một cách chính xác, thân thiện, bằng tiếng Việt. "
    "Nếu không chắc chắn, hãy khuyên người dùng liên hệ bác sĩ."
)


async def reply(user_message: str) -> str:
    payload = {
        "model": settings.llm_model,
        "stream": False,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_message},
        ],
    }

    async with httpx.AsyncClient(timeout=60) as client:
        resp = await client.post(
            settings.llm_base_url,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {settings.llm_api_key}",
            },
            json=payload,
        )
        resp.raise_for_status()
        data = resp.json()

    choices = data.get("choices", [])
    if not choices:
        return "Xin lỗi, tôi không thể xử lý yêu cầu này. Vui lòng thử lại."

    return choices[0].get("message", {}).get("content", "Không có phản hồi từ AI.")
