# Sơ đồ Agentic MedIntel

```mermaid
flowchart TD
    U["Người dùng gửi câu hỏi"] --> G["API Gateway / Chat Endpoint"]
    G --> O["Agent Orchestrator"]
    O --> C["Context Builder<br/>- profile_id<br/>- lịch thuốc hôm nay<br/>- lịch sử chat"]
    C --> I["Intent Router"]

    I -->|Ghi nhận uống thuốc| A1["Medication Agent"]
    I -->|Hỏi lịch dùng thuốc| A2["Schedule Agent"]
    I -->|Hỏi thông tin thuốc| A3["Drug Knowledge Agent"]
    I -->|Tác dụng phụ/triệu chứng| A4["Symptom & Side-effect Agent"]
    I -->|Tương tác thuốc| A5["Interaction Agent"]

    A1 --> T1["Tool Calls"]
    A2 --> T1
    A3 --> T1
    A4 --> T1
    A5 --> T1

    T1 --> DB["PostgreSQL<br/>medications/schedules/logs"]
    T1 --> VDB["pgvector<br/>knowledge retrieval (RAG)"]
    T1 --> FS["Object Storage<br/>Quét/prescription images"]

    DB --> E["Evidence Composer"]
    VDB --> E
    FS --> E

    E --> S["Safety Guardrails<br/>- policy check<br/>- risk triage<br/>- escalation rules"]
    S --> R{"Mức rủi ro"}
    R -->|Nhẹ/Trung bình| F1["Phản hồi + hướng dẫn theo dõi"]
    R -->|Nặng| F2["Khuyến nghị liên hệ cơ sở y tế/cấp cứu"]

    F1 --> L["Logging & Audit"]
    F2 --> L
    L --> M["Monitoring/KPI<br/>latency, tool success, safety events"]
    F1 --> UO["Trả lời cho người dùng"]
    F2 --> UO
```

## Luồng ngắn gọn

1. Nhận tin nhắn -> dựng ngữ cảnh bệnh nhân.
2. Phân loại ý định -> chọn tác tử chuyên trách.
3. Tác tử gọi công cụ lấy dữ liệu cấu trúc + tri thức thuốc (RAG).
4. Ghép bằng chứng -> chạy lớp an toàn.
5. Trả lời theo mức rủi ro và ghi log theo dõi.

