"""Action templates dùng chung + helper tạo template.

Placeholder hỗ trợ: {drug}, {next_drug}, {entity_drug}, {profile_name}.
Route phải trùng `client-med/lib/app/router.dart`:
    /home /cabinet /ai /history /care /scan /reminder /medical-records /memory /settings
"""

from __future__ import annotations

P, T, N, E = "prompt", "tool", "navigate", "escalate"


def action(label: str, category: str, **kw) -> dict:
    return {
        "label": label,
        "category": category,
        "type": kw.pop("type", P),
        "priority": kw.pop("priority", 50),
        **kw,
    }


# -- App-level shortcuts (reusable) --

def add_to_cabinet() -> dict:
    return action(
        "Thêm {entity_drug} vào tủ thuốc",
        "cabinet",
        type=T,
        tool="upsert_medication",
        tool_args={"name": "{entity_drug}"},
        requires=["entity_drug_not_in_cabinet"],
        priority=82,
    )


def scan_prescription() -> dict:
    return action("Quét đơn thuốc (OCR)", "scan", type=N, route="/scan", priority=55)


def view_cabinet() -> dict:
    return action("Xem tủ thuốc", "cabinet", type=N, route="/cabinet", priority=55)


def setup_reminder() -> dict:
    return action(
        "Lập lịch uống {drug}", "reminder", type=N, route="/reminder",
        requires=["has_meds"], priority=78,
    )


def save_to_records() -> dict:
    return action("Lưu vào hồ sơ y tế", "records", type=N, route="/medical-records", priority=55)


def write_care_note() -> dict:
    return action(
        "Ghi ghi chú gửi bác sĩ", "care",
        type=T, tool="append_care_note", priority=65,
    )


def search_kb() -> dict:
    return action(
        "Tra cứu trong kho thuốc", "info",
        type=T, tool="search_drug_kb", tool_args={"query": "{entity_drug}"},
        requires=["has_entity_drug"], priority=82,
    )


def call_115() -> dict:
    return action("GỌI 115 NGAY", "emergency", type=E, priority=100)


def contact_doctor() -> dict:
    return action("Liên hệ bác sĩ", "emergency", type=E, priority=90)
