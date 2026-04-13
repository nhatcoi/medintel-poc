"""Gợi ý dòng chào chat — gom dữ liệu bệnh nhân (DB) + LLM hoặc template."""

from __future__ import annotations

import json
import logging
import uuid
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta, timezone
from typing import Any, Literal

import httpx
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.llm_openai_compat import apply_max_output_tokens
from app.models.audit_log import AuditLog
from app.models.treatment_medication import MedicationLog
from app.repositories.medication_repository import list_medications_for_profile
from app.repositories.profile_repository import get_by_id
from app.services.memory.long_term import get_all_memory
from app.services.patient_context_chunks import format_chunks_for_llm, snapshot_to_markdown_chunks
from app.services.patient_snapshot_service import build_patient_snapshot

_log = logging.getLogger("medintel.welcome_hints")

SourceKind = Literal["llm", "template"]

# Prompt gửi API OpenAI-compatible (welcome-hints).
WELCOME_HINTS_SYSTEM = """Bạn sinh 6–8 câu gợi ý cực ngắn (tiếng Việt) cho ông chat ứng dụng theo dõi thuốc MedIntel.
Chỉ trả về MỘT object JSON, không markdown, không văn bản ngoài JSON:
{"hints":["câu 1","câu 2",...]}

Quy tắc:
- Mỗi câu ≤ 120 ký tự, thân thiện, có thể hỏi hoặc gợi ý hành động.
- Bám vào dữ liệu bệnh nhân (tên thuốc, giờ uống, số thuốc, log hôm nay, dị ứng/bệnh nền nếu có).
- Nếu chưa có thuốc trên server: gợi ý quét đơn, thêm thuốc, hỏi khỏe.
- Không hiển thị UUID, medication_id, hay kỹ thuật nội bộ.
- Không được thêm chữ trước/sau JSON."""

_RAW_ASSISTANT_MAX = 120_000


def welcome_hints_openai_messages(patient_facts: str) -> list[dict[str, str]]:
    """messages[] đúng như gửi lên LLM (để audit / tra cứu DB)."""
    return [
        {"role": "system", "content": WELCOME_HINTS_SYSTEM},
        {
            "role": "user",
            "content": (
                "Dữ liệu bệnh nhân (snapshot server đã chunk theo mục ##; không có UUID):\n"
                f"{patient_facts}"
            ),
        },
    ]


def build_patient_context_markdown_for_welcome(db: Session, profile_id: uuid.UUID) -> str:
    """Ưu tiên snapshot đầy đủ + chunking; fallback markdown cũ nếu không load được snapshot."""
    snap = build_patient_snapshot(db, profile_id, log_limit=50, adherence_days=14)
    if snap is None:
        return collect_patient_facts_markdown(db, profile_id)
    chunks = snapshot_to_markdown_chunks(snap, redact_uuids=True)
    return format_chunks_for_llm(chunks, max_total_chars=7200)


@dataclass
class LlmHintsOutcome:
    """Kết quả một lần gọi LLM sinh welcome-hints (kèm dữ liệu ghi audit)."""

    hints: list[str] | None
    llm_called: bool = False
    http_status: int | None = None
    raw_assistant_content: str | None = None
    error: str | None = None


def _fmt_schedule_times(scheduled_times: list[time]) -> str:
    if not scheduled_times:
        return "—"
    ordered = sorted(scheduled_times, key=lambda t: (t.hour, t.minute))
    return ", ".join(f"{t.hour:02d}:{t.minute:02d}" for t in ordered)


def _count_logs_today(db: Session, profile_id: uuid.UUID) -> int:
    today = date.today()
    start = datetime.combine(today, datetime.min.time()).replace(tzinfo=timezone.utc)
    end = start + timedelta(days=1)
    n = db.scalar(
        select(func.count())
        .select_from(MedicationLog)
        .where(
            MedicationLog.profile_id == profile_id,
            MedicationLog.scheduled_datetime >= start,
            MedicationLog.scheduled_datetime < end,
        )
    )
    return int(n or 0)


def collect_patient_facts_markdown(db: Session, profile_id: uuid.UUID) -> str:
    """Dữ liệu thật từ DB — đưa vào prompt LLM (không UUID trong câu gợi ý)."""
    lines: list[str] = []
    prof = get_by_id(db, profile_id)
    if prof:
        lines.append(f"Hồ sơ: tên hiển thị: {(prof.full_name or '').strip() or 'chưa có tên'}")

    meds = list_medications_for_profile(db, profile_id)
    if not meds:
        lines.append("Thuốc trên server: chưa có bản ghi trong database (chưa đồng bộ từ app).")
    else:
        lines.append(f"Số thuốc trên server: {len(meds)}")
        for m in meds[:12]:
            t_str = _fmt_schedule_times(m.schedule_times)
            dose = (m.dosage or "").strip() or "—"
            lines.append(f"- {m.name} | liều: {dose} | giờ nhắc: {t_str}")

    mem = get_all_memory(db, profile_id)
    for key in ("allergies", "chronic_conditions", "current_medications"):
        if key in mem and mem[key]:
            val = mem[key]
            snippet = json.dumps(val, ensure_ascii=False) if not isinstance(val, str) else val
            lines.append(f"Bộ nhớ {key}: {snippet[:240]}")

    log_n = _count_logs_today(db, profile_id)
    lines.append(f"Số log liều đã ghi trong ngày (theo lịch server): {log_n}")

    return "\n".join(lines)


def _parse_hints_payload(content: str) -> list[str] | None:
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
        hints = data.get("hints")
        if not isinstance(hints, list):
            continue
        out = [str(x).strip() for x in hints if str(x).strip()]
        return out[:12] if out else None
    return None


async def llm_generate_hints(patient_facts: str) -> LlmHintsOutcome:
    messages = welcome_hints_openai_messages(patient_facts)
    if not (settings.llm_api_key or "").strip():
        return LlmHintsOutcome(hints=None, llm_called=False)

    payload: dict[str, Any] = {
        "model": settings.llm_model,
        "stream": False,
        "messages": messages,
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
            _log.warning("welcome_hints LLM HTTP %s", resp.status_code)
            raw_err = (resp.text or "")[:_RAW_ASSISTANT_MAX]
            return LlmHintsOutcome(
                hints=None,
                llm_called=True,
                http_status=resp.status_code,
                raw_assistant_content=raw_err or None,
            )
        body = resp.json()
        choices = body.get("choices") or []
        if not choices:
            return LlmHintsOutcome(
                hints=None,
                llm_called=True,
                http_status=resp.status_code,
                raw_assistant_content=json.dumps(body, ensure_ascii=False)[:_RAW_ASSISTANT_MAX],
            )
        text = (choices[0].get("message") or {}).get("content") or ""
        raw = (text or "")[:_RAW_ASSISTANT_MAX]
        parsed = _parse_hints_payload(text)
        return LlmHintsOutcome(
            hints=parsed,
            llm_called=True,
            http_status=resp.status_code,
            raw_assistant_content=raw or None,
        )
    except Exception as exc:  # noqa: BLE001
        _log.warning("welcome_hints LLM error: %s", exc)
        return LlmHintsOutcome(hints=None, llm_called=True, error=str(exc))


def _persist_welcome_hints_audit(
    db: Session,
    profile_id: uuid.UUID,
    *,
    patient_facts: str,
    source_final: SourceKind,
    final_hints: list[str],
    openai_messages: list[dict[str, str]],
    llm_outcome: LlmHintsOutcome | None,
) -> None:
    """Ghi audit_logs: prompt gửi Gen AI + raw trả lời + gợi ý trả về client."""
    new_value: dict[str, Any] = {
        "purpose": "welcome_hints",
        "source_final": source_final,
        "model_requested": settings.llm_model,
        "llm_base_url": settings.llm_base_url,
        "patient_facts_markdown": patient_facts,
        "openai_compatible_messages": openai_messages,
        "final_hints_returned": final_hints,
    }
    if llm_outcome is not None:
        new_value["llm_called"] = llm_outcome.llm_called
        new_value["llm_http_status"] = llm_outcome.http_status
        new_value["raw_assistant_content"] = llm_outcome.raw_assistant_content
        new_value["parsed_hints_from_llm"] = llm_outcome.hints
        new_value["llm_error"] = llm_outcome.error
    try:
        db.add(
            AuditLog(
                actor_profile_id=profile_id,
                action_type="gen_ai_welcome_hints",
                new_value=new_value,
            )
        )
        db.commit()
    except Exception as exc:  # noqa: BLE001
        db.rollback()
        _log.warning("welcome_hints audit persist failed: %s", exc)


def build_template_hints(db: Session, profile_id: uuid.UUID) -> list[str]:
    """Khi không gọi LLM hoặc LLM lỗi — vẫn cá nhân hóa theo DB."""
    prof = get_by_id(db, profile_id)
    first_name = "Bạn"
    if prof and (prof.full_name or "").strip():
        parts = prof.full_name.strip().split()
        first_name = parts[0]

    meds = list_medications_for_profile(db, profile_id)
    log_n = _count_logs_today(db, profile_id)
    hints: list[str] = [
        f"{first_name}, hôm nay bạn cảm thấy thế nào?",
    ]

    if not meds:
        hints.append("Bạn có muốn quét đơn thuốc để lưu lịch uống trên máy không?")
        hints.append("Hỏi tôi về thuốc hoặc cách ghi nhận liều đã uống nhé.")
        return hints[:8]

    m0 = meds[0]
    times = _fmt_schedule_times(m0.schedule_times)
    tail = f" (nhắc: {times})" if times != "—" else ""
    hints.append(f"Hôm nay bạn đã uống {m0.name} đúng giờ chưa?{tail}")

    if len(meds) > 1:
        hints.append(f"Bạn đang có {len(meds)} loại thuốc — cần ôn lại lịch uống không?")

    hints.append(f"Bạn muốn tôi nhắc cách dùng {m0.name} không?")

    if log_n > 0:
        hints.append(f"Hôm nay đã có {log_n} lần ghi liều trên hệ thống — bạn còn liều nào chưa ghi?")
    else:
        hints.append("Bạn có liều nào vừa uống muốn ghi nhận không?")

    mem = get_all_memory(db, profile_id)
    if mem.get("allergies"):
        hints.append("Bạn có cần nhắc lại dị ứng đang lưu không?")

    return hints[:8]


async def build_welcome_hints(db: Session, profile_id: uuid.UUID) -> tuple[list[str], SourceKind]:
    facts = build_patient_context_markdown_for_welcome(db, profile_id)
    messages = welcome_hints_openai_messages(facts)
    _log.info(
        "welcome_hints profile_id=%s — dữ liệu gom từ DB (markdown gửi LLM/template):\n%s",
        profile_id,
        facts,
    )
    llm_outcome = await llm_generate_hints(facts)
    if llm_outcome.hints:
        _log.info(
            "welcome_hints profile_id=%s source=llm hints_count=%d",
            profile_id,
            len(llm_outcome.hints),
        )
        _persist_welcome_hints_audit(
            db,
            profile_id,
            patient_facts=facts,
            source_final="llm",
            final_hints=llm_outcome.hints,
            openai_messages=messages,
            llm_outcome=llm_outcome,
        )
        return llm_outcome.hints, "llm"
    tmpl = build_template_hints(db, profile_id)
    _log.info(
        "welcome_hints profile_id=%s source=template hints_count=%d",
        profile_id,
        len(tmpl),
    )
    _persist_welcome_hints_audit(
        db,
        profile_id,
        patient_facts=facts,
        source_final="template",
        final_hints=tmpl,
        openai_messages=messages,
        llm_outcome=llm_outcome,
    )
    return tmpl, "template"
