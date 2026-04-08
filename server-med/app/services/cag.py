"""Cache-Augmented Generation — cache câu trả lời generic trong PostgreSQL.

Quy tắc an toàn:
- CHỈ cache câu hỏi generic, KHÔNG cá nhân hóa (không session history, không profile).
- KHÔNG cache response có write tool_calls (log_dose, upsert_medication, …).
- Key = sha256(normalized_query + kb_version) — invalidate bằng cách bump kb_version.
"""

from __future__ import annotations

import hashlib
import re
import unicodedata
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.response_cache import ResponseCache

# Intent → TTL (giờ). Default: cag_default_ttl_hours.
TTL_BY_INTENT: dict[str, int] = {
    "drug_info": 72,       # thông tin thuốc ít đổi
    "dose_general": 24,    # liều chung (không cá nhân)
    "interaction": 24,
    "side_effect": 24,
    "generic_qa": 12,
}

# Nếu user text khớp regex này → coi là cá nhân hóa, KHÔNG cache.
_PERSONAL_MARKERS = re.compile(
    r"\b(tôi|mình|của tôi|của mình|vừa uống|đã uống|nhớ giúp|nhắc tôi|nhắc mình|bỏ liều|thêm thuốc|ghi chú)\b",
    flags=re.IGNORECASE,
)


@dataclass
class CachedResponse:
    reply: str
    tool_calls: list[dict[str, Any]]
    suggested_actions: list[dict[str, Any]]
    intent: str | None
    hit_count: int


def normalize_query(text: str) -> str:
    """Chuẩn hóa: strip, lowercase, gộp whitespace, bỏ dấu câu cuối câu."""
    t = unicodedata.normalize("NFC", text or "").strip().lower()
    t = re.sub(r"\s+", " ", t)
    t = re.sub(r"[?.!,…]+$", "", t)
    return t[: settings.cag_max_query_len]


def classify_intent(text: str) -> str:
    """Heuristic đơn giản — đủ cho cache key, không cần ML."""
    t = (text or "").lower()
    if any(k in t for k in ("tương tác", "uống cùng", "chung với", "kết hợp")):
        return "interaction"
    if any(k in t for k in ("tác dụng phụ", "side effect", "phản ứng phụ")):
        return "side_effect"
    if any(k in t for k in ("liều", "mg", "uống bao nhiêu", "mấy viên")):
        return "dose_general"
    if any(k in t for k in ("thuốc", "công dụng", "chỉ định", "là gì", "dùng để")):
        return "drug_info"
    return "generic_qa"


def make_cache_key(normalized: str, intent: str, kb_version: int) -> str:
    raw = f"{kb_version}|{intent}|{normalized}"
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()[:48]


def is_cacheable_request(
    *,
    user_text: str,
    profile_id: Any,
    session_id: Any,
    include_medication_context: bool,
) -> bool:
    """Chỉ cache request generic, không cá nhân hóa."""
    if not settings.cag_enabled:
        return False
    if profile_id is not None or session_id is not None:
        return False
    if include_medication_context:
        return False
    if _PERSONAL_MARKERS.search(user_text or ""):
        return False
    if len(user_text.strip()) < 6:
        return False
    return True


def is_cacheable_response(
    *, tool_calls: list[dict[str, Any]], reply: str
) -> bool:
    """Không cache nếu có write tool hoặc reply rỗng/lỗi."""
    if not reply or not reply.strip():
        return False
    if tool_calls:
        # Có bất kỳ tool_call nào → có thể là hành động ghi, không cache
        return False
    return True


# ---------- CRUD ----------

def get_cached(db: Session, cache_key: str) -> CachedResponse | None:
    now = datetime.now(timezone.utc)
    row = db.execute(
        select(ResponseCache).where(ResponseCache.cache_key == cache_key)
    ).scalar_one_or_none()
    if row is None:
        return None
    if row.expires_at <= now:
        # Hết hạn — xóa lười
        db.delete(row)
        db.commit()
        return None
    if row.kb_version != settings.kb_version:
        # KB đã bump → invalidate
        db.delete(row)
        db.commit()
        return None
    row.hit_count += 1
    db.commit()
    return CachedResponse(
        reply=row.reply,
        tool_calls=row.tool_calls or [],
        suggested_actions=row.suggested_actions or [],
        intent=row.intent,
        hit_count=row.hit_count,
    )


def set_cached(
    db: Session,
    *,
    cache_key: str,
    query_text: str,
    intent: str,
    reply: str,
    tool_calls: list[dict[str, Any]],
    suggested_actions: list[dict[str, Any]],
) -> None:
    ttl_hours = TTL_BY_INTENT.get(intent, settings.cag_default_ttl_hours)
    expires_at = datetime.now(timezone.utc) + timedelta(hours=ttl_hours)

    row = db.execute(
        select(ResponseCache).where(ResponseCache.cache_key == cache_key)
    ).scalar_one_or_none()
    if row is None:
        row = ResponseCache(
            cache_key=cache_key,
            query_text=query_text,
            intent=intent,
            kb_version=settings.kb_version,
            reply=reply,
            tool_calls=tool_calls or None,
            suggested_actions=suggested_actions or None,
            expires_at=expires_at,
        )
        db.add(row)
    else:
        row.query_text = query_text
        row.intent = intent
        row.kb_version = settings.kb_version
        row.reply = reply
        row.tool_calls = tool_calls or None
        row.suggested_actions = suggested_actions or None
        row.expires_at = expires_at
    db.commit()


def invalidate_all(db: Session) -> int:
    """Xóa toàn bộ cache — dùng khi bump KB thủ công."""
    result = db.execute(delete(ResponseCache))
    db.commit()
    return result.rowcount or 0


def invalidate_stale(db: Session) -> int:
    """Xóa row hết hạn HOẶC khác kb_version hiện tại."""
    now = datetime.now(timezone.utc)
    result = db.execute(
        delete(ResponseCache).where(
            (ResponseCache.expires_at <= now)
            | (ResponseCache.kb_version != settings.kb_version)
        )
    )
    db.commit()
    return result.rowcount or 0
