from __future__ import annotations

from pydantic import BaseModel, Field


class SuggestedAction(BaseModel):
    label: str
    prompt: str
    category: str = "other"
    # Optional -- client mới có thể bấm thẳng tool/navigate/escalate thay vì chỉ gõ prompt.
    type: str | None = None  # "prompt" | "tool" | "navigate" | "escalate"
    route: str | None = None
    tool: str | None = None
    tool_args: dict | None = None
    priority: int | None = None


class ToolCall(BaseModel):
    tool: str
    args: dict = Field(default_factory=dict)


class Citation(BaseModel):
    title: str
    url: str | None = None
    source_type: str = "model"


class ChatRequest(BaseModel):
    text: str
    profile_id: str | None = None
    session_id: str | None = None
    include_medication_context: bool = False


class ChatResponse(BaseModel):
    reply: str
    source_type: str = "model"
    confidence: float = 0.4
    citations: list[Citation] = Field(default_factory=list)
    tool_calls: list[ToolCall] = Field(default_factory=list)
    suggested_actions: list[SuggestedAction] = Field(default_factory=list)
    session_id: str | None = None


class WelcomeHintsResponse(BaseModel):
    hints: list[str]
    source: str = "template"


class SuggestedQuestionsResponse(BaseModel):
    questions: list[str]
    source: str = "template"
