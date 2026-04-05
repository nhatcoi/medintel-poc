from fastapi import APIRouter, HTTPException

from ai.chatbot import reply as llm_reply
from app.schemas.chat import ChatRequest, ChatResponse, SuggestedAction, ToolCall

router = APIRouter()


@router.post("/message", response_model=ChatResponse)
async def send_message(body: ChatRequest):
    text = body.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text must not be empty")
    try:
        turn = await llm_reply(text)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Gemini API error: {exc}")
    actions = [
        SuggestedAction(
            label=a["label"],
            prompt=a["prompt"] if a.get("prompt") else a["label"],
        )
        for a in turn.suggested_actions
    ]
    tools = [ToolCall(tool=t["tool"], args=t.get("args") or {}) for t in turn.tool_calls]
    return ChatResponse(reply=turn.reply, suggested_actions=actions, tool_calls=tools)
