# MedIntel - Sơ đồ mô hình hóa kiến trúc và chức năng

Tài liệu này tổng hợp sơ đồ từ `doc.md`, `architecture.md`, `db-design.md`, `agentic-medical.md`.

## 1) Sơ đồ bối cảnh (hệ thống tổng thể)

```mermaid
flowchart LR
    Patient["Bệnh nhân"] --> App["Ứng dụng MedIntel (Flutter)"]
    Caregiver["Người chăm sóc"] --> App
    Doctor["Bác sĩ/Nhà thuốc (ngoài hệ thống)"] -->|Đơn thuốc/hướng dẫn| Patient

    App -->|REST/WebSocket| API["Backend FastAPI + Điều phối tác tử"]
    API --> PG["PostgreSQL (dữ liệu có cấu trúc)"]
    API --> VEC["pgvector (RAG thuốc, tác dụng phụ, hướng dẫn)"]
    API --> STORE["R2/S3 (ảnh đơn thuốc)"]
    API --> NOTI["FCM/Thông báo cục bộ"]
    API --> LLM["Dịch vụ LLM + Quét"]
```

## 2) Sơ đồ container (kiến trúc 3 lớp)

```mermaid
flowchart TB
    subgraph Client["Lớp Client"]
        M1["Giao diện Flutter"]
        M2["Quản lý trạng thái (Riverpod)"]
        M3["Máy nhắc lịch (cục bộ)"]
        M4["API Client (Dio)"]
    end

    subgraph Server["Lớp máy chủ tác tử (FastAPI)"]
        S1["Định tuyến API"]
        S2["Middleware xác thực/đồng bộ"]
        S3["Điều phối tác tử"]
        S4["Lớp công cụ (Tool Layer)"]
        S5["Dịch vụ nghiệp vụ"]
        S6["Repository/ORM"]
    end

    subgraph Data["Lớp dữ liệu"]
        D1["PostgreSQL"]
        D2["pgvector"]
        D3["Lưu trữ đối tượng (R2/S3)"]
        D4["Redis (tùy chọn)"]
    end

    Client --> Server
    S1 --> S3
    S3 --> S4
    S4 --> S5 --> S6
    S6 --> D1
    S6 --> D2
    S5 --> D3
    S3 --> D4
```

## 3) Bản đồ chức năng nghiệp vụ (Functional Map)

```mermaid
mindmap
  root((MedIntel))
    Hồ sơ và đồng bộ
      Hồ sơ local-first
      Đồng bộ đa thiết bị
      Liên kết người chăm sóc
    Quản lý điều trị
      Hồ sơ bệnh án
      Đợt điều trị
      Danh mục thuốc
      Lịch uống thuốc
      Nhật ký dùng thuốc
    Nhắc nhở và tuân thủ
      Nhắc giờ uống thuốc
      Đánh dấu đã uống/quên/bỏ qua
      Báo cáo tỷ lệ tuân thủ
    Trợ lý AI điều trị
      Quét đơn thuốc
      Giải thích thuốc
      Kiểm tra tác dụng phụ
      Kiểm tra tương tác thuốc
      Hỏi đáp theo ngữ cảnh bệnh nhân
    Bảo mật và kiểm soát
      Nhật ký kiểm toán
      Cảnh báo an toàn y tế
      Giới hạn khuyến nghị (không thay bác sĩ)
```

## 4) Luồng agentic mở rộng (đa tầng điều phối)

```mermaid
flowchart TD
    U["Tin nhắn người dùng"] --> P0["Tiền xử lý ngữ cảnh<br/>- profile_id<br/>- lịch dùng thuốc hôm nay<br/>- lịch sử hội thoại"]
    P0 --> I["Nhận diện ý định + thực thể"]
    I --> D{Nhóm ý định chính}

    D -->|Ghi nhận dùng thuốc| A1["Medication Agent"]
    D -->|Lịch dùng thuốc| A2["Schedule Agent"]
    D -->|Thông tin thuốc| A3["Drug Knowledge Agent"]
    D -->|Tác dụng phụ/triệu chứng| A4["Symptom Agent"]
    D -->|Tương tác thuốc| A5["Interaction Agent"]
    D -->|Báo cáo tuân thủ| A6["Adherence Agent"]

    A1 --> PL["Planner/Executor<br/>lập kế hoạch gọi công cụ"]
    A2 --> PL
    A3 --> PL
    A4 --> PL
    A5 --> PL
    A6 --> PL

    PL --> T1["Tool: get_today_medications()"]
    PL --> T2["Tool: log_medication_taken()"]
    PL --> T3["Tool: get_today_schedule()"]
    PL --> T4["Tool: get_drug_info()/search_drug()"]
    PL --> T5["Tool: check_side_effects()"]
    PL --> T6["Tool: check_drug_interaction()"]
    PL --> T7["Tool: get_compliance_rate()"]

    T1 --> E["Evidence Composer<br/>hợp nhất dữ liệu + tri thức"]
    T2 --> E
    T3 --> E
    T4 --> E
    T5 --> E
    T6 --> E
    T7 --> E

    E --> S["Safety Guardrails<br/>- policy check<br/>- chống suy diễn quá mức<br/>- quy tắc không thay bác sĩ"]
    S --> R{"Mức nguy cơ"}
    R -->|Nhẹ| F1["Phản hồi + hướng dẫn theo dõi"]
    R -->|Trung bình| F2["Phản hồi + khuyến nghị liên hệ bác sĩ"]
    R -->|Nặng| F3["Escalation: cơ sở y tế/cấp cứu"]

    F1 --> L["Ghi log, audit, metrics"]
    F2 --> L
    F3 --> L
    L --> FB["Feedback loop<br/>cập nhật prompt/policy/eval"]
```

## 5) Sequence - Trường hợp "Tôi vừa uống thuốc"

```mermaid
sequenceDiagram
    participant P as Bệnh nhân
    participant A as Ứng dụng di động
    participant G as Điều phối tác tử
    participant DB as PostgreSQL
    participant KG as Tri thức thuốc (pgvector)

    P->>A: "Tôi vừa uống thuốc"
    A->>G: Tin nhắn chat + profile_id
    G->>DB: get_today_medications(profile_id)
    DB-->>G: [Aspirin, Metformin, ...]
    G-->>A: "Bạn vừa uống thuốc nào?"
    P->>A: "Metformin"
    A->>G: Thuốc được chọn
    G->>DB: log_medication_taken(...)
    G->>KG: get_drug_info + side_effects
    KG-->>G: Thông tin thuốc + cảnh báo
    G-->>A: Xác nhận đã ghi + hướng dẫn an toàn
```

## 6) Tổng quan mô hình dữ liệu (rút gọn từ `db-design.md`)

```mermaid
erDiagram
    PROFILES ||--o{ MEDICAL_RECORDS : so_huu
    MEDICAL_RECORDS ||--o{ TREATMENT_PERIODS : gom
    TREATMENT_PERIODS ||--o{ MEDICATIONS : chua
    MEDICATIONS ||--o{ MEDICATION_SCHEDULES : lap_lich
    MEDICATION_SCHEDULES ||--o{ MEDICATION_LOGS : ghi_nhan
    PROFILES ||--o{ MEDICATION_LOGS : tao_boi

    PROFILES ||--o{ HEALTH_HABITS : theo_doi
    HEALTH_HABITS ||--o{ HABIT_REMINDERS : nhac_nho
    HEALTH_HABITS ||--o{ HABIT_LOGS : ghi_nhan

    PROFILES ||--o{ CAREGIVER_PATIENT_LINKS : benh_nhan
    PROFILES ||--o{ CAREGIVER_PATIENT_LINKS : nguoi_cham_soc

    PROFILES ||--o{ NOTIFICATIONS : nhan
    PROFILES ||--o{ COMPLIANCE_REPORTS : bao_cao
    PROFILES ||--o{ DEVICES : dong_bo
    PROFILES ||--o{ AUDIT_LOGS : thao_tac
```

## 7) Luồng bảo mật và quản trị (đồng bộ local-first)

```mermaid
flowchart LR
    C["Client tạo profile_id (UUID)"] --> L["Lưu cục bộ trên thiết bị"]
    L --> S["Đồng bộ theo lô lên server"]
    S --> U["Upsert theo profile_id (idempotent)"]
    U --> A["Ghi audit_logs"]
    U --> R["Đồng bộ ngược về client khác (nếu có)"]
```

## 8) Gợi ý sử dụng trong báo cáo

- Chương kiến trúc tổng thể: dùng sơ đồ 1 + 2.
- Chương đặc tả chức năng: dùng sơ đồ 3.
- Chương AI/agentic: dùng sơ đồ 4 + 5.
- Chương CSDL: dùng sơ đồ 6.
- Chương đồng bộ và bảo mật: dùng sơ đồ 7.

