#!/usr/bin/env python3
"""
Mẫu cào danh sách + trang chi tiết thuốc từ thuocbietduoc.com.vn.

Lưu ý pháp lý / đạo đức:
- Đọc Điều khoản sử dụng / chính sách của site; dữ liệu có thể có bản quyền.
- robots.txt hiện cho phép User-agent: * (không Disallow cụ thể) — vẫn nên gửi
  User-Agent rõ ràng, giới hạn tần suất, ưu tiên xin API/hợp tác nếu dùng thương mại.
- Chỉ dùng cho nghiên cứu / prototype; không thay nguồn chính thức BYT/DAV.

Chạy:
  python crawl_thuocbietduoc_sample.py --pages 1
  python crawl_thuocbietduoc_sample.py --pages 1 --chi-tiet
  python crawl_thuocbietduoc_sample.py --page-from 2 --page-to 100 --chi-tiet
  python crawl_thuocbietduoc_sample.py --page-from 2 --pages 100 --chi-tiet
  # Ghi mặc định: data/thuocbietduoc_export_<pages>.json (vd. --pages 1 → ..._1.json)
  python crawl_thuocbietduoc_sample.py --pages 1 --chi-tiet --limit 3 --delay 1.5 -o /tmp/out.json
"""

from __future__ import annotations

import argparse
import html as html_module
import json
import re
import sys
import time
from html.parser import HTMLParser
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

_SCRIPT_DIR = Path(__file__).resolve().parent


def default_export_path(page_from: int, page_to: int) -> Path:
    """Tên file mặc định theo khoảng trang drgsearch."""
    if page_from == 1 and page_to == 1:
        return _SCRIPT_DIR / "data" / "thuocbietduoc_export_1.json"
    return _SCRIPT_DIR / "data" / f"thuocbietduoc_export_p{page_from}_p{page_to}.json"


BASE = "https://thuocbietduoc.com.vn"
LIST_PATH = "/thuoc/drgsearch.aspx"

CARD_SPLIT = re.compile(r'<div class="bg-white rounded-xl shadow-md')
URL_RE = re.compile(
    r'href="(https://thuocbietduoc\.com\.vn/thuoc-(\d+)/([^"]+\.aspx))"'
)
TITLE_RE = re.compile(r'class="drug-card-title[^"]*"[^>]*>\s*([^<]+?)\s*</a>')
REG_RE = re.compile(
    r'fa-certificate[^<]*</i>\s*<span[^>]*class="truncate"[^>]*>([^<]+)</span>'
)
FORM_RE = re.compile(
    r'fa-capsules[^<]*</i>\s*<span[^>]*class="truncate"[^>]*>([^<]+)</span>'
)

LD_JSON_RE = re.compile(
    r'<script type="application/ld\+json">\s*(\{[\s\S]*?\})\s*</script>',
    re.IGNORECASE,
)
CANONICAL_RE = re.compile(
    r'<link[^>]+rel="canonical"[^>]+href="([^"]+)"',
    re.IGNORECASE,
)
MAIN_IMG_RE = re.compile(
    r'<img[^>]*id="mainImage"[^>]*src="([^"]+)"',
    re.IGNORECASE,
)

# Các khối nội dung dài (theo id div trên trang chi tiết)
PROSE_SECTION_IDS = (
    "cong-dung-thuoc",
    "duoc-luc",
    "duoc-dong-hoc",
    "tac-dung",
    "chi-dinh",
    "lieu-luong-cach-dung",
    "chong-chi-dinh",
    "tuong-tac-thuoc",
    "tac-dung-phu",
    "than-trong-luc-dung",
    "bao-quan",
)


class _StripTags(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self._chunks: list[str] = []

    def handle_data(self, data: str) -> None:
        t = data.strip()
        if t:
            self._chunks.append(t)

    def text(self) -> str:
        return " ".join(self._chunks)


def text_from_html(fragment: str) -> str:
    p = _StripTags()
    try:
        p.feed(fragment)
        p.close()
    except Exception:
        return re.sub(r"<[^>]+>", " ", fragment)
    return html_module.unescape(p.text())


def fetch(url: str, delay_s: float, *, timeout_sec: float = 45.0) -> str:
    if delay_s > 0:
        time.sleep(delay_s)
    req = Request(
        url,
        headers={
            "User-Agent": "MedIntel-NCKH-research/1.0 (+local; respectful crawl)",
            "Accept-Language": "vi,en;q=0.8",
        },
    )
    with urlopen(req, timeout=timeout_sec) as r:
        return r.read().decode("utf-8", errors="replace")


def parse_list_page(html: str) -> list[dict]:
    chunks = CARD_SPLIT.split(html)[1:]
    out: list[dict] = []
    seen: set[int] = set()
    for chunk in chunks:
        m_url = URL_RE.search(chunk)
        if not m_url:
            continue
        full_url, sid, slug = m_url.group(1), m_url.group(2), m_url.group(3)
        drug_id = int(sid)
        if drug_id in seen:
            continue
        seen.add(drug_id)
        m_title = TITLE_RE.search(chunk)
        title = (m_title.group(1).strip() if m_title else "")
        m_reg = REG_RE.search(chunk)
        reg = m_reg.group(1).strip() if m_reg else None
        m_form = FORM_RE.search(chunk)
        form = m_form.group(1).strip() if m_form else None
        out.append(
            {
                "id": drug_id,
                "ten": title,
                "so_dang_ky": reg,
                "dang_bao_che": form,
                "url": full_url,
                "slug": slug,
            }
        )
    return out


def _parse_ld_product(html: str) -> dict | None:
    for m in LD_JSON_RE.finditer(html):
        raw = m.group(1).strip()
        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            continue
        if data.get("@type") == "Product":
            return data
    return None


def _extract_first_prose_inner(html: str, from_pos: int, max_scan: int = 20000) -> str | None:
    window = html[from_pos : from_pos + max_scan]
    m = re.search(r'<div class="prose w-full[^"]*"[^>]*>', window)
    if not m:
        return None
    open_end = from_pos + m.end()
    i = open_end
    depth = 1
    n = len(html)
    while i < n and depth > 0 and i < open_end + max_scan:
        if html.startswith("<div", i):
            depth += 1
            gt = html.find(">", i)
            if gt == -1:
                break
            i = gt + 1
        elif html.startswith("</div>", i):
            depth -= 1
            i += 6
        else:
            i += 1
    if depth != 0:
        return None
    return html[open_end : i - 6]


def _prose_text_after_id(html: str, elem_id: str) -> str | None:
    needle = f'id="{elem_id}"'
    pos = html.find(needle)
    if pos == -1:
        return None
    inner = _extract_first_prose_inner(html, pos)
    if inner is None:
        return None
    t = text_from_html(inner).strip()
    return t.replace("\r\n", "\n").replace("\r", "\n")


def _parse_quick_info(html: str) -> dict[str, str]:
    start = html.find("Thông tin nhanh")
    if start == -1:
        return {}
    window = html[start : start + 6000]
    out: dict[str, str] = {}
    for m in re.finditer(
        r'<div class="text-xs text-gray-600">([^<]+)</div>\s*'
        r'<div class="font-semibold text-gray-900">([^<]+)</div>',
        window,
    ):
        k = m.group(1).strip()
        v = m.group(2).strip()
        out[k] = v
    for m in re.finditer(
        r'<div class="text-xs text-gray-600">([^<]+)</div>\s*'
        r'<a[^>]*class="[^"]*font-semibold[^"]*"[^>]*>\s*([^<]+?)\s*</a>',
        window,
    ):
        k = m.group(1).strip()
        v = html_module.unescape(re.sub(r"\s+", " ", m.group(2)).strip())
        out[k] = v
    return out


def _parse_h1(html: str) -> str | None:
    m = re.search(
        r'<h1 class="font-bold[^"]*text-gray-900[^"]*"[^>]*>([^<]+)</h1>',
        html,
    )
    return m.group(1).strip() if m else None


def _parse_ingredient_snippet(html: str) -> str | None:
    m = re.search(
        r'class="ingredient-content[^"]*"[^>]*>([\s\S]*?)</div>',
        html,
    )
    if not m:
        return None
    return text_from_html(m.group(1)).strip()


def _parse_quy_cach(html: str) -> str | None:
    m = re.search(
        r"Quy cách đóng gói</span>\s*"
        r'<span class="text-base font-bold text-gray-900">([^<]+)</span>',
        html,
    )
    return m.group(1).strip() if m else None


def _parse_active_ingredient_table(html: str) -> list[dict[str, str]]:
    """Parse từng <tr> trong tbody bảng hoạt chất; tránh regex hay gây treo CPU (ReDoS)."""
    block_start = html.find("Thành phần hoạt chất")
    if block_start == -1:
        return []
    window = html[block_start : block_start + 8000]
    t0 = window.find("<tbody>")
    t1 = window.find("</tbody>", t0)
    if t0 == -1 or t1 == -1 or t1 <= t0:
        return []
    tbody = window[t0:t1]
    rows: list[dict[str, str]] = []
    name_re = re.compile(
        r'thuoc-goc[^"]*\.aspx"[^>]*>\s*([^<]+?)\s*(?:<span[^>]*>Chính</span>)?\s*</a>',
        re.I,
    )
    dose_re = re.compile(
        r'<span class="text-base font-bold text-gray-900">([^<]+)</span>',
    )
    for part in tbody.split("<tr"):
        if "thuoc-goc" not in part:
            continue
        nm = name_re.search(part)
        dm = dose_re.search(part)
        if nm and dm:
            rows.append(
                {
                    "ten_hoat_chat": html_module.unescape(nm.group(1).strip()),
                    "ham_luong": dm.group(1).strip(),
                }
            )
    return rows


def _parse_companies(html: str) -> list[dict[str, str]]:
    start = html.find("Thông tin công ty")
    if start == -1:
        return []
    window = html[start : start + 12000]
    companies: list[dict[str, str]] = []
    needle = 'href="https://thuocbietduoc.com.vn/nha-san-xuat/'
    pos = 0
    seen_url: set[str] = set()
    while True:
        i = window.find(needle, pos)
        if i == -1:
            break
        a_open = window.rfind("<a", 0, i + 1)
        if a_open == -1:
            pos = i + len(needle)
            continue
        block = window[a_open : a_open + 1600]
        url_m = re.search(
            r'href="(https://thuocbietduoc\.com\.vn/nha-san-xuat/[^"]+)"',
            block,
        )
        if not url_m:
            pos = i + len(needle)
            continue
        url = url_m.group(1)
        if url in seen_url:
            pos = i + len(needle)
            continue
        seen_url.add(url)
        gt = block.find(">")
        if gt == -1:
            pos = i + len(needle)
            continue
        a_close = block.find("</a>", gt)
        if a_close == -1:
            pos = i + len(needle)
            continue
        name_html = block[gt + 1 : a_close]
        badges_start = block.find('<div class="flex flex-wrap gap-1 mt-2">', a_close)
        badges_html = ""
        if badges_start != -1:
            b0 = badges_start + len('<div class="flex flex-wrap gap-1 mt-2">')
            b1 = block.find("</div>", b0)
            if b1 != -1:
                badges_html = block[b0:b1]
        name = text_from_html(name_html).strip()
        name = re.sub(r"\s*-\s*[A-Z]{2,}\s*$", "", name).strip()
        roles: list[str] = []
        for bm in re.finditer(
            r'rounded-full"[^>]*>\s*<i[^>]*></i>\s*([^<]+)</span>',
            badges_html,
        ):
            t = bm.group(1).strip()
            if t in ("Sản xuất", "Đăng ký", "Phân phối"):
                roles.append(t)
        qg_m = re.search(
            r'<span class="text-xs text-gray-600 font-normal">\s*-\s*([^<]+)</span>',
            name_html,
        )
        companies.append(
            {
                "ten": name,
                "url": url,
                "vai_tro": ", ".join(roles) if roles else "",
                "quoc_gia": qg_m.group(1).strip() if qg_m else "",
            }
        )
        pos = i + len(needle)
    return companies


def _parse_h2_clinical_sections(html: str) -> dict[str, str]:
    """Các mục Chỉ định / Chống chỉ định / ... trong khối prose đầu (id section-1..)."""
    start = html.find('<h2 id="section-1"')
    if start == -1:
        return {}
    end = html.find('id="cong-dung-thuoc"', start)
    if end == -1:
        window = html[start : start + 15000]
    else:
        window = html[start:end]
    sections: dict[str, str] = {}
    parts = re.split(r'(<h2 id="section-\d+"[^>]*>[^<]+</h2>)', window)
    current_title = None
    for part in parts:
        hm = re.match(r'<h2 id="section-(\d+)"[^>]*>([^<]+)</h2>', part)
        if hm:
            current_title = html_module.unescape(hm.group(2).strip())
            continue
        if current_title and part.strip():
            sections[current_title] = text_from_html(part).strip()
    return sections


def parse_detail_page(html: str) -> dict:
    ld = _parse_ld_product(html)
    canonical_m = CANONICAL_RE.search(html)
    img_m = MAIN_IMG_RE.search(html)

    chi_tiet: dict = {
        "url_chuan": canonical_m.group(1) if canonical_m else None,
        "anh_chinh": img_m.group(1) if img_m else None,
        "ten_trang": _parse_h1(html),
        "schema_org_product": None,
        "thong_tin_nhanh": _parse_quick_info(html),
        "thanh_phan_ngan": _parse_ingredient_snippet(html),
        "quy_cach_dong_goi": _parse_quy_cach(html),
        "bang_hoat_chat": _parse_active_ingredient_table(html),
        "cong_ty": _parse_companies(html),
        "muc_lam_sang_html_ngan": _parse_h2_clinical_sections(html),
        "cac_phan_bo_sung": {},
    }

    if ld:
        chi_tiet["schema_org_product"] = {
            "ten": ld.get("name"),
            "mo_ta_ngan": html_module.unescape(ld.get("description") or "")
            if ld.get("description")
            else None,
            "thuong_hieu": (ld.get("brand") or {}).get("name")
            if isinstance(ld.get("brand"), dict)
            else None,
            "sku_so_dang_ky": ld.get("sku"),
            "danh_muc": ld.get("category"),
            "hinh_anh": ld.get("image"),
            "gia_goi_y": (ld.get("offers") or {}).get("price")
            if isinstance(ld.get("offers"), dict)
            else None,
            "don_vi_tien": (ld.get("offers") or {}).get("priceCurrency")
            if isinstance(ld.get("offers"), dict)
            else None,
        }

    extra: dict[str, str] = {}
    for sid in PROSE_SECTION_IDS:
        t = _prose_text_after_id(html, sid)
        if t:
            extra[sid.replace("-", "_")] = t
    chi_tiet["cac_phan_bo_sung"] = extra

    return chi_tiet


def main() -> None:
    p = argparse.ArgumentParser(description="Cào mẫu danh sách + chi tiết thuốc Thuốc Biệt Dược.")
    p.add_argument(
        "--pages",
        type=int,
        default=1,
        help="Trang kết thúc drgsearch khi không dùng --page-to (cào page-from .. pages). Mặc định với --page-from=1: trang 1..N.",
    )
    p.add_argument(
        "--page-from",
        type=int,
        default=1,
        metavar="N",
        help="Trang danh sách bắt đầu (>=1).",
    )
    p.add_argument(
        "--page-to",
        type=int,
        default=None,
        metavar="N",
        help="Trang danh sách kết thúc (>= page-from). Nếu bỏ trống, dùng giá trị --pages làm trang cuối.",
    )
    p.add_argument(
        "--delay",
        type=float,
        default=1.0,
        help="Giây nghỉ giữa mỗi request (mặc định 1).",
    )
    p.add_argument(
        "--chi-tiet",
        action="store_true",
        help="Tải từng URL thuốc và gắn trường chi_tiet_day_du.",
    )
    p.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Giới hạn số thuốc sau khi gom trang (0 = không giới hạn).",
    )
    p.add_argument(
        "-o",
        "--output",
        type=Path,
        default=None,
        help="Đường dẫn file JSON đầu ra.",
    )
    p.add_argument(
        "--stdout",
        action="store_true",
        help="Với --chi-tiet: in JSON ra stdout thay vì ghi file mặc định.",
    )
    p.add_argument(
        "--timeout",
        type=float,
        default=45.0,
        help="Timeout HTTP mỗi request (giây). Giảm nếu treo lâu ở recv (mặc định 45).",
    )
    args = p.parse_args()
    page_from = max(1, args.page_from)
    page_to = args.page_to if args.page_to is not None else args.pages
    if page_to < page_from:
        raise SystemExit(f"--page-to ({page_to}) phải >= --page-from ({page_from}).")

    all_rows: list[dict] = []
    export_ngat_som = False
    try:
        for i, page in enumerate(range(page_from, page_to + 1)):
            q = f"{BASE}{LIST_PATH}" if page == 1 else f"{BASE}{LIST_PATH}?page={page}"
            print(f"[danh sách trang {page}/{page_to}] {q}", file=sys.stderr, flush=True)
            try:
                html = fetch(
                    q,
                    delay_s=args.delay if (page > 1 or i > 0) else 0,
                    timeout_sec=args.timeout,
                )
            except (HTTPError, URLError, TimeoutError, OSError) as e:
                raise SystemExit(f"Lỗi tải {q}: {e}") from e
            rows = parse_list_page(html)
            if not rows:
                raise SystemExit(f"Không parse được thuốc nào từ {q} (có thể đổi HTML).")
            all_rows.extend(rows)
    except KeyboardInterrupt:
        export_ngat_som = True
        print(
            "\nĐã nhận Ctrl+C khi tải trang danh sách — dừng, giữ các trang đã gom được.",
            file=sys.stderr,
            flush=True,
        )

    if args.limit and args.limit > 0:
        all_rows = all_rows[: args.limit]

    if args.chi_tiet:
        n = len(all_rows)
        try:
            for i, row in enumerate(all_rows):
                label = row.get("ten") or row.get("url", "")
                print(
                    f"[chi tiết {i + 1}/{n}] {label}",
                    file=sys.stderr,
                    flush=True,
                )
                dly = args.delay if i > 0 else 0
                try:
                    dhtml = fetch(
                        row["url"],
                        delay_s=dly,
                        timeout_sec=args.timeout,
                    )
                except (HTTPError, URLError, TimeoutError, OSError) as e:
                    row["chi_tiet_day_du"] = {"loi": str(e)}
                    continue
                row["chi_tiet_day_du"] = parse_detail_page(dhtml)
        except KeyboardInterrupt:
            export_ngat_som = True
            print(
                "\nĐã nhận Ctrl+C — ghi JSON với phần đã tải (có thể thiếu chi tiết một số thuốc).",
                file=sys.stderr,
                flush=True,
            )

    payload: dict = {"thuoc": all_rows}
    if export_ngat_som:
        payload["_meta"] = {
            "export_bi_ngat_som": True,
            "ly_do": "KeyboardInterrupt",
        }

    text = json.dumps(payload, ensure_ascii=False, indent=2)

    write_path: Path | None = args.output
    if args.chi_tiet and write_path is None and not args.stdout:
        write_path = default_export_path(page_from, page_to)
    elif not args.chi_tiet:
        write_path = args.output

    if write_path is not None:
        write_path.parent.mkdir(parents=True, exist_ok=True)
        write_path.write_text(text, encoding="utf-8")
        print(f"Đã ghi: {write_path.resolve()}", flush=True)

    if args.stdout or write_path is None:
        print(text)


if __name__ == "__main__":
    main()
