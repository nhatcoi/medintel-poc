# MedIntel - Bộ sơ đồ poster NCKH

> Mục tiêu: dùng trực tiếp cho poster/báo cáo tóm tắt, ưu tiên trực quan, ít chữ, khối lớn.

---

## Hình P1. Kiến trúc tổng thể hệ thống MedIntel

```mermaid
flowchart LR
    classDef main fill:#123CA6,color:#fff,stroke:#0d2c7a,stroke-width:2px;
    classDef sec fill:#EAF1FF,color:#0f172a,stroke:#123CA6,stroke-width:1.5px;
    classDef ai fill:#FFF4E6,color:#7c2d12,stroke:#f59e0b,stroke-width:1.5px;
    classDef data fill:#ECFDF3,color:#065f46,stroke:#10b981,stroke-width:1.5px;

    U["Bệnh nhân<br/>Người chăm sóc"]:::sec --> APP["Ứng dụng MedIntel<br/>(Flutter)"]:::main
    APP --> API["API Gateway + FastAPI"]:::main
    API --> ORC["Agent Orchestrator"]:::ai
    ORC --> TOOL["Tool Layer"]:::ai
    TOOL --> DB["PostgreSQL"]:::data
    TOOL --> VEC["pgvector (RAG)"]:::data
    TOOL --> OBJ["Object Storage<br/>(Ảnh đơn thuốc/Quét)"]:::data
    API --> NOTI["Push Notification"]:::sec
```

**Thông điệp chính:** Kiến trúc 3 lớp, AI agent là lõi điều phối giữa nghiệp vụ và tri thức thuốc.

---

## Hình P2. Luồng agentic "Tôi vừa uống thuốc"

```mermaid
flowchart TB
    classDef step fill:#ffffff,color:#111827,stroke:#374151,stroke-width:1.3px;
    classDef risk fill:#FEF2F2,color:#7f1d1d,stroke:#ef4444,stroke-width:1.5px;
    classDef ok fill:#ECFDF5,color:#14532d,stroke:#22c55e,stroke-width:1.5px;

    S1["1) Người dùng gửi tin nhắn"]:::step --> S2["2) Nhận diện ý định<br/>+ dựng ngữ cảnh"]:::step
    S2 --> S3["3) Chọn agent chuyên trách"]:::step
    S3 --> S4["4) Gọi tool:<br/>- get_today_medications<br/>- log_medication_taken<br/>- get_drug_info"]:::step
    S4 --> S5["5) Hợp nhất bằng chứng (RAG + DB)"]:::step
    S5 --> S6["6) Safety Guardrails"]:::step
    S6 --> D{"7) Mức nguy cơ"}:::risk
    D -->|Nhẹ/Trung bình| S7["8) Phản hồi + hướng dẫn theo dõi"]:::ok
    D -->|Nặng| S8["8) Khuyến nghị liên hệ cơ sở y tế"]:::risk
    S7 --> S9["9) Audit + KPI"]:::step
    S8 --> S9
```

**Thông điệp chính:** Mọi phản hồi đều qua lớp an toàn trước khi trả cho người bệnh.

---

## Hình P3. Bản đồ chức năng nghiên cứu

```mermaid
mindmap
  root((MedIntel))
    Tuân thủ dùng thuốc
      Nhắc lịch
      Ghi nhận đã uống
      Cảnh báo quên liều
    Trợ lý AI điều trị
      Hỏi đáp thuốc
      Tác dụng phụ
      Tương tác thuốc
      Triage nguy cơ
    Quản trị hồ sơ
      Hồ sơ bệnh
      Đợt điều trị
      Lịch và nhật ký
    Phối hợp chăm sóc
      Người chăm sóc
      Chia sẻ trạng thái
      Báo cáo cho bác sĩ
```

**Thông điệp chính:** Hệ thống tích hợp cả quản lý điều trị, AI hỗ trợ và phối hợp chăm sóc.

---

## Hình P4. Kiến trúc dữ liệu và tri thức

```mermaid
flowchart LR
    classDef in fill:#EEF2FF,stroke:#4F46E5,color:#1f2937;
    classDef proc fill:#FFFBEB,stroke:#D97706,color:#1f2937;
    classDef out fill:#ECFDF5,stroke:#059669,color:#1f2937;

    I1["Nguồn vào<br/>Quét đơn / lịch dùng thuốc / chat"]:::in --> P1["Chuẩn hóa dữ liệu"]:::proc
    P1 --> P2["Tách trường y khoa"]:::proc
    P2 --> P3["Embedding tri thức"]:::proc
    P2 --> D1["PostgreSQL"]:::out
    P3 --> D2["pgvector"]:::out
    P2 --> D3["Object Storage"]:::out
    D1 --> S1["API nghiệp vụ"]:::out
    D2 --> S2["RAG truy hồi"]:::out
    S1 --> A["Agent phản hồi có bằng chứng"]:::out
    S2 --> A
```

**Thông điệp chính:** Dữ liệu cấu trúc + dữ liệu ngữ nghĩa cùng phục vụ quyết định của agent.

---

## Hình P5. Khung đánh giá kết quả (KPI)

```mermaid
flowchart TB
    K["KPI MedIntel"] --> K1["Hiệu quả tuân thủ"]
    K["KPI MedIntel"] --> K2["An toàn AI"]
    K["KPI MedIntel"] --> K3["Hiệu năng hệ thống"]
    K["KPI MedIntel"] --> K4["Trải nghiệm người dùng"]

    K1 --> A1["Adherence rate"]
    K1 --> A2["Missed-dose recovery"]

    K2 --> B1["Tool-call accuracy"]
    K2 --> B2["Escalation precision"]
    K2 --> B3["False reassurance rate"]

    K3 --> C1["Latency p95/p99"]
    K3 --> C2["Uptime/SLO"]

    K4 --> D1["Task completion time"]
    K4 --> D2["Satisfaction score"]
```

**Thông điệp chính:** Đánh giá đồng thời 4 trục: lâm sàng hỗ trợ, AI an toàn, vận hành, trải nghiệm.

---

## Hình P6. Lộ trình phát triển theo giai đoạn

```mermaid
flowchart LR
    M1["GĐ1: Prototype"] --> M2["GĐ2: Pilot"]
    M2 --> M3["GĐ3: Scale"]
    M3 --> M4["GĐ4: Optimization"]

    M1 --- D1["Core app + nhắc thuốc + agent cơ bản"]
    M2 --- D2["Safety guardrails + báo cáo tuân thủ"]
    M3 --- D3["Đa thiết bị + giám sát vận hành + HA"]
    M4 --- D4["Tối ưu prompt/model + eval vòng kín"]
```

**Thông điệp chính:** Nghiên cứu có lộ trình tiến hóa rõ từ nguyên mẫu đến hệ thống vận hành quy mô.

---

## Gợi ý dàn poster

- Cột trái: **P1 + P3**
- Cột giữa: **P2 + P4**
- Cột phải: **P5 + P6**
- Dưới mỗi hình giữ 1 câu “Thông điệp chính” như trên để hội đồng đọc nhanh.

