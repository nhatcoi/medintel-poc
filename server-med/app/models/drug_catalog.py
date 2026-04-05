"""Tham chiếu dược (countries, drug_groups, pharmaceutical_companies) — catalog DAV/national_drugs đã gỡ."""

from __future__ import annotations

import uuid

from sqlalchemy import Boolean, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

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
