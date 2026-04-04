# Hướng dẫn cho coding agent

Workspace NCKH (đề tài MedIntel): ưu tiên tiếng Việt khi user dùng tiếng Việt; tài liệu kỹ thuật ở `doc.md`.

## Claude Code

Cấu hình đầy đủ nằm trong `CLAUDE.md` và thư mục `.claude/` (skills, agents, rules, `settings.json`).

## Skill / lệnh gợi ý (Claude Code)

- `/medintel-nckh` — MedIntel + PDF báo cáo + `doc.md`
- `/nckh-bao-cao` — khung viết báo cáo
- `/tai-lieu-tham-khao` — định dạng tham khảo
- Subagent `nckh-reviewer` — rà soát `doc.md` (chỉ đọc/tìm)
