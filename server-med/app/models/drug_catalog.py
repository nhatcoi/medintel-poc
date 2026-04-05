"""§2 db-design: national drug catalog (tối thiểu để FK medications hoạt động)."""

from __future__ import annotations

import uuid
from datetime import date

from typing import Any

from sqlalchemy import Boolean, Date, ForeignKey, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database.session import Base, GUID

from app.models.mixins import TimestampMixin


class Country(Base, TimestampMixin):
    __tablename__ = "countries"

    id: Mapped[uuid.UUID] = mapped_column("country_id", GUID, primary_key=True, default=uuid.uuid4)
    country_name: Mapped[str] = mapped_column(String(100), unique=True)
    country_code: Mapped[str | None] = mapped_column(String(10), nullable=True)


class DrugGroup(Base):
    __tablename__ = "drug_groups"

    id: Mapped[int] = mapped_column("group_id", Integer, primary_key=True, autoincrement=True)
    group_code: Mapped[str | None] = mapped_column(String(20), nullable=True)
    group_name: Mapped[str] = mapped_column(String(255))
    parent_group_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("drug_groups.group_id"), nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)


class DosageForm(Base):
    __tablename__ = "dosage_forms"

    id: Mapped[int] = mapped_column("form_id", Integer, primary_key=True, autoincrement=True)
    form_name: Mapped[str] = mapped_column(String(100), unique=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)


class QualityStandard(Base):
    __tablename__ = "quality_standards"

    id: Mapped[int] = mapped_column("standard_id", Integer, primary_key=True, autoincrement=True)
    standard_code: Mapped[str] = mapped_column(String(20), unique=True)
    standard_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)


class PharmaceuticalCompany(Base, TimestampMixin):
    __tablename__ = "pharmaceutical_companies"

    id: Mapped[uuid.UUID] = mapped_column("company_id", GUID, primary_key=True, default=uuid.uuid4)
    company_name: Mapped[str] = mapped_column(String(500))
    address: Mapped[str | None] = mapped_column(Text, nullable=True)
    country_id: Mapped[uuid.UUID | None] = mapped_column(GUID, ForeignKey("countries.country_id"), nullable=True)
    company_type: Mapped[str | None] = mapped_column(String(64), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(50), nullable=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    website: Mapped[str | None] = mapped_column(String(255), nullable=True)
    is_active: Mapped[bool | None] = mapped_column(Boolean, default=True)


class NationalDrug(Base, TimestampMixin):
    __tablename__ = "national_drugs"

    id: Mapped[uuid.UUID] = mapped_column("drug_id", GUID, primary_key=True, default=uuid.uuid4)
    registration_number: Mapped[str | None] = mapped_column(String(50), unique=True, nullable=True)
    old_registration_number: Mapped[str] = mapped_column(String(50), default="")
    drug_name: Mapped[str] = mapped_column(String(255))
    drug_name_no_diacritics: Mapped[str | None] = mapped_column(String(255), nullable=True)
    drug_code: Mapped[str | None] = mapped_column(String(50), nullable=True)
    type_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    group_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("drug_groups.group_id"), nullable=True)
    is_active: Mapped[bool | None] = mapped_column(Boolean, default=True)
    is_expired: Mapped[bool | None] = mapped_column(Boolean, default=False)
    is_permitted: Mapped[bool | None] = mapped_column(Boolean, default=True)
    is_registration_withdrawn: Mapped[bool | None] = mapped_column(Boolean, default=False)
    external_id: Mapped[int | None] = mapped_column(Integer, unique=True, nullable=True)
    # Đồng bộ thêm từ DAV list API (GetAllPublicServerPaging) — phục vụ RAG / agent
    dav_notes: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
        comment="ghiChu từ DAV (thường ghi chú hành chính, không phải SmPC đầy đủ)",
    )
    dav_documents: Mapped[dict[str, Any] | None] = mapped_column(
        JSON,
        nullable=True,
        comment="URL/metadata tài liệu: HDSD, nhãn, TCCL (trích từ thongTinTaiLieu)",
    )

    basic_info: Mapped[DrugBasicInfo | None] = relationship(
        "DrugBasicInfo", back_populates="drug", uselist=False, cascade="all, delete-orphan"
    )


class DrugBasicInfo(Base):
    __tablename__ = "drug_basic_info"

    id: Mapped[uuid.UUID] = mapped_column("info_id", GUID, primary_key=True, default=uuid.uuid4)
    drug_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("national_drugs.drug_id"), unique=True)
    active_ingredient: Mapped[str | None] = mapped_column(Text, nullable=True)
    concentration: Mapped[str | None] = mapped_column(String(255), nullable=True)
    form_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("dosage_forms.form_id"), nullable=True)
    route_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    administration_route_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    drug_type_label: Mapped[str | None] = mapped_column(String(200), nullable=True)
    drug_group_label: Mapped[str | None] = mapped_column(String(255), nullable=True)
    packaging: Mapped[str | None] = mapped_column(Text, nullable=True)
    standard_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("quality_standards.standard_id"), nullable=True)
    shelf_life: Mapped[str | None] = mapped_column(String(50), nullable=True)

    drug: Mapped[NationalDrug] = relationship("NationalDrug", back_populates="basic_info")


class DrugRegistrationInfo(Base):
    __tablename__ = "drug_registration_info"

    id: Mapped[uuid.UUID] = mapped_column("registration_id", GUID, primary_key=True, default=uuid.uuid4)
    drug_id: Mapped[uuid.UUID] = mapped_column(GUID, ForeignKey("national_drugs.drug_id"), index=True)
    registration_issue_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    registration_renewal_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    registration_expiry_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    decision_number: Mapped[str | None] = mapped_column(String(100), nullable=True)
    decision_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    issue_batch: Mapped[str | None] = mapped_column(String(50), nullable=True)
    renewal_application_number: Mapped[str | None] = mapped_column(String(100), nullable=True)
    renewal_application_received: Mapped[date | None] = mapped_column(Date, nullable=True)
    renewal_receipt_url: Mapped[str | None] = mapped_column(Text, nullable=True)
