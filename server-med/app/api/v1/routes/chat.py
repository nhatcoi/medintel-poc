from fastapi import APIRouter

from app.api.deps import DbSession
from app.schemas.chat import ChatRequest, ChatResponse
from app.services.chat_service import preview_chat_message, process_chat_message

router = APIRouter()


@router.post("/message", response_model=ChatResponse)
async def send_message(body: ChatRequest, db: DbSession):
    return await process_chat_message(db, body)


@router.post("/message/dry-run", response_model=ChatResponse)
async def send_message_dry_run(body: ChatRequest, db: DbSession):
    """Giống /message nhưng không ghi chat_sessions / chat_messages (thử prompt + LLM)."""
    return await preview_chat_message(db, body)
