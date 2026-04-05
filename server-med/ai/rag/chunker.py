"""Chia dữ liệu thuốc (crawl JSON) thành các chunk theo section lâm sàng."""

from __future__ import annotations

from dataclasses import dataclass

# Map section key → tên hiển thị tiếng Việt (dùng trong RAG context)
SECTION_LABELS: dict[str, str] = {
    "summary": "Tóm tắt",
    "chi_dinh": "Chỉ định",
    "chong_chi_dinh": "Chống chỉ định",
    "lieu_luong_cach_dung": "Liều lượng - Cách dùng",
    "tac_dung_phu": "Tác dụng phụ",
    "tuong_tac_thuoc": "Tương tác thuốc",
    "duoc_luc": "Dược lực",
    "duoc_dong_hoc": "Dược động học",
    "tac_dung": "Tác dụng",
    "cong_dung_thuoc": "Công dụng thuốc",
    "than_trong_luc_dung": "Thận trọng lúc dùng",
    "bao_quan": "Bảo quản",
}


@dataclass
class DrugChunk:
    section: str
    content: str
    token_estimate: int


def _estimate_tokens(text: str) -> int:
    """Ước lượng token (tiếng Việt ~1.5 token/từ, ~4 char/token)."""
    return max(1, len(text) // 4)


def _build_summary(drug: dict) -> str:
    """Tạo chunk tóm tắt từ metadata thuốc."""
    parts: list[str] = []
    ten = drug.get("ten") or ""
    chi_tiet = drug.get("chi_tiet_day_du") or {}
    ten_trang = chi_tiet.get("ten_trang") or ten

    parts.append(f"Tên thuốc: {ten_trang}")

    reg = drug.get("so_dang_ky") or ""
    if reg:
        parts.append(f"Số đăng ký: {reg}")

    form = drug.get("dang_bao_che") or ""
    if form:
        parts.append(f"Dạng bào chế: {form}")

    tp = chi_tiet.get("thanh_phan_ngan") or ""
    if tp:
        parts.append(f"Thành phần: {tp}")

    qc = chi_tiet.get("quy_cach_dong_goi") or ""
    if qc:
        parts.append(f"Quy cách: {qc}")

    # Bảng hoạt chất
    hc_list = chi_tiet.get("bang_hoat_chat") or []
    if hc_list:
        hc_strs = [f'{h["ten_hoat_chat"]} {h["ham_luong"]}' for h in hc_list if h.get("ten_hoat_chat")]
        if hc_strs:
            parts.append(f"Hoạt chất: {'; '.join(hc_strs)}")

    # Công ty
    cty = chi_tiet.get("cong_ty") or []
    if cty:
        cty_strs = [f'{c["ten"]} ({c.get("vai_tro", "")})'.strip() for c in cty if c.get("ten")]
        if cty_strs:
            parts.append(f"Công ty: {'; '.join(cty_strs)}")

    # Danh mục
    info = chi_tiet.get("thong_tin_nhanh") or {}
    cat = info.get("Danh mục") or ""
    if cat:
        parts.append(f"Danh mục: {cat}")

    # Mô tả ngắn từ schema.org
    schema = chi_tiet.get("schema_org_product") or {}
    desc = schema.get("mo_ta_ngan") or ""
    if desc:
        parts.append(f"Mô tả: {desc}")

    return "\n".join(parts)


def chunk_drug(drug: dict) -> list[DrugChunk]:
    """Chia một bản ghi thuốc thành các chunk theo section."""
    chunks: list[DrugChunk] = []
    chi_tiet = drug.get("chi_tiet_day_du") or {}
    ten = drug.get("ten") or chi_tiet.get("ten_trang") or "?"

    # 1) Summary chunk
    summary = _build_summary(drug)
    if summary.strip():
        chunks.append(DrugChunk(section="summary", content=summary, token_estimate=_estimate_tokens(summary)))

    # 2) Các mục lâm sàng ngắn (từ muc_lam_sang_html_ngan)
    clinical = chi_tiet.get("muc_lam_sang_html_ngan") or {}
    section_key_map = {
        "Chỉ định": "chi_dinh",
        "Chống chỉ định": "chong_chi_dinh",
        "Liều lượng - Cách dùng": "lieu_luong_cach_dung",
        "Tác dụng phụ": "tac_dung_phu",
        "Tương tác thuốc": "tuong_tac_thuoc",
    }

    # 3) Các phần bổ sung (prose dài hơn từ cac_phan_bo_sung)
    extra = chi_tiet.get("cac_phan_bo_sung") or {}

    # Merge: ưu tiên extra (dài hơn), fallback clinical (ngắn)
    all_sections: dict[str, str] = {}
    for label, key in section_key_map.items():
        text = extra.get(key) or clinical.get(label) or ""
        if text.strip():
            all_sections[key] = text.strip()

    # Các section chỉ có trong extra
    for key in ("duoc_luc", "duoc_dong_hoc", "tac_dung", "cong_dung_thuoc", "than_trong_luc_dung", "bao_quan"):
        text = extra.get(key) or ""
        if text.strip() and key not in all_sections:
            all_sections[key] = text.strip()

    for section_key, text in all_sections.items():
        label = SECTION_LABELS.get(section_key, section_key)
        content = f"[{ten}] {label}:\n{text}"
        chunks.append(DrugChunk(section=section_key, content=content, token_estimate=_estimate_tokens(content)))

    return chunks
