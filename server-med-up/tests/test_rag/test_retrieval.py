"""Tests for RAG chunker."""

from rag.chunker import chunk_drug


def test_chunk_drug_basic():
    doc = {
        "thanh_phan": "Paracetamol 500mg",
        "chi_dinh": "Ha sot, giam dau",
        "lieu_dung": "1-2 vien/lan, 3-4 lan/ngay",
    }
    chunks = chunk_drug(doc, drug_name="Paracetamol")
    assert len(chunks) == 3
    assert chunks[0].section == "thanh_phan"
    assert "Paracetamol" in chunks[0].content


def test_chunk_drug_empty():
    chunks = chunk_drug({})
    assert len(chunks) == 0
