"""Chunking dữ liệu snapshot profile → markdown cho LLM (welcome, chat, gợi ý câu hỏi).

Không đưa UUID vào nội dung chunk (an toàn hiển thị / prompt bệnh nhân).
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass

from app.schemas.profile_snapshot import ProfileSnapshotResponse

_UUID_RE = re.compile(
    r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
    re.IGNORECASE,
)


@dataclass(frozen=True, slots=True)
class PatientContextChunk:
    """Một khối ngữ cảnh có tiêu đề — dễ cắt ghép và giới hạn token."""

    chunk_id: str
    title: str
    body: str

    @property
    def char_len(self) -> int:
        return len(self.body)


def _maybe_redact(text: str, redact_uuids: bool) -> str:
    if not redact_uuids or not text:
        return text
    return _UUID_RE.sub("[id]", text)


def _join_lines(lines: list[str], redact: bool) -> str:
    raw = "\n".join(lines).strip()
    return _maybe_redact(raw, redact)


def _profile_chunk(snap: ProfileSnapshotResponse, redact: bool) -> PatientContextChunk:
    p = snap.profile
    lines = [
        f"Tên hiển thị: {p.full_name}",
        f"Vai trò: {p.role}",
    ]
    if p.date_of_birth:
        lines.append(f"Ngày sinh: {p.date_of_birth}")
    if p.phone_number:
        lines.append(f"SĐT: {p.phone_number}")
    if p.emergency_contact:
        lines.append(f"Liên hệ khẩn: {p.emergency_contact}")
    if p.email and "@device.local" not in (p.email or ""):
        lines.append(f"Email: {p.email}")
    if p.last_server_sync_at:
        lines.append(f"Đồng bộ server gần nhất: {p.last_server_sync_at.isoformat()}")
    body = _join_lines(lines, redact)
    return PatientContextChunk("profile", "Hồ sơ", body)


def _devices_chunk(snap: ProfileSnapshotResponse, redact: bool) -> PatientContextChunk | None:
    if not snap.devices:
        return None
    lines: list[str] = []
    for d in snap.devices:
        parts = [d.device_label or "Thiết bị", d.platform or ""]
        line = " — ".join(x for x in parts if x).strip()
        if d.last_seen_at:
            line += f" (last_seen: {d.last_seen_at.isoformat()})"
        lines.append(f"- {line}")
    return PatientContextChunk("devices", "Thiết bị", _join_lines(lines, redact))


def _records_chunk(snap: ProfileSnapshotResponse, redact: bool) -> PatientContextChunk | None:
    if not snap.medical_records:
        return None
    lines: list[str] = []
    for r in snap.medical_records:
        lines.append(
            f"- {r.disease_name} | từ {r.treatment_start_date} | "
            f"{r.treatment_status or '—'} | loại: {r.treatment_type or '—'}"
        )
        if r.notes:
            lines.append(f"  Ghi chú: {(r.notes or '')[:300]}")
    return PatientContextChunk("medical_records", "Bệnh án / điều trị", _join_lines(lines, redact))


def _format_one_medication(m) -> list[str]:
    lines = [
        f"**{m.name}**",
        f"  Liều: {m.dosage or '—'} | Tần suất: {m.frequency or '—'}",
    ]
    if m.instructions:
        lines.append(f"  Hướng dẫn: {m.instructions[:400]}")
    times = ", ".join(s.scheduled_time for s in m.schedule_times) or "—"
    lines.append(f"  Giờ nhắc: {times}")
    if m.remaining_quantity is not None:
        lines.append(f"  Tồn: {m.remaining_quantity} {m.quantity_unit or ''}".strip())
    if m.prescribing_doctor:
        lines.append(f"  BS kê đơn: {m.prescribing_doctor}")
    if m.notes:
        lines.append(f"  Ghi chú: {m.notes[:200]}")
    return lines


def _cabinet_chunks(
    snap: ProfileSnapshotResponse,
    *,
    max_chunk_chars: int,
    max_meds_per_chunk: int,
    redact: bool,
) -> list[PatientContextChunk]:
    if not snap.medication_cabinet:
        return [
            PatientContextChunk(
                "medication_cabinet",
                "Tủ thuốc (server)",
                _maybe_redact("Chưa có thuốc đồng bộ trên server.", redact),
            )
        ]
    out: list[PatientContextChunk] = []
    buf: list[str] = []
    part = 0
    count_in_buf = 0

    def flush() -> None:
        nonlocal buf, part, count_in_buf
        if not buf:
            return
        part += 1
        body = _join_lines(buf, redact)
        out.append(
            PatientContextChunk(
                f"medication_cabinet_{part}",
                f"Tủ thuốc (phần {part})",
                body,
            )
        )
        buf = []
        count_in_buf = 0

    for m in snap.medication_cabinet:
        med_lines = _format_one_medication(m)
        candidate = "\n".join(buf + [""] + med_lines if buf else med_lines)
        if (
            buf
            and (
                len(candidate) > max_chunk_chars or count_in_buf >= max_meds_per_chunk
            )
        ):
            flush()
        buf.extend([""] * bool(buf))
        buf.extend(med_lines)
        count_in_buf += 1
    flush()
    return out


def _logs_chunk(
    snap: ProfileSnapshotResponse,
    *,
    max_lines: int,
    max_chars: int,
    redact: bool,
) -> PatientContextChunk:
    logs = snap.medication_logs_recent[:max_lines]
    if not logs:
        return PatientContextChunk(
            "medication_logs",
            "Nhật ký liều gần đây",
            _maybe_redact("Chưa có log liều trên server.", redact),
        )
    lines: list[str] = []
    for log in logs:
        lines.append(
            f"- {log.medication_name} | {log.status} | "
            f"dự kiến {log.scheduled_datetime.isoformat()}"
            + (
                f" | thực tế {log.actual_datetime.isoformat()}"
                if log.actual_datetime
                else ""
            )
        )
        if log.notes:
            lines.append(f"  ({log.notes[:120]})")
    body = _join_lines(lines, redact)
    if len(body) > max_chars:
        body = body[: max_chars - 20] + "\n…(rút gọn)"
    return PatientContextChunk("medication_logs", "Nhật ký liều gần đây", body)


def _memories_chunk(snap: ProfileSnapshotResponse, redact: bool) -> PatientContextChunk:
    if not snap.memories:
        return PatientContextChunk(
            "memories",
            "Bộ nhớ AI (KV)",
            _maybe_redact("Chưa có mục bộ nhớ dài hạn.", redact),
        )
    lines: list[str] = []
    for mem in snap.memories:
        try:
            val = json.dumps(mem.value, ensure_ascii=False)[:400]
        except (TypeError, ValueError):
            val = str(mem.value)[:400]
        lines.append(f"- {mem.key}: {val}")
    return PatientContextChunk("memories", "Bộ nhớ AI (KV)", _join_lines(lines, redact))


def _adherence_chunk(snap: ProfileSnapshotResponse, redact: bool) -> PatientContextChunk:
    a = snap.adherence_summary
    lines = [
        f"Cửa sổ: {a.days} ngày gần nhất",
        f"Tổng log: {a.total} | taken: {a.taken} | missed: {a.missed} | skipped: {a.skipped} | late: {a.late}",
    ]
    return PatientContextChunk("adherence", "Tuân thủ (tóm tắt)", _join_lines(lines, redact))


def snapshot_to_markdown_chunks(
    snap: ProfileSnapshotResponse,
    *,
    max_cabinet_chunk_chars: int = 2000,
    max_meds_per_cabinet_chunk: int = 2,
    log_lines_cap: int = 40,
    log_max_chars: int = 3500,
    redact_uuids: bool = True,
) -> list[PatientContextChunk]:
    """Chuyển snapshot API thành các chunk markdown có tiêu đề."""
    chunks: list[PatientContextChunk] = [_profile_chunk(snap, redact_uuids)]
    d = _devices_chunk(snap, redact_uuids)
    if d:
        chunks.append(d)
    r = _records_chunk(snap, redact_uuids)
    if r:
        chunks.append(r)
    chunks.extend(
        _cabinet_chunks(
            snap,
            max_chunk_chars=max_cabinet_chunk_chars,
            max_meds_per_chunk=max_meds_per_cabinet_chunk,
            redact=redact_uuids,
        )
    )
    chunks.append(
        _logs_chunk(
            snap, max_lines=log_lines_cap, max_chars=log_max_chars, redact=redact_uuids
        )
    )
    chunks.append(_memories_chunk(snap, redact_uuids))
    chunks.append(_adherence_chunk(snap, redact_uuids))
    return chunks


def format_chunks_for_llm(
    chunks: list[PatientContextChunk],
    *,
    max_total_chars: int = 8000,
) -> str:
    """Nối chunk thành một khối user-context cho prompt; cắt bớt chunk cuối nếu quá dài."""
    parts: list[str] = []
    total = 0
    for c in chunks:
        block = f"## {c.title}\n{c.body}"
        sep = "\n\n" if parts else ""
        if total + len(sep) + len(block) <= max_total_chars:
            parts.append(sep + block)
            total += len(sep) + len(block)
            continue
        room = max_total_chars - total - len(sep) - 30
        if room < 80:
            break
        trimmed = block[:room] + "\n…"
        parts.append(sep + trimmed)
        break
    return "".join(parts).strip()
