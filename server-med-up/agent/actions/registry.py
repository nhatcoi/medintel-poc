"""Intent -> action templates (trim, ≤3 action/intent).

Quy ước: mỗi intent chỉ giữ 2-3 action cốt lõi — 1 primary (type=tool/navigate),
1-2 support (prompt/info). Trước khi thêm, hãy tự hỏi: *có thật sự khác intent khác?*

Các action dùng chung (scan/cabinet/records…) nằm ở `templates.py`.
"""

from __future__ import annotations

from agent.actions.templates import (
    action as A,
    add_to_cabinet,
    call_115,
    contact_doctor,
    save_to_records,
    scan_prescription,
    search_kb,
    setup_reminder,
    view_cabinet,
    write_care_note,
    T, N, E,
)
from agent.intents.definitions import Intent


# Common log_dose tool-call action
def _log_dose(status: str, label: str, priority: int, note: str = "") -> dict:
    args: dict = {"medication_name": "{drug}", "status": status}
    if note:
        args["note"] = note
    return A(label, "log_dose", type=T, tool="log_dose", tool_args=args,
             requires=["has_meds"], priority=priority)


# ---------------------------------------------------------------------------
# SCHEDULE & DOSAGE (10)
# ---------------------------------------------------------------------------
_SCHEDULE = {
    Intent.CHECK_MED_SCHEDULE.value: [
        _log_dose("taken", "Đã uống {drug}", 85),
        A("Xem lịch hôm nay", "schedule", type=N, route="/home", priority=80),
        A("Nhắc tôi liều kế tiếp", "adherence",
          prompt="Liều kế tiếp của tôi là khi nào?", priority=65),
    ],
    Intent.CHECK_DOSE_AMOUNT.value: [
        A("Uống trước hay sau ăn?", "info",
          prompt="{drug} nên uống trước hay sau ăn?",
          requires=["has_meds"], priority=65),
        view_cabinet(),
    ],
    Intent.MISSED_DOSE_GUIDANCE.value: [
        _log_dose("taken", "Ghi nhận đã uống bù {drug}", 95, note="uống bù"),
        _log_dose("missed", "Ghi nhận bỏ liều này", 85),
        A("Đặt nhắc sau 30 phút", "reminder", type=T,
          tool="save_reminder_intent", tool_args={"offset_minutes": 30}, priority=70),
    ],
    Intent.SKIP_DOSE_GUIDANCE.value: [
        A("Bỏ 1 liều có ảnh hưởng gì?", "safety",
          prompt="Bỏ 1 liều {drug} có ảnh hưởng gì không?",
          requires=["has_meds"], priority=78),
        _log_dose("skipped", "Ghi nhận bỏ liều", 70),
    ],
    Intent.ADJUST_DOSE.value: [
        contact_doctor(),
        write_care_note(),
    ],
    Intent.DOSE_FREQUENCY.value: [
        A("Hôm nay uống mấy lần?", "schedule",
          prompt="Hôm nay tôi uống {drug} mấy lần?",
          requires=["has_meds"], priority=70),
        view_cabinet(),
    ],
    Intent.DOSE_TIME_CHANGE.value: [
        A("Cập nhật giờ nhắc", "reminder", type=N, route="/reminder", priority=85),
        setup_reminder(),
    ],
    Intent.DOSE_BEFORE_AFTER_MEAL.value: [
        search_kb(),
        A("Tương tác với thức ăn?", "info",
          prompt="{drug} có tương tác với thức ăn nào không?",
          requires=["has_meds"], priority=65),
    ],
    Intent.DOSE_WITH_WATER_FOOD.value: [
        A("Xem cách dùng chi tiết", "info",
          prompt="Hướng dẫn dùng {drug} chi tiết",
          requires=["has_meds"], priority=60),
    ],
    Intent.DOSE_FORM_INSTRUCTIONS.value: [
        A("Xem thành phần thuốc", "info",
          prompt="{drug} có thành phần gì?",
          requires=["has_meds"], priority=55),
    ],
}


# ---------------------------------------------------------------------------
# SIDE EFFECTS (8)
# ---------------------------------------------------------------------------
_SIDE_EFFECTS = {
    Intent.SIDE_EFFECT_CHECK.value: [
        A("Đánh giá mức độ nghiêm trọng", "triage",
          prompt="Triệu chứng của tôi ở mức nào?", priority=80),
        write_care_note(),
    ],
    Intent.SERIOUS_SIDE_EFFECT_ALERT.value: [
        call_115(),
        contact_doctor(),
        write_care_note(),
    ],
    Intent.MILD_SIDE_EFFECT_INFO.value: [
        write_care_note(),
        A("Khi nào cần đi khám?", "safety",
          prompt="Trường hợp nào cần đi khám ngay?", priority=75),
    ],
    Intent.SIDE_EFFECT_DURATION.value: [write_care_note()],
    Intent.SIDE_EFFECT_MANAGEMENT.value: [
        write_care_note(),
        A("Xem tương tác thuốc", "info",
          prompt="{drug} có tương tác khiến tác dụng phụ nặng hơn?",
          requires=["has_meds"], priority=60),
    ],
    Intent.UNEXPECTED_SYMPTOM_CHECK.value: [
        A("Triệu chứng do thuốc?", "triage",
          prompt="Triệu chứng này có thể do thuốc tôi đang dùng không?",
          requires=["has_meds"], priority=85),
        write_care_note(),
    ],
    Intent.ALLERGIC_REACTION_GUIDANCE.value: [
        call_115(),
        A("Ngưng thuốc & liên hệ bác sĩ", "emergency", type=E, priority=95),
    ],
    Intent.REPORT_SIDE_EFFECT.value: [
        write_care_note(),
        contact_doctor(),
    ],
}


# ---------------------------------------------------------------------------
# INTERACTIONS (6)
# ---------------------------------------------------------------------------
_INTERACTIONS = {
    Intent.DRUG_DRUG_INTERACTION.value: [
        A("Kiểm tra tương tác {drug} & {next_drug}", "interaction", type=T,
          tool="check_drug_interaction",
          tool_args={"drug_a": "{drug}", "drug_b": "{next_drug}"},
          requires=["has_two_meds"], priority=95),
        add_to_cabinet(),
        contact_doctor(),
    ],
    Intent.DRUG_FOOD_INTERACTION.value: [
        A("Thực phẩm cần tránh", "info",
          prompt="{drug} cần tránh thực phẩm nào?",
          requires=["has_meds"], priority=75),
    ],
    Intent.DRUG_ALCOHOL_INTERACTION.value: [
        A("Rủi ro với rượu bia", "safety",
          prompt="Uống rượu khi dùng {drug} nguy hiểm đến đâu?",
          requires=["has_meds"], priority=80),
    ],
    Intent.DRUG_SUPPLEMENT_INTERACTION.value: [
        A("Kiểm tra vitamin/TPCN", "interaction",
          prompt="Vitamin tôi đang dùng có tương tác với {drug}?",
          requires=["has_meds"], priority=70),
    ],
    Intent.CONTRAINDICATION_CHECK.value: [contact_doctor(), save_to_records()],
    Intent.PREGNANCY_LACTATION_SAFE.value: [
        A("Hỏi bác sĩ sản khoa", "safety", type=E, priority=90),
        A("Phân loại an toàn thai kỳ?", "info",
          prompt="{drug} thuộc nhóm an toàn nào cho thai kỳ?",
          requires=["has_meds"], priority=70),
    ],
}


# ---------------------------------------------------------------------------
# ADHERENCE (6)
# ---------------------------------------------------------------------------
_ADHERENCE = {
    Intent.TREATMENT_EFFECTIVENESS.value: [
        A("Xem tiến độ 7 ngày", "adherence", type=N, route="/history", priority=80),
    ],
    Intent.TREATMENT_DURATION.value: [save_to_records(), view_cabinet()],
    Intent.CAN_STOP_EARLY.value: [
        A("KHÔNG tự ngưng - hỏi bác sĩ", "safety", type=E, priority=95),
        A("Rủi ro ngưng sớm", "info",
          prompt="Ngưng {drug} sớm có rủi ro gì?",
          requires=["has_meds"], priority=75),
    ],
    Intent.TREATMENT_REMINDER_SETUP.value: [
        A("Mở màn hình nhắc nhở", "reminder", type=N, route="/reminder", priority=90),
        A("Đặt nhắc sau 30 phút", "reminder", type=T,
          tool="save_reminder_intent", tool_args={"offset_minutes": 30}, priority=75),
    ],
    Intent.TREATMENT_TRACKING.value: [
        A("Xem lịch sử tuân thủ", "adherence", type=N, route="/history", priority=85),
        A("Mẹo tuân thủ", "tips",
          prompt="Cho tôi vài mẹo tuân thủ điều trị", priority=60),
    ],
    Intent.TREATMENT_COMPLIANCE_TIPS.value: [
        A("Đặt nhắc tự động", "reminder", type=N, route="/reminder", priority=80),
    ],
}


# ---------------------------------------------------------------------------
# STORAGE (4)
# ---------------------------------------------------------------------------
_STORAGE = {
    Intent.STORAGE_INSTRUCTIONS.value: [view_cabinet()],
    Intent.EXPIRY_CHECK.value: [
        A("Ghi nhận hết hạn", "report", type=T,
          tool="append_care_note", priority=75),
        view_cabinet(),
    ],
    Intent.TEMPERATURE_REQUIREMENT.value: [
        A("Yêu cầu độ ẩm/ánh sáng?", "info",
          prompt="{drug} có cần tránh ẩm, ánh sáng không?",
          requires=["has_meds"], priority=60),
    ],
    Intent.HUMIDITY_LIGHT_SENSITIVITY.value: [
        A("Nhiệt độ bảo quản?", "info",
          prompt="{drug} bảo quản ở nhiệt độ nào?",
          requires=["has_meds"], priority=60),
    ],
}


# ---------------------------------------------------------------------------
# DRUG & DISEASE INFO (8)
# ---------------------------------------------------------------------------
_INFO = {
    Intent.DRUG_INFO_GENERAL.value: [
        search_kb(),
        add_to_cabinet(),
        setup_reminder(),
    ],
    Intent.DRUG_COMPOSITION.value: [search_kb(), add_to_cabinet()],
    Intent.DRUG_BRAND_GENERIC.value: [search_kb(), add_to_cabinet()],
    Intent.DISEASE_INFO_GENERAL.value: [
        A("Triệu chứng thường gặp", "info",
          prompt="Triệu chứng của bệnh này?", priority=70),
        save_to_records(),
    ],
    Intent.DISEASE_SYMPTOMS_CHECK.value: [
        A("Khi nào cần đi khám?", "safety",
          prompt="Triệu chứng nào cần đi khám ngay?", priority=80),
        write_care_note(),
    ],
    Intent.DISEASE_RISK_FACTORS.value: [
        A("Cách phòng ngừa", "info",
          prompt="Làm sao phòng ngừa?", priority=70),
    ],
    Intent.DISEASE_PREVENTION.value: [
        A("Lựa chọn điều trị", "info",
          prompt="Các lựa chọn điều trị là gì?", priority=65),
    ],
    Intent.TREATMENT_OPTIONS.value: [
        A("So sánh hiệu quả", "info",
          prompt="So sánh hiệu quả các phương án điều trị", priority=70),
        save_to_records(),
    ],
}


# ---------------------------------------------------------------------------
# SPECIAL POPULATIONS (4)
# ---------------------------------------------------------------------------
_SPECIAL = {
    Intent.PEDIATRIC_USE.value: [
        A("Hỏi bác sĩ nhi", "safety", type=E, priority=90),
        A("Liều theo cân nặng", "info",
          prompt="Liều {drug} cho trẻ theo cân nặng?",
          requires=["has_meds"], priority=70),
    ],
    Intent.ELDERLY_USE.value: [
        A("Chống chỉ định người cao tuổi?", "safety",
          prompt="{drug} có chống chỉ định ở người cao tuổi?",
          requires=["has_meds"], priority=75),
    ],
    Intent.PREGNANCY_USE.value: [
        A("Hỏi bác sĩ sản khoa", "safety", type=E, priority=95),
    ],
    Intent.CHRONIC_DISEASE_USE.value: [
        A("Tương tác với thuốc mãn tính", "interaction",
          prompt="{drug} có tương tác với thuốc mãn tính tôi đang dùng?",
          requires=["has_meds"], priority=80),
    ],
}


# ---------------------------------------------------------------------------
# EMERGENCY (4)
# ---------------------------------------------------------------------------
_EMERGENCY = {
    Intent.OVERDOSE_GUIDANCE.value: [
        call_115(),
        A("Trung tâm chống độc", "emergency", type=E, priority=95),
        A("Ghi lại lượng đã uống", "report", type=T,
          tool="append_care_note", priority=85),
    ],
    Intent.EMERGENCY_SYMPTOM.value: [
        call_115(),
        A("Đến cơ sở y tế gần nhất", "emergency", type=E, priority=95),
    ],
    Intent.POISONING_GUIDANCE.value: [
        call_115(),
        A("Trung tâm chống độc", "emergency", type=E, priority=95),
    ],
    Intent.CONTACT_DOCTOR.value: [
        write_care_note(),
        A("Chuẩn bị tóm tắt tình trạng", "report",
          prompt="Tóm tắt tình trạng của tôi để gửi bác sĩ", priority=78),
    ],
}


# ---------------------------------------------------------------------------
# META (3)
# ---------------------------------------------------------------------------
_META = {
    Intent.GREETING.value: [
        A("Hôm nay tôi uống thuốc gì?", "schedule",
          prompt="Hôm nay tôi cần uống những thuốc nào?", priority=80),
        A("Xem tuân thủ tuần qua", "adherence",
          prompt="Tình hình tuân thủ 7 ngày gần đây?", priority=70),
        view_cabinet(),
    ],
    Intent.SMALL_TALK.value: [
        A("Xem thuốc đang dùng", "info",
          prompt="Cho tôi xem danh sách thuốc đang dùng",
          requires=["has_meds"], priority=60),
        view_cabinet(),
    ],
    Intent.UNKNOWN.value: [
        A("Hôm nay uống thuốc gì?", "schedule",
          prompt="Hôm nay tôi uống thuốc gì?", priority=60),
        scan_prescription(),
    ],
}


# ---------------------------------------------------------------------------
# MERGE
# ---------------------------------------------------------------------------
ACTION_MAP: dict[str, list[dict]] = {
    **_SCHEDULE, **_SIDE_EFFECTS, **_INTERACTIONS, **_ADHERENCE,
    **_STORAGE, **_INFO, **_SPECIAL, **_EMERGENCY, **_META,
}


FOLLOW_UP_CHAIN: dict[str, list[str]] = {
    Intent.SIDE_EFFECT_CHECK.value: [Intent.CONTACT_DOCTOR.value],
    Intent.CHECK_MED_SCHEDULE.value: [Intent.TREATMENT_TRACKING.value],
    Intent.MISSED_DOSE_GUIDANCE.value: [Intent.TREATMENT_COMPLIANCE_TIPS.value],
    Intent.DRUG_DRUG_INTERACTION.value: [Intent.CONTACT_DOCTOR.value],
    Intent.DRUG_INFO_GENERAL.value: [Intent.SIDE_EFFECT_CHECK.value],
}


DEFAULT_ACTIONS: list[dict] = [
    A("Tóm tắt ngắn", "summary",
      prompt="Tóm tắt câu trả lời thành 3 ý chính", priority=50),
    view_cabinet(),
]
