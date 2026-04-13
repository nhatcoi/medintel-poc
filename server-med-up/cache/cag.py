"""CAG (Cache-Augmented Generation): normalize, classify, cache lookup/write."""

from __future__ import annotations

import re
import unicodedata

from sqlalchemy.orm import Session

from core.config import settings
from repositories.cache_repo import get_cached, make_key, set_cached

_PERSONAL_RE = re.compile(r"(tôi|mình|em|của tôi|bệnh nhân|hồ sơ)", re.IGNORECASE)

TTL_BY_INTENT: dict[str, int] = {
    "drug_info_general": 72,
    "side_effect_check": 48,
    "drug_drug_interaction": 48,
    "dose_before_after_meal": 72,
    "storage_instructions": 72,
}


def normalize_query(text: str) -> str:
    t = unicodedata.normalize("NFC", text).lower().strip()
    t = re.sub(r"\s+", " ", t)
    t = re.sub(r"[?.!,]+$", "", t).strip()
    return t[: settings.cag_max_query_len]


def classify_intent_for_cache(text: str) -> str:
    t = text.lower()
    if "tương tác" in t:
        return "drug_drug_interaction"
    if "tác dụng phụ" in t:
        return "side_effect_check"
    if "liều" in t:
        return "dose_general"
    return "generic_qa"


def is_cacheable_request(
    user_text: str,
    profile_id: str | None,
    session_id: str | None,
    include_medication_context: bool,
) -> bool:
    if not settings.cag_enabled:
        return False
    if profile_id or session_id or include_medication_context:
        return False
    if len(user_text.strip()) < 6:
        return False
    if _PERSONAL_RE.search(user_text):
        return False
    return True


def is_cacheable_response(tool_calls: list[dict], reply: str) -> bool:
    if tool_calls:
        return False
    if not reply or len(reply.strip()) < 10:
        return False
    return True


def try_cache_lookup(db: Session, text: str) -> dict | None:
    normalized = normalize_query(text)
    intent = classify_intent_for_cache(normalized)
    key = make_key(normalized, intent, settings.kb_version)
    row = get_cached(db, key)
    if row is None:
        return None
    return {
        "reply": row.reply,
        "tool_calls": row.tool_calls or [],
        "suggested_actions": row.suggested_actions or [],
        "cache_key": key,
        "intent": intent,
    }


def write_cache(
    db: Session,
    text: str,
    reply: str,
    tool_calls: list[dict] | None = None,
    suggested_actions: list[dict] | None = None,
) -> None:
    normalized = normalize_query(text)
    intent = classify_intent_for_cache(normalized)
    key = make_key(normalized, intent, settings.kb_version)
    ttl = TTL_BY_INTENT.get(intent, settings.cag_default_ttl_hours)
    set_cached(
        db,
        cache_key=key,
        query_text=text,
        intent=intent,
        reply=reply,
        tool_calls=tool_calls,
        suggested_actions=suggested_actions,
        ttl_hours=ttl,
    )
