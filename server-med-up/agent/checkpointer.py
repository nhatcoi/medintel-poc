"""LangGraph checkpointer configuration."""

from __future__ import annotations

from langgraph.checkpoint.memory import MemorySaver

_checkpointer: MemorySaver | None = None


def get_checkpointer() -> MemorySaver:
    """Get in-memory checkpointer. Swap to PostgresSaver for production."""
    global _checkpointer
    if _checkpointer is None:
        _checkpointer = MemorySaver()
    return _checkpointer
