import json
import logging
import time
import uuid

from fastapi import APIRouter, HTTPException, Query, Response

from app.api.deps import DbSession
from app.repositories.profile_repository import get_by_id
from app.schemas.chat import (
    ChatRequest,
    ChatResponse,
    SuggestedQuestionsResponse,
    WelcomeHintsResponse,
)
from app.services.chat import preview_chat_message, process_chat_message
from app.services.patient_suggested_questions_service import build_suggested_questions
from app.services.welcome_hints_service import build_welcome_hints

router = APIRouter()
_log = logging.getLogger("medintel.chat")


@router.get("/suggested-questions", response_model=SuggestedQuestionsResponse)
async def get_suggested_questions(
    db: DbSession,
    profile_id: str = Query(..., description="UUID profile (bệnh nhân)"),
):
    """Câu hỏi/chip gợi ý — LLM theo snapshot đã chunk hoặc template."""
    raw = (profile_id or "").strip()
    try:
        pid = uuid.UUID(raw)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="profile_id phải là UUID hợp lệ") from exc
    if get_by_id(db, pid) is None:
        raise HTTPException(status_code=404, detail="Không tìm thấy profile")
    questions, source = await build_suggested_questions(db, pid)
    return SuggestedQuestionsResponse(questions=questions, source=source)


@router.get("/welcome-hints", response_model=WelcomeHintsResponse)
async def get_welcome_hints(
    db: DbSession,
    profile_id: str = Query(..., description="UUID profile (bệnh nhân)"),
):
    """Gợi ý câu chào/typewriter: gom thuốc + log + bộ nhớ từ DB, sinh câu bằng LLM hoặc template."""
    raw = (profile_id or "").strip()
    try:
        pid = uuid.UUID(raw)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="profile_id phải là UUID hợp lệ") from exc
    if get_by_id(db, pid) is None:
        raise HTTPException(status_code=404, detail="Không tìm thấy profile")
    hints, source = await build_welcome_hints(db, pid)
    body = {"hints": hints, "source": source}
    _log.info(
        "GET /welcome-hints profile_id=%s response_json=%s",
        pid,
        json.dumps(body, ensure_ascii=False),
    )
    return WelcomeHintsResponse(hints=hints, source=source)


async def _run_chat_timed(
    *,
    route_label: str,
    response: Response,
    body: ChatRequest,
    coro,
):
    """Đo wall-clock từ đầu handler đến khi có response (gồm LLM/RAG)."""
    t0 = time.perf_counter()
    try:
        return await coro
    finally:
        ms = (time.perf_counter() - t0) * 1000
        response.headers["X-Process-Time-Ms"] = f"{ms:.1f}"
        response.headers["Server-Timing"] = f"medintel-chat;dur={ms:.1f}"
        pid = (body.profile_id or "").strip() or "-"
        _log.info("chat %s %.1fms profile_id=%s", route_label, ms, pid)


@router.post("/message", response_model=ChatResponse)
async def send_message(body: ChatRequest, db: DbSession, response: Response):
    return await _run_chat_timed(
        route_label="POST /message",
        response=response,
        body=body,
        coro=process_chat_message(db, body),
    )


@router.post("/message/dry-run", response_model=ChatResponse)
async def send_message_dry_run(body: ChatRequest, db: DbSession, response: Response):
    """Giống /message nhưng không ghi chat_sessions / chat_messages (thử prompt + LLM)."""
    return await _run_chat_timed(
        route_label="POST /message/dry-run",
        response=response,
        body=body,
        coro=preview_chat_message(db, body),
    )
