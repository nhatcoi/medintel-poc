---
name: medintel-architecture
description: >-
  Kiến trúc tổng thể MedIntel / AI health agent: 3 lớp (client → FastAPI agent → DB), tool layer,
  PostgreSQL + pgvector (sau), Redis tùy chọn. Dùng khi thiết kế API, agent, RAG, triển khai Docker DB,
  hoặc khi user nhắc architecture.md, stack Flutter/FastAPI, Pydantic AI / LangChain / LangGraph.
---

# MedIntel — kiến trúc (theo `architecture.md`)

## Nguồn chuẩn

- **`architecture.md`** (root repo): lớp hệ thống, gợi ý framework agent, DB, vector, Redis.
- **`db-design.md`**, **`doc.md`**: chi tiết schema & đề tài; ORM tại `server-med/app/models/`.

## Nguyên tắc kiến trúc

1. **Ba lớp:** Client (Flutter) → **REST/WebSocket** → **Python Agent Server (FastAPI)** → **Database** (PostgreSQL; vector/pgvector cho drug knowledge sau; Redis tùy chọn cho cache/memory/rate limit).
2. **Agent không đọc DB trực tiếp trong lý tưởng tầng reasoning:** luồng đi qua **tools** (vd. `get_today_medications`, `log_medication_taken`, `search_drug`, `check_drug_interaction`, …). Triển khai thực tế có thể gộp repository trong service; vẫn giữ ranh giới “tool = hành động có hợp đồng”.
3. **Dữ liệu có cấu trúc** (thuốc người dùng, lịch, log, hồ sơ): **PostgreSQL**, không bắt buộc vector.
4. **Kiến thức thuốc / mô tả dài / side effects** (RAG): **pgvector** cùng Postgres khi cần; chỉ cân nhắc DB vector riêng (Qdrant, Weaviate) khi quy mô embedding rất lớn.
5. **Stack gợi ý trong tài liệu:** Flutter + FastAPI + **Pydantic AI** (nhẹ) hoặc LangChain / **LangGraph** (workflow phức tạp).

## Khớp repo hiện tại

- Backend: **`server-med`** (FastAPI, SQLAlchemy). Schema vận hành dev: **`create_all` từ model** khi `create_tables_on_startup=true` — không phụ thuộc file SQL init trong Docker nếu chọn compose “chỉ Postgres”.
- Định danh: **`profiles` / `profile_id`** (local-first + sync), không IAM cổ điển trong `db-design.md`.
- Thuốc quốc gia lớn: Postgres + index (GIN, **pg_trgm** khi cần fuzzy search) — bổ sung khi ingestion ổn định.

## Khi agent thiết kế / code

- Ưu tiên **một nguồn schema**: ORM + `db-design.md`; tránh thêm bảng chỉ trong SQL init mà không có model.
- API và agent: giữ **response ngắn**, tool có tham số rõ; phần nhạy cảm y tế: không chẩn đoán thay BS (thống nhất `agentic-medical.md` / skill agentic).
- Docker: `server-med/docker-compose.yml` chỉ chạy **PostgreSQL**, không mount `docker-entrypoint-initdb.d` — schema do app tạo.

## Skill liên quan

- **`/medintel-nckh`** — báo cáo, COM-B, PDF.
- **`/medintel-db-local-sync`** — schema, profiles, ORM.
- **`/agentic-medical-adherence`** — intent, tool, orchestration.
