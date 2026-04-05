# Hướng dẫn dự án (Claude Code)

@AGENTS.md

Đây là workspace **NCKH**; tài liệu kỹ thuật đề tài **MedIntel** nằm trong `doc.md`. Agent nên ưu tiên tiếng Việt khi người dùng viết tiếng Việt, giữ văn phong học thuật rõ ràng.

## Cấu trúc quan trọng

| Thành phần | Đường dẫn |
|------------|-----------|
| Tài liệu đề tài chính | `doc.md` |
| Thiết kế CSDL (local-first) | `db-design.md` |
| Kiến trúc AI agent / stack | `architecture.md` |
| Bộ nhớ / quy ước Claude | `CLAUDE.md` (file này) |
| Ghi đè cá nhân (không commit) | `CLAUDE.local.md` |
| Skills (lệnh `/tên-skill`) | `.claude/skills/<tên>/SKILL.md` |
| Subagent tùy chỉnh | `.claude/agents/*.md` |
| Quy tắc theo chủ đề | `.claude/rules/*.md` |
| Cài đặt phiên bản | `.claude/settings.json` |

## Quy ước làm việc

- Cập nhật `doc.md` khi người dùng xác nhận mốc tiến độ, thay đổi mục tiêu, hoặc khi họ yêu cầu “cập nhật tài liệu”.
- Không đoán số liệu hay trích dẫn: nếu thiếu nguồn, ghi `(cần bổ sung)` hoặc hỏi lại.
- Giữ diff nhỏ, đúng phạm vi; không refactor lan sang file không liên quan.

## Lệnh hữu ích trong Claude Code

- `/skills` — danh sách skill
- `/agents` — quản lý subagent
- `/memory` — xem memory đã nạp
- `/context` — usage ngữ cảnh

## Skill / agent gợi ý trong repo

- `/medintel-nckh` — ngữ cảnh đề tài MedIntel + `doc.md` + `bao-cao-nckh-med-2.pdf`
- `/nckh-bao-cao` — khung viết mục báo cáo NCKH
- `/tai-lieu-tham-khao` — định dạng tham khảo
- `/agentic-medical-adherence` — thiết kế chat agentic tuân thủ điều trị + `agentic-medical.md`
- `/medintel-server-api` — FastAPI `server-med`: agent layer, chat, treatment/medications
- `/medintel-db-local-sync` — schema `db-design.md`, profiles/sync, không IAM cổ điển
- `/medintel-architecture` — kiến trúc 3 lớp, tools, Postgres/pgvector, `architecture.md`
- Subagent `nckh-reviewer` — rà soát `doc.md` và tính nhất quán (chỉ đọc/tìm)
