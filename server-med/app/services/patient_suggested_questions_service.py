"""Sinh câu hỏi gợi ý (quick replies) từ context đã chunk + LLM hoặc template."""

from __future__ import annotations

import json
import logging
import uuid

import httpx
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.llm_openai_compat import apply_max_output_tokens
from app.repositories.profile_repository import get_by_id
from app.schemas.profile_snapshot import ProfileSnapshotResponse
from app.services.patient_context_chunks import format_chunks_for_llm, snapshot_to_markdown_chunks
from app.services.patient_snapshot_service import build_patient_snapshot

_log = logging.getLogger("medintel.suggested_questions")

SUGGESTED_Q_SYSTEM = """Bạn sinh 5–8 câu hỏi hoặc gợi ý ngắn (tiếng Việt) mà bệnh nhân có thể chạm để chat tiếp trong app MedIntel.
Chỉ trả về MỘT object JSON, không markdown, không văn bản ngoài JSON:
{"questions":["câu 1","câu 2",...]}

Quy tắc:
- Mỗi câu ≤ 100 ký tự, thân thiện, có thể là câu hỏi hoặc mệnh lệnh gợi ý (vd. "Nhắc tôi uống Amlodipine tối nay").
- Bám vào dữ liệu: thuốc đang uống, giờ nhắc, log taken/missed, tuân thủ, bệnh nền, dị ứng nếu có.
- Không lặp lại cùng một ý; không nhắc UUID hay id kỹ thuật.
- Không thêm chữ trước/sau JSON."""


def _parse_questions_payload(content: str) -> list[str] | None:
    raw = (content or "").strip()
    if not raw:
        return None
    for chunk in (raw, raw[raw.find("{") : raw.rfind("}") + 1] if "{" in raw else raw):
        try:
            data = json.loads(chunk)
        except json.JSONDecodeError:
            continue
        if not isinstance(data, dict):
            continue
        qs = data.get("questions")
        if not isinstance(qs, list):
            continue
        out = [str(x).strip() for x in qs if str(x).strip()]
        return out[:12] if out else None
    return None


async def llm_suggested_questions(context_markdown: str) -> list[str] | None:
    if not (settings.llm_api_key or "").strip():
        return None
    payload: dict = {
        "model": settings.llm_model,
        "stream": False,
        "messages": [
            {"role": "system", "content": SUGGESTED_Q_SYSTEM},
            {
                "role": "user",
                "content": f"Ngữ cảnh bệnh nhân:\n{context_markdown}",
            },
        ],
    }
    apply_max_output_tokens(payload, base_url=settings.llm_base_url, limit=512)
    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(25.0, connect=10.0)) as client:
            resp = await client.post(
                settings.llm_base_url,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {settings.llm_api_key}",
                },
                json=payload,
            )
        if resp.status_code >= 400:
            _log.warning("suggested_questions LLM HTTP %s", resp.status_code)
            return None
        body = resp.json()
        choices = body.get("choices") or []
        if not choices:
            return None
        text = (choices[0].get("message") or {}).get("content") or ""
        return _parse_questions_payload(text)
    except Exception as exc:  # noqa: BLE001
        _log.warning("suggested_questions LLM error: %s", exc)
        return None


def template_suggested_questions_from_snapshot(snap: ProfileSnapshotResponse) -> list[str]:
    out: list[str] = []
    if snap.medication_cabinet:
        m0 = snap.medication_cabinet[0]
        times = ", ".join(s.scheduled_time for s in m0.schedule_times) or "—"
        out.append(f"Hôm nay tôi đã uống {m0.name} đúng giờ chưa?")
        out.append(f"Nhắc lại lịch uống {m0.name} ({times})")
        if len(snap.medication_cabinet) > 1:
            out.append(f"Tôi đang uống {len(snap.medication_cabinet)} loại thuốc — có tương tác không?")
    else:
        out.append("Làm sao để thêm thuốc từ đơn quét?")
    if snap.adherence_summary.missed > 0:
        out.append("Tôi bị missed liều — nên xử lý thế nào?")
    for mem in snap.memories:
        if mem.key == "allergies":
            out.append("Nhắc lại dị ứng của tôi")
            break
    out.append("Tóm tắt tuân thủ tuần này")
    return out[:10]


async def build_suggested_questions(db: Session, profile_id: uuid.UUID) -> tuple[list[str], str]:
    """Trả về (questions, source) với source llm | template."""
    if get_by_id(db, profile_id) is None:
        return [], "template"
    snap = build_patient_snapshot(db, profile_id, log_limit=40, adherence_days=14)
    if snap is None:
        return [
            "Hôm nay tôi cần uống thuốc gì?",
            "Cách ghi nhận liều đã uống?",
        ], "template"
    chunks = snapshot_to_markdown_chunks(snap, redact_uuids=True)
    context = format_chunks_for_llm(chunks, max_total_chars=6000)
    llm_q = await llm_suggested_questions(context)
    if llm_q:
        return llm_q, "llm"
    return template_suggested_questions_from_snapshot(snap), "template"
