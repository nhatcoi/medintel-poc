"""PatientState -- shared state flowing through the LangGraph graph."""

from __future__ import annotations

from typing import Annotated, Any, TypedDict

from langchain_core.messages import BaseMessage
from langgraph.graph.message import add_messages


class PatientState(TypedDict, total=False):
    # -- Input --
    messages: Annotated[list[BaseMessage], add_messages]
    profile_id: str | None
    session_id: str | None
    include_medication_context: bool

    # -- Intent --
    current_intent: str
    intent_confidence: float
    entities: dict[str, Any]

    # -- Context (populated by context_loader) --
    patient_info: dict[str, Any]
    medications: list[dict[str, Any]]
    adherence_summary: dict[str, Any]
    memory: dict[str, Any]

    # -- RAG --
    retrieved_context: str
    rag_results: list[dict[str, Any]]

    # -- Reasoning --
    tool_calls: list[dict[str, Any]]
    tool_results: list[dict[str, Any]]
    pending_write_action: dict[str, Any]
    last_confirmation_status: str
    user_confirms_pending: bool
    confidence: float

    # -- Safety --
    risk_level: str
    needs_human_review: bool

    # -- Output --
    reply: str
    suggested_actions: list[dict[str, str]]
    citations: list[dict[str, str | None]]
    source_type: str
