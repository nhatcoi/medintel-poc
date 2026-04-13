# MedIntel - Sơ đồ kiến trúc vĩ mô (Macro)

## 1) Kiến trúc vĩ mô đa lớp

```mermaid
flowchart TB
    subgraph L1["Lớp trải nghiệm"]
        A["App bệnh nhân"]
        B["App/cổng người chăm sóc"]
        C["Cổng chuyên gia y tế (tùy chọn)"]
    end

    subgraph L2["Lớp biên & tích hợp"]
        D["API Gateway"]
        E["Auth/Device Trust"]
        F["Rate limit/WAF"]
    end

    subgraph L3["Lớp nghiệp vụ số"]
        G["Medication & Schedule"]
        H["Adherence & Habit"]
        I["Care-team Collaboration"]
        J["Notification Orchestrator"]
    end

    subgraph L4["Lớp agentic AI"]
        K["Intent Router"]
        L["Planner/Executor"]
        M["Tool Orchestrator"]
        N["Safety Guardrails"]
        O["Evidence Composer (RAG)"]
    end

    subgraph L5["Lớp dữ liệu"]
        P["PostgreSQL (OLTP)"]
        Q["pgvector (tri thức thuốc)"]
        R["Object Storage (ảnh/Quét)"]
        S["Audit/Event Store"]
    end

    subgraph L6["Lớp vận hành"]
        T["Observability"]
        U["Model/Prompt Registry"]
        V["CI/CD + Data Pipeline"]
    end

    L1 --> L2 --> L3
    L2 --> L4
    L3 --> L5
    L4 --> L5
    L4 --> L3
    L5 --> L6
```

## 2) Sơ đồ ý định -> tác tử -> công cụ

```mermaid
flowchart LR
    A["Ý định người dùng"] --> B["Intent Router"]
    B --> C1["Medication Agent"]
    B --> C2["Schedule Agent"]
    B --> C3["Knowledge Agent"]
    B --> C4["Side-effect Agent"]
    B --> C5["Interaction Agent"]

    C1 --> D["Tool Layer"]
    C2 --> D
    C3 --> D
    C4 --> D
    C5 --> D

    D --> E1["get_today_medications"]
    D --> E2["log_medication_taken"]
    D --> E3["get_today_schedule"]
    D --> E4["search_drug/get_drug_info"]
    D --> E5["check_side_effects"]
    D --> E6["check_drug_interaction"]

    E1 --> F["Safety Engine"]
    E2 --> F
    E3 --> F
    E4 --> F
    E5 --> F
    E6 --> F

    F --> G["Phản hồi có bằng chứng + khuyến nghị"]
```

## 3) Luồng macro cho ca "Tôi vừa uống thuốc"

```mermaid
sequenceDiagram
    participant U as Người dùng
    participant APP as Mobile App
    participant ORC as Agent Orchestrator
    participant TOOL as Tool Layer
    participant DB as PostgreSQL
    participant VEC as pgvector
    participant SAFE as Safety Layer

    U->>APP: "Tôi vừa uống thuốc"
    APP->>ORC: message + profile context
    ORC->>TOOL: get_today_medications(profile_id)
    TOOL->>DB: query thuốc hôm nay
    DB-->>TOOL: danh sách thuốc
    TOOL-->>ORC: options
    ORC-->>APP: hỏi lại "Bạn vừa uống thuốc nào?"
    U->>APP: chọn thuốc
    APP->>ORC: selected medication
    ORC->>TOOL: log_medication_taken(...)
    ORC->>TOOL: get_drug_info/check_side_effects
    TOOL->>VEC: retrieve evidence
    VEC-->>TOOL: chunks liên quan
    TOOL-->>ORC: evidence bundle
    ORC->>SAFE: policy + risk check
    SAFE-->>ORC: response policy
    ORC-->>APP: xác nhận + cảnh báo + hành động tiếp theo
```

## 4) Vòng an toàn y tế (Clinical Safety Loop)

```mermaid
flowchart LR
    A["Đầu vào người dùng<br/>triệu chứng/ngữ cảnh dùng thuốc"] --> B["Safety Intake"]
    B --> C["Chuẩn hóa thực thể y khoa<br/>(thuốc, liều, triệu chứng)"]
    C --> D["Risk Stratification Engine"]
    D --> E{"Mức nguy cơ"}
    E -->|Thấp| F1["Khuyến nghị tự theo dõi + nhắc tái đánh giá"]
    E -->|Trung bình| F2["Khuyến nghị liên hệ bác sĩ trong khung thời gian"]
    E -->|Cao| F3["Escalation khẩn: cơ sở y tế/cấp cứu"]
    F1 --> G["Audit + Explainability"]
    F2 --> G
    F3 --> G
    G --> H["Feedback để hiệu chỉnh policy/rule"]
    H --> D
```

## 5) Kiến trúc triển khai (Deployment Topology)

```mermaid
flowchart TB
    subgraph EDGE["Public Edge"]
        E1["CDN/WAF"]
        E2["API Gateway"]
    end

    subgraph APP["Application Zone"]
        A1["FastAPI Pods"]
        A2["Agent Orchestrator Pods"]
        A3["Worker Pods (Quét, batch jobs)"]
        A4["Notification Worker"]
    end

    subgraph DATA["Data Zone"]
        D1["PostgreSQL Primary"]
        D2["PostgreSQL Replica"]
        D3["Redis"]
        D4["Object Storage"]
        D5["Vector Extension (pgvector)"]
    end

    subgraph OPS["Operations Zone"]
        O1["Prometheus/Grafana"]
        O2["Centralized Logging"]
        O3["Alertmanager/On-call"]
        O4["CI/CD Runner"]
    end

    E1 --> E2
    E2 --> A1
    E2 --> A2
    A1 --> D1
    A2 --> D1
    A2 --> D5
    A3 --> D4
    A4 --> D3
    D1 --> D2
    APP --> O1
    APP --> O2
    O1 --> O3
    O4 --> APP
```

## 6) Data Lineage cho nhánh AI y tế

```mermaid
flowchart LR
    S1["Nguồn dữ liệu thuốc<br/>(label, hướng dẫn, tương tác)"] --> P1["Ingestion & Validation"]
    S2["Quét đơn thuốc người dùng"] --> P1
    S3["Nhật ký dùng thuốc/symptom"] --> P1

    P1 --> P2["Chuẩn hóa + khử nhiễu + masking"]
    P2 --> P3["Chunking tri thức"]
    P3 --> P4["Embedding Pipeline"]
    P4 --> K1["Kho vector (pgvector)"]
    P2 --> K2["Kho nghiệp vụ (PostgreSQL)"]
    P2 --> K3["Kho đối tượng (ảnh/tệp)"]

    K1 --> R1["RAG Retrieval API"]
    K2 --> R1
    K3 --> R1
    R1 --> A1["Agent Response Composer"]
    A1 --> Q1["Safety + Quality Checks"]
    Q1 --> U1["Phản hồi cuối cho người dùng"]
```

## 7) Bảng điều khiển KPI chiến lược

```mermaid
flowchart TB
    K["KPI MedIntel (Macro)"] --> K1["Nhóm KPI lâm sàng hỗ trợ"]
    K --> K2["Nhóm KPI hành vi tuân thủ"]
    K --> K3["Nhóm KPI AI & an toàn"]
    K --> K4["Nhóm KPI vận hành hệ thống"]

    K1 --> A1["Tỷ lệ phát hiện sớm nguy cơ"]
    K1 --> A2["Thời gian từ cảnh báo đến hành động"]

    K2 --> B1["Medication Adherence Rate"]
    K2 --> B2["Missed-dose recovery rate"]
    K2 --> B3["Persistence theo chu kỳ điều trị"]

    K3 --> C1["Tool-call accuracy"]
    K3 --> C2["Tỷ lệ trả lời có bằng chứng"]
    K3 --> C3["False reassurance rate"]
    K3 --> C4["Escalation precision"]

    K4 --> D1["Latency p95/p99"]
    K4 --> D2["Uptime/SLO"]
    K4 --> D3["MTTR sự cố"]
    K4 --> D4["Tỷ lệ lỗi pipeline dữ liệu"]
```

## 8) Lộ trình trưởng thành hệ thống (Maturity Roadmap)

```mermaid
flowchart LR
    M1["Mức 1 - Prototype"] --> M2["Mức 2 - Pilot lâm sàng hỗ trợ"]
    M2 --> M3["Mức 3 - Scale đa cơ sở"]
    M3 --> M4["Mức 4 - Tối ưu liên tục"]

    M1 --- D1["Rule-based + tool cơ bản"]
    M2 --- D2["Guardrails + KPI + giám sát"]
    M3 --- D3["Đa tenant + HA + data governance"]
    M4 --- D4["A/B prompt, eval tự động, cải tiến vòng kín"]
```

