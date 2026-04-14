"""Registry: intent -> list of action templates.

Mỗi template được render bởi `action_planner` node. Template có thể tham chiếu:
- `{drug}`         : tên thuốc đầu tiên trong `state.medications`
- `{next_drug}`    : tên thuốc thứ 2 (nếu có)
- `{profile_name}` : tên bệnh nhân (nếu có trong patient_info)

Trường `requires` liệt kê điều kiện (key trong `PlannerFacts`) phải True mới giữ action.
`priority` 0-100, cao hơn = xếp trước. `type`:
    - "prompt"   : gõ prompt lại cho chatbot
    - "tool"     : gọi thẳng tool ở client (client cần xử lý)
    - "navigate" : deep-link sang màn hình khác
    - "escalate" : hành động khẩn cấp (gọi 115, liên hệ bác sĩ)
"""

from __future__ import annotations

from agent.intents.definitions import Intent

# -- Aliases để rút gọn --
P = "prompt"
T = "tool"
N = "navigate"
E = "escalate"


def _t(label: str, category: str, **kwargs) -> dict:
    """Helper tạo template với mặc định type=prompt."""
    return {
        "label": label,
        "category": category,
        "type": kwargs.pop("type", P),
        "priority": kwargs.pop("priority", 50),
        **kwargs,
    }


# ============================================================================
# SCHEDULE & DOSAGE
# ============================================================================
_SCHEDULE: dict[str, list[dict]] = {
    Intent.CHECK_MED_SCHEDULE.value: [
        _t("Xem lịch hôm nay", "schedule", type=N, route="/today", priority=80),
        _t("Nhắc tôi liều kế tiếp", "adherence", prompt="Liều kế tiếp của tôi là khi nào?", priority=70),
        _t("Đã uống {drug}", "log_dose", type=T, tool="log_dose", tool_args={"drug": "{drug}", "status": "taken"}, requires=["has_meds"], priority=75),
    ],
    Intent.CHECK_DOSE_AMOUNT.value: [
        _t("Xem hướng dẫn dạng thuốc", "info", prompt="Dạng thuốc của {drug} dùng thế nào?", requires=["has_meds"], priority=60),
        _t("Uống trước hay sau ăn?", "info", prompt="{drug} nên uống trước hay sau ăn?", requires=["has_meds"], priority=65),
    ],
    Intent.MISSED_DOSE_GUIDANCE.value: [
        _t("Ghi nhận đã uống bù {drug}", "log_dose", type=T, tool="log_dose", tool_args={"drug": "{drug}", "status": "taken_late"}, requires=["has_meds"], priority=90),
        _t("Ghi nhận bỏ liều này", "log_dose", type=T, tool="log_dose", tool_args={"drug": "{drug}", "status": "missed"}, requires=["has_meds"], priority=80),
        _t("Đặt nhắc sau 30 phút", "reminder", type=T, tool="save_reminder_intent", tool_args={"offset_minutes": 30}, priority=70),
        _t("Xem lịch còn lại hôm nay", "schedule", type=N, route="/today", priority=60),
    ],
    Intent.SKIP_DOSE_GUIDANCE.value: [
        _t("Có thể bỏ liều được không?", "safety", prompt="Bỏ 1 liều {drug} có ảnh hưởng gì không?", requires=["has_meds"], priority=75),
        _t("Ghi nhận bỏ liều", "log_dose", type=T, tool="log_dose", tool_args={"drug": "{drug}", "status": "skipped"}, requires=["has_meds"], priority=70),
    ],
    Intent.ADJUST_DOSE.value: [
        _t("Liên hệ bác sĩ trước khi chỉnh liều", "safety", type=E, priority=95),
        _t("Xem chỉ định hiện tại", "info", type=N, route="/treatment", priority=60),
    ],
    Intent.DOSE_FREQUENCY.value: [
        _t("Xem lịch {drug}", "schedule", prompt="Hôm nay tôi uống {drug} mấy lần?", requires=["has_meds"], priority=70),
    ],
    Intent.DOSE_TIME_CHANGE.value: [
        _t("Cập nhật giờ uống", "reminder", type=N, route="/reminders", priority=80),
        _t("Đặt nhắc mới", "reminder", type=T, tool="save_reminder_intent", priority=70),
    ],
    Intent.DOSE_BEFORE_AFTER_MEAL.value: [
        _t("Xem tương tác với thức ăn", "info", prompt="{drug} có tương tác với thức ăn nào không?", requires=["has_meds"], priority=65),
    ],
    Intent.DOSE_WITH_WATER_FOOD.value: [
        _t("Xem cách dùng chi tiết", "info", prompt="Hướng dẫn dùng {drug} chi tiết", requires=["has_meds"], priority=60),
    ],
    Intent.DOSE_FORM_INSTRUCTIONS.value: [
        _t("Xem thành phần thuốc", "info", prompt="{drug} có thành phần gì?", requires=["has_meds"], priority=55),
    ],
}

# ============================================================================
# SIDE EFFECTS & SYMPTOMS
# ============================================================================
_SIDE_EFFECTS: dict[str, list[dict]] = {
    Intent.SIDE_EFFECT_CHECK.value: [
        _t("Đánh giá mức độ nghiêm trọng", "triage", prompt="Triệu chứng của tôi ở mức nào?", priority=80),
        _t("Báo tác dụng phụ cho bác sĩ", "report", type=T, tool="append_care_note", priority=75),
        _t("Cách giảm tác dụng phụ", "info", prompt="Làm sao giảm tác dụng phụ của {drug}?", requires=["has_meds"], priority=70),
    ],
    Intent.SERIOUS_SIDE_EFFECT_ALERT.value: [
        _t("Gọi 115 / cấp cứu", "emergency", type=E, priority=100),
        _t("Liên hệ bác sĩ ngay", "emergency", type=E, priority=95),
        _t("Ghi lại triệu chứng", "report", type=T, tool="append_care_note", priority=80),
    ],
    Intent.MILD_SIDE_EFFECT_INFO.value: [
        _t("Theo dõi triệu chứng", "report", type=T, tool="append_care_note", priority=70),
        _t("Khi nào cần đi khám?", "safety", prompt="Trường hợp nào cần đi khám ngay?", priority=75),
    ],
    Intent.SIDE_EFFECT_DURATION.value: [
        _t("Ghi chú thời gian xuất hiện", "report", type=T, tool="append_care_note", priority=65),
    ],
    Intent.SIDE_EFFECT_MANAGEMENT.value: [
        _t("Báo bác sĩ", "report", type=T, tool="append_care_note", priority=75),
        _t("Xem tương tác thuốc", "info", prompt="{drug} có tương tác gì khiến tác dụng phụ nặng hơn?", requires=["has_meds"], priority=60),
    ],
    Intent.UNEXPECTED_SYMPTOM_CHECK.value: [
        _t("Triệu chứng có do thuốc không?", "triage", prompt="Triệu chứng này có thể do thuốc tôi đang dùng không?", requires=["has_meds"], priority=85),
        _t("Đi khám", "safety", prompt="Có nên đi khám không?", priority=70),
    ],
    Intent.ALLERGIC_REACTION_GUIDANCE.value: [
        _t("Gọi 115 / cấp cứu", "emergency", type=E, priority=100),
        _t("Ngưng thuốc & liên hệ bác sĩ", "emergency", type=E, priority=95),
    ],
    Intent.REPORT_SIDE_EFFECT.value: [
        _t("Ghi nhận vào hồ sơ", "report", type=T, tool="append_care_note", priority=90),
        _t("Liên hệ bác sĩ", "report", type=E, priority=80),
    ],
}

# ============================================================================
# INTERACTIONS
# ============================================================================
_INTERACTIONS: dict[str, list[dict]] = {
    Intent.DRUG_DRUG_INTERACTION.value: [
        _t("Kiểm tra tương tác {drug} & {next_drug}", "interaction", type=T, tool="check_drug_interaction", tool_args={"drug_a": "{drug}", "drug_b": "{next_drug}"}, requires=["has_two_meds"], priority=95),
        _t("Liên hệ dược sĩ", "safety", type=E, priority=80),
        _t("Cách giãn giờ uống", "info", prompt="Nên giãn giờ uống 2 thuốc này thế nào?", requires=["has_two_meds"], priority=70),
    ],
    Intent.DRUG_FOOD_INTERACTION.value: [
        _t("Thực phẩm cần tránh", "info", prompt="{drug} cần tránh thực phẩm nào?", requires=["has_meds"], priority=75),
    ],
    Intent.DRUG_ALCOHOL_INTERACTION.value: [
        _t("Mức độ rủi ro với rượu bia", "safety", prompt="Uống rượu khi dùng {drug} nguy hiểm đến đâu?", requires=["has_meds"], priority=80),
    ],
    Intent.DRUG_SUPPLEMENT_INTERACTION.value: [
        _t("Kiểm tra vitamin/TPCN", "interaction", prompt="Các vitamin tôi đang dùng có tương tác với {drug} không?", requires=["has_meds"], priority=70),
    ],
    Intent.CONTRAINDICATION_CHECK.value: [
        _t("Liên hệ bác sĩ xác nhận", "safety", type=E, priority=85),
        _t("Xem bệnh lý nền", "info", type=N, route="/profile/conditions", priority=60),
    ],
    Intent.PREGNANCY_LACTATION_SAFE.value: [
        _t("Hỏi bác sĩ sản khoa", "safety", type=E, priority=90),
        _t("Xem phân loại an toàn", "info", prompt="{drug} thuộc nhóm an toàn nào cho thai kỳ?", requires=["has_meds"], priority=70),
    ],
}

# ============================================================================
# ADHERENCE & EFFECTIVENESS
# ============================================================================
_ADHERENCE: dict[str, list[dict]] = {
    Intent.TREATMENT_EFFECTIVENESS.value: [
        _t("Xem tiến độ 7 ngày", "adherence", prompt="Tình hình tuân thủ 7 ngày gần đây của tôi?", priority=80),
        _t("Ghi chú cải thiện/không cải thiện", "report", type=T, tool="append_care_note", priority=70),
    ],
    Intent.TREATMENT_DURATION.value: [
        _t("Xem chỉ định bác sĩ", "info", type=N, route="/treatment", priority=70),
    ],
    Intent.CAN_STOP_EARLY.value: [
        _t("KHÔNG tự ngưng - hỏi bác sĩ", "safety", type=E, priority=95),
        _t("Xem rủi ro ngưng sớm", "info", prompt="Ngưng {drug} sớm có rủi ro gì?", requires=["has_meds"], priority=75),
    ],
    Intent.TREATMENT_REMINDER_SETUP.value: [
        _t("Đặt nhắc mới", "reminder", type=T, tool="save_reminder_intent", priority=90),
        _t("Xem nhắc hiện có", "reminder", type=N, route="/reminders", priority=70),
    ],
    Intent.TREATMENT_TRACKING.value: [
        _t("Xem adherence chi tiết", "adherence", type=N, route="/adherence", priority=85),
        _t("Mẹo tuân thủ", "tips", prompt="Cho tôi vài mẹo tuân thủ điều trị", priority=65),
    ],
    Intent.TREATMENT_COMPLIANCE_TIPS.value: [
        _t("Đặt nhắc tự động", "reminder", type=T, tool="save_reminder_intent", priority=80),
        _t("Xem chuỗi đã đạt", "adherence", type=N, route="/adherence", priority=60),
    ],
}

# ============================================================================
# STORAGE
# ============================================================================
_STORAGE: dict[str, list[dict]] = {
    Intent.STORAGE_INSTRUCTIONS.value: [
        _t("Kiểm tra hạn sử dụng", "info", prompt="Hạn sử dụng {drug} của tôi còn bao lâu?", requires=["has_meds"], priority=70),
    ],
    Intent.EXPIRY_CHECK.value: [
        _t("Ghi nhận hết hạn, cần mua lại", "report", type=T, tool="append_care_note", priority=75),
    ],
    Intent.TEMPERATURE_REQUIREMENT.value: [
        _t("Xem yêu cầu độ ẩm/ánh sáng", "info", prompt="{drug} có cần tránh ẩm, ánh sáng không?", requires=["has_meds"], priority=60),
    ],
    Intent.HUMIDITY_LIGHT_SENSITIVITY.value: [
        _t("Xem nhiệt độ bảo quản", "info", prompt="{drug} bảo quản ở nhiệt độ nào?", requires=["has_meds"], priority=60),
    ],
}

# ============================================================================
# DRUG & DISEASE INFO
# ============================================================================
_INFO: dict[str, list[dict]] = {
    Intent.DRUG_INFO_GENERAL.value: [
        _t("Xem tác dụng phụ thường gặp", "info", prompt="Tác dụng phụ thường gặp của {drug}?", requires=["has_meds"], priority=75),
        _t("Xem tương tác thuốc", "interaction", prompt="{drug} có tương tác với thuốc nào?", requires=["has_meds"], priority=70),
    ],
    Intent.DRUG_COMPOSITION.value: [
        _t("Xem tên gốc / biệt dược", "info", prompt="{drug} có những tên biệt dược nào?", requires=["has_meds"], priority=65),
    ],
    Intent.DRUG_BRAND_GENERIC.value: [
        _t("Xem thành phần", "info", prompt="Thành phần {drug}?", requires=["has_meds"], priority=60),
    ],
    Intent.DISEASE_INFO_GENERAL.value: [
        _t("Triệu chứng thường gặp", "info", prompt="Triệu chứng của bệnh này?", priority=70),
        _t("Cách phòng ngừa", "info", prompt="Cách phòng ngừa bệnh này?", priority=65),
    ],
    Intent.DISEASE_SYMPTOMS_CHECK.value: [
        _t("Khi nào cần đi khám?", "safety", prompt="Triệu chứng nào cần đi khám ngay?", priority=80),
    ],
    Intent.DISEASE_RISK_FACTORS.value: [
        _t("Cách phòng ngừa", "info", prompt="Làm sao phòng ngừa?", priority=70),
    ],
    Intent.DISEASE_PREVENTION.value: [
        _t("Lựa chọn điều trị", "info", prompt="Các lựa chọn điều trị là gì?", priority=65),
    ],
    Intent.TREATMENT_OPTIONS.value: [
        _t("So sánh hiệu quả", "info", prompt="So sánh hiệu quả các phương án điều trị", priority=70),
    ],
}

# ============================================================================
# SPECIAL POPULATIONS
# ============================================================================
_SPECIAL: dict[str, list[dict]] = {
    Intent.PEDIATRIC_USE.value: [
        _t("Hỏi bác sĩ nhi", "safety", type=E, priority=90),
        _t("Xem liều theo cân nặng", "info", prompt="Liều {drug} cho trẻ theo cân nặng?", requires=["has_meds"], priority=70),
    ],
    Intent.ELDERLY_USE.value: [
        _t("Xem chống chỉ định", "safety", prompt="{drug} có chống chỉ định ở người cao tuổi?", requires=["has_meds"], priority=75),
    ],
    Intent.PREGNANCY_USE.value: [
        _t("Hỏi bác sĩ sản khoa", "safety", type=E, priority=95),
    ],
    Intent.CHRONIC_DISEASE_USE.value: [
        _t("Xem tương tác với thuốc mãn tính", "interaction", prompt="{drug} có tương tác với thuốc mãn tính tôi đang dùng?", requires=["has_meds"], priority=80),
    ],
}

# ============================================================================
# EMERGENCY
# ============================================================================
_EMERGENCY: dict[str, list[dict]] = {
    Intent.OVERDOSE_GUIDANCE.value: [
        _t("GỌI 115 NGAY", "emergency", type=E, priority=100),
        _t("Liên hệ trung tâm chống độc", "emergency", type=E, priority=95),
        _t("Ghi lại lượng đã uống", "report", type=T, tool="append_care_note", priority=85),
    ],
    Intent.EMERGENCY_SYMPTOM.value: [
        _t("GỌI 115 NGAY", "emergency", type=E, priority=100),
        _t("Đến cơ sở y tế gần nhất", "emergency", type=E, priority=95),
    ],
    Intent.POISONING_GUIDANCE.value: [
        _t("GỌI 115 NGAY", "emergency", type=E, priority=100),
        _t("Trung tâm chống độc", "emergency", type=E, priority=95),
    ],
    Intent.CONTACT_DOCTOR.value: [
        _t("Xem danh bạ bác sĩ", "contact", type=N, route="/contacts/doctors", priority=85),
        _t("Chuẩn bị thông tin trao đổi", "report", prompt="Tóm tắt tình trạng của tôi để gửi bác sĩ", priority=70),
    ],
}

# ============================================================================
# META
# ============================================================================
_META: dict[str, list[dict]] = {
    Intent.GREETING.value: [
        _t("Hôm nay tôi uống thuốc gì?", "schedule", prompt="Hôm nay tôi cần uống những thuốc nào?", priority=80),
        _t("Xem tuân thủ tuần qua", "adherence", prompt="Tình hình tuân thủ 7 ngày gần đây?", priority=70),
        _t("Đặt nhắc mới", "reminder", type=N, route="/reminders", priority=60),
    ],
    Intent.SMALL_TALK.value: [
        _t("Hỏi về thuốc hiện tại", "info", prompt="Cho tôi xem danh sách thuốc đang dùng", requires=["has_meds"], priority=60),
    ],
    Intent.UNKNOWN.value: [
        _t("Hỏi về lịch uống thuốc", "schedule", prompt="Hôm nay tôi uống thuốc gì?", priority=60),
        _t("Hỏi về tác dụng phụ", "info", prompt="Tác dụng phụ thường gặp của thuốc tôi đang dùng?", requires=["has_meds"], priority=55),
    ],
}


# ============================================================================
# MERGE
# ============================================================================
ACTION_MAP: dict[str, list[dict]] = {
    **_SCHEDULE,
    **_SIDE_EFFECTS,
    **_INTERACTIONS,
    **_ADHERENCE,
    **_STORAGE,
    **_INFO,
    **_SPECIAL,
    **_EMERGENCY,
    **_META,
}


# Follow-up chain: sau intent A, gợi ý chain sang intent B
FOLLOW_UP_CHAIN: dict[str, list[str]] = {
    Intent.SIDE_EFFECT_CHECK.value: [Intent.REPORT_SIDE_EFFECT.value, Intent.CONTACT_DOCTOR.value],
    Intent.CHECK_MED_SCHEDULE.value: [Intent.TREATMENT_TRACKING.value],
    Intent.MISSED_DOSE_GUIDANCE.value: [Intent.TREATMENT_COMPLIANCE_TIPS.value],
    Intent.DRUG_DRUG_INTERACTION.value: [Intent.CONTACT_DOCTOR.value],
    Intent.DRUG_INFO_GENERAL.value: [Intent.SIDE_EFFECT_CHECK.value, Intent.DRUG_DRUG_INTERACTION.value],
}


# Default fallback khi intent không có trong ACTION_MAP
DEFAULT_ACTIONS: list[dict] = [
    _t("Tóm tắt ngắn", "summary", prompt="Tóm tắt câu trả lời thành 3 ý chính", priority=50),
    _t("Kế hoạch hôm nay", "planning", prompt="Gợi ý kế hoạch theo dõi thuốc cho hôm nay", priority=40),
]
