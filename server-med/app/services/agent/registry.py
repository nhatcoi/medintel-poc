"""Đăng ký tool agent MedIntel — một nguồn duy nhất cho whitelist và tài liệu."""

from __future__ import annotations

from typing import Final

ALLOWED_TOOLS: Final[frozenset[str]] = frozenset(
    {
        "log_dose",
        "upsert_medication",
        "append_care_note",
        "save_reminder_intent",
        "update_patient_memory",
    }
)

# Tool do server xử lý (không trả về client)
SERVER_SIDE_TOOLS: Final[frozenset[str]] = frozenset({"update_patient_memory"})

# Mô tả ngắn cho OpenAPI / tài liệu nội bộ
TOOL_DESCRIPTIONS: dict[str, str] = {
    "log_dose": "Ghi nhận một liều (taken/missed/skipped); app hoặc server sync lưu log.",
    "upsert_medication": "Thêm/cập nhật một dòng thuốc trong danh sách (lưu database / đồng bộ).",
    "append_care_note": "Ghi chú nhanh vào nhật ký chăm sóc.",
    "save_reminder_intent": "Lưu ý định nhắc (nháp); báo thức thật do app xử lý.",
    "update_patient_memory": (
        "Ghi nhớ dài hạn về bệnh nhân (server-side). "
        "args: key (canonical_key), value (any), confidence (0-1, mặc định 0.9)."
    ),
}
