"""ORM models cho bảng tbdf_drugs + tbdf_drug_chunks (pgvector RAG)."""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

import os

from sqlalchemy import (
    Column,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    JSON,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship

from database.session import Base, GUID

try:
    from pgvector.sqlalchemy import Vector
except ImportError:  # pgvector chưa cài — model vẫn import được, chỉ thiếu cột embedding
    Vector = None

# SQLite: JSON + Text embedding; PostgreSQL: JSON + Vector khi có pgvector
_DB_URL = os.environ.get("DATABASE_URL", "").lower()
_USE_PG_VECTOR = "postgresql" in _DB_URL or "postgres" in _DB_URL


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


class TbdfDrug(Base):
    __tablename__ = "tbdf_drugs"

    drug_id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    source_site = Column(Text, nullable=False, default="thuocbietduoc.com.vn")
    external_id = Column(Integer, nullable=False)
    canonical_url = Column(Text, nullable=False)
    slug = Column(Text, nullable=True)
    name_display = Column(Text, nullable=False)
    registration_no = Column(Text, nullable=True)
    dosage_form = Column(Text, nullable=True)
    ingredient_short = Column(Text, nullable=True)
    category = Column(Text, nullable=True)
    raw_document = Column(JSON, nullable=False)
    normalized_text = Column(Text, nullable=True)
    text_sha256 = Column(Text, nullable=True)
    crawled_at = Column(DateTime(timezone=True), nullable=False, default=_utcnow)
    updated_at = Column(DateTime(timezone=True), nullable=False, default=_utcnow, onupdate=_utcnow)

    chunks = relationship("TbdfDrugChunk", back_populates="drug", cascade="all, delete-orphan")

    __table_args__ = (
        UniqueConstraint("source_site", "external_id", name="uq_tbdf_site_ext"),
        Index("idx_tbdf_drugs_reg", "registration_no"),
    )


class TbdfDrugChunk(Base):
    __tablename__ = "tbdf_drug_chunks"

    chunk_id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    drug_id = Column(GUID(), ForeignKey("tbdf_drugs.drug_id", ondelete="CASCADE"), nullable=False)
    chunk_ordinal = Column(Integer, nullable=False)
    section = Column(Text, nullable=False, default="body")
    content = Column(Text, nullable=False)
    token_estimate = Column(Integer, nullable=True)
    embedding_model = Column(Text, nullable=False, default="paraphrase-multilingual-MiniLM-L12-v2")
    embedding = (
        Column(Vector(384))
        if (_USE_PG_VECTOR and Vector is not None)
        else Column(Text, nullable=True)
    )
    created_at = Column(DateTime(timezone=True), nullable=False, default=_utcnow)

    drug = relationship("TbdfDrug", back_populates="chunks")

    __table_args__ = (
        UniqueConstraint("drug_id", "chunk_ordinal", "section", name="uq_tbdf_chunk_place"),
        Index("idx_tbdf_chunks_drug", "drug_id"),
        Index("idx_tbdf_chunks_section", "section"),
    )
