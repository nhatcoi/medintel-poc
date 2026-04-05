"""LLM chatbot — OpenAI-compatible API; agentic tool_calls + gợi ý tiếp (JSON)."""

from __future__ import annotations

from ai.chatbot.llm_client import ChatTurnResult, reply
from ai.chatbot.prompts import build_system_prompt
from app.services.agent.registry import ALLOWED_TOOLS

__all__ = [
    "ALLOWED_TOOLS",
    "ChatTurnResult",
    "build_system_prompt",
    "reply",
]
