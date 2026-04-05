"""API lõi agent — registry tool, chuẩn hoá tool_calls (client / gateway)."""

from __future__ import annotations

from fastapi import APIRouter

from app.schemas.agent_tools import (
    ToolCallPayload,
    ToolDescriptor,
    ToolRegistryResponse,
    ToolValidateRequest,
    ToolValidateResponse,
)
from app.services.agent.registry import ALLOWED_TOOLS, TOOL_DESCRIPTIONS
from app.services.agent.tool_validation import validate_incoming_tool_calls

router = APIRouter()


@router.get("/tools", response_model=ToolRegistryResponse)
def list_agent_tools():
    tools = [
        ToolDescriptor(name=name, description=TOOL_DESCRIPTIONS.get(name, ""))
        for name in sorted(ALLOWED_TOOLS)
    ]
    return ToolRegistryResponse(tools=tools)


@router.post("/tools/validate", response_model=ToolValidateResponse)
def validate_tool_calls(body: ToolValidateRequest):
    raw = [tc.model_dump() for tc in body.tool_calls]
    validated = validate_incoming_tool_calls(raw)
    dropped = max(0, len(body.tool_calls) - len(validated))
    return ToolValidateResponse(
        tool_calls=[
            ToolCallPayload(tool=str(t["tool"]), args=dict(t.get("args") or {})) for t in validated
        ],
        dropped_count=dropped,
    )
