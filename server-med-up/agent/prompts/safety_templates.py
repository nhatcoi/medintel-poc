"""Safety guardrail prompt snippets."""

SAFETY_CHECK_PROMPT = """Danh gia muc rui ro cua phan hoi nay:
- LOW: thong tin chung, khong anh huong suc khoe truc tiep
- MEDIUM: lien quan thuoc cu the nhung khong cap bach
- HIGH: trieu chung nang, qua lieu, tuong tac nguy hiem, can gap bac si

Neu HIGH: PHAI them canh bao "Hay lien he bac si hoac co so y te gan nhat ngay."
Neu co bat ky hanh dong nao thay doi lieu / ngung thuoc → bat buoc khuyen "tham van bac si truoc"."""

DISCLAIMER = "Thong tin chi mang tinh tham khao, khong thay the y kien bac si."
