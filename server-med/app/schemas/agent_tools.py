"""Schema validate / liệt kê tool agent."""

from __future__ import annotations

from typing import Any

from pydantic import BaseModel, Field

from app.services.agent.registry import ALLOWED_TOOLS, TOOL_DESCRIPTIONS


class ToolCallPayload(BaseModel):
    tool: str
    args: dict[str, Any] = Field(default_factory=dict)


class ToolValidateRequest(BaseModel):
    tool_calls: list[ToolCallPayload] = Field(default_factory=list)


class ToolValidateResponse(BaseModel):
    tool_calls: list[ToolCallPayload]
    dropped_count: int = Field(
        default=0,
        description="Số phần tử bị loại (tên tool không nằm trong whitelist)",
    )


class ToolDescriptor(BaseModel):
    name: str
    description: str


class ToolRegistryResponse(BaseModel):
    tools: list[ToolDescriptor]
