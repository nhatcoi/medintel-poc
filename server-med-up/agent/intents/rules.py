"""Rule-based intent classifier (regex + keyword). Fast, no LLM cost."""

from __future__ import annotations

import re

from agent.intents.definitions import Intent

_GREETING_RE = re.compile(
    r"^(hi|hello|hey|chào|xin\s*chào|hế\s*lô|alo+|good\s*(morning|afternoon|evening))[\s!?.]*$",
    re.IGNORECASE,
)

_SMALL_TALK_RE = re.compile(
    r"^(ok+|ừ+|dạ|vâng(\s+ạ)?|bye|tạm\s*biệt)[\s!?.]*$",
    re.IGNORECASE,
)

_KEYWORD_RULES: list[tuple[re.Pattern, Intent]] = [
    (re.compile(r"xem\s*(t[uủ]|tu)\s*thuốc|mở\s*tủ\s*thuốc|vao\s*tu\s*thuoc", re.I), Intent.SMALL_TALK),
    (
        re.compile(
            r"(?:^|\b)(?:tôi|toi|em|con|cháu|chau)?\s*(?:đã|da)\s*uống\s+\S+|uống\s+rồi|vừa\s*uống",
            re.I,
        ),
        Intent.TREATMENT_TRACKING,
    ),
    (re.compile(r"quên\s*(uống|liều)", re.I), Intent.MISSED_DOSE_GUIDANCE),
    (re.compile(r"bỏ\s*(liều|thuốc)", re.I), Intent.SKIP_DOSE_GUIDANCE),
    (re.compile(r"tác\s*dụng\s*phụ", re.I), Intent.SIDE_EFFECT_CHECK),
    (re.compile(r"tương\s*tác\s*(thuốc|với)", re.I), Intent.DRUG_DRUG_INTERACTION),
    (re.compile(r"(trước|sau)\s*ăn", re.I), Intent.DOSE_BEFORE_AFTER_MEAL),
    (re.compile(r"giờ\s*uống|lịch\s*uống|uống\s*khi\s*nào", re.I), Intent.CHECK_MED_SCHEDULE),
    (re.compile(r"liều\s*lượng|uống\s*bao\s*nhiêu", re.I), Intent.CHECK_DOSE_AMOUNT),
    (re.compile(r"quá\s*liều", re.I), Intent.OVERDOSE_GUIDANCE),
    (re.compile(r"cấp\s*cứu|khẩn\s*cấp", re.I), Intent.EMERGENCY_SYMPTOM),
    (re.compile(r"dị\s*ứng", re.I), Intent.ALLERGIC_REACTION_GUIDANCE),
    (re.compile(r"bảo\s*quản|cất\s*giữ", re.I), Intent.STORAGE_INSTRUCTIONS),
    (re.compile(r"hạn\s*sử\s*dụng|hết\s*hạn", re.I), Intent.EXPIRY_CHECK),
    (re.compile(r"(đổi|thay)\s*giờ\s*(uống|nhắc)", re.I), Intent.DOSE_TIME_CHANGE),
    (re.compile(r"nhắc\s*(nhở|lịch)|đặt\s*nhắc", re.I), Intent.TREATMENT_REMINDER_SETUP),
    (re.compile(r"tuân\s*thủ|adherence|compliance", re.I), Intent.TREATMENT_TRACKING),
    (re.compile(r"thuốc\s*.+\s*(là\s*gì|dùng\s*để)", re.I), Intent.DRUG_INFO_GENERAL),
    (re.compile(r"thành\s*phần", re.I), Intent.DRUG_COMPOSITION),
    (re.compile(r"mang\s*thai|cho\s*con\s*bú", re.I), Intent.PREGNANCY_LACTATION_SAFE),
    (re.compile(r"trẻ\s*em|nhi", re.I), Intent.PEDIATRIC_USE),
    (re.compile(r"người\s*già|cao\s*tuổi", re.I), Intent.ELDERLY_USE),
    (re.compile(r"ngừng\s*thuốc|dừng\s*thuốc", re.I), Intent.CAN_STOP_EARLY),
    (re.compile(r"liên\s*hệ\s*(bác\s*sĩ|bs|doctor)", re.I), Intent.CONTACT_DOCTOR),
    (re.compile(r"rượu|bia|alcohol", re.I), Intent.DRUG_ALCOHOL_INTERACTION),
]


def classify_by_rules(text: str) -> tuple[Intent, float] | None:
    """Returns (intent, confidence) or None if no rule matches."""
    text = (text or "").strip()
    if not text:
        return None

    if len(text) <= 48:
        if _GREETING_RE.match(text):
            return Intent.GREETING, 0.95
        if _SMALL_TALK_RE.match(text):
            return Intent.SMALL_TALK, 0.95

    for pattern, intent in _KEYWORD_RULES:
        if pattern.search(text):
            return intent, 0.80

    return None
