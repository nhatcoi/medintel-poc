from fastapi import APIRouter, HTTPException

from ai.chatbot import reply as gemini_reply
from app.schemas.chat import ChatRequest, ChatResponse

router = APIRouter()


@router.post("/message", response_model=ChatResponse)
async def send_message(body: ChatRequest):
    text = body.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text must not be empty")
    try:
        answer = await gemini_reply(text)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Gemini API error: {exc}")
    return ChatResponse(reply=answer)
