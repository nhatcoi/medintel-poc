"""Drug JSON -> clinical section chunks for RAG ingestion."""

from __future__ import annotations

from dataclasses import dataclass

SECTION_LABELS = {
    "thanh_phan": "Thanh phan",
    "chi_dinh": "Chi dinh",
    "lieu_dung": "Lieu dung - Cach dung",
    "chong_chi_dinh": "Chong chi dinh",
    "tac_dung_phu": "Tac dung phu",
    "tuong_tac": "Tuong tac thuoc",
    "bao_quan": "Bao quan",
    "qua_lieu": "Qua lieu",
    "than_trong": "Than trong",
    "phu_nu_co_thai": "Phu nu co thai va cho con bu",
    "duoc_dong_hoc": "Duoc dong hoc",
    "duoc_luc_hoc": "Duoc luc hoc",
}


@dataclass
class DrugChunk:
    section: str
    content: str
    ordinal: int


def chunk_drug(raw_doc: dict, drug_name: str = "") -> list[DrugChunk]:
    """Split a crawled drug JSON into clinical section chunks."""
    chunks: list[DrugChunk] = []
    ordinal = 0

    for key, label in SECTION_LABELS.items():
        text = raw_doc.get(key, "")
        if not text or not str(text).strip():
            continue
        body = f"[{drug_name}] {label}:\n{str(text).strip()}"
        chunks.append(DrugChunk(section=key, content=body, ordinal=ordinal))
        ordinal += 1

    if not chunks:
        full = str(raw_doc.get("full_text", raw_doc.get("body", "")))
        if full.strip():
            chunks.append(DrugChunk(section="body", content=full.strip(), ordinal=0))

    return chunks
