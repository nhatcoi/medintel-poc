"""Schema: compliance reports."""

from __future__ import annotations

import uuid
from datetime import date, datetime

from pydantic import BaseModel, Field


class ComplianceReportCreate(BaseModel):
    profile_id: uuid.UUID
    report_type: str = "weekly"
    period_start: date
    period_end: date


class ComplianceReportRead(BaseModel):
    report_id: uuid.UUID
    profile_id: uuid.UUID | None = None
    report_type: str
    period_start: date
    period_end: date
    total_scheduled: int | None = None
    total_completed: int | None = None
    total_missed: int | None = None
    total_skipped: int | None = None
    compliance_rate: float | None = None
    generated_at: datetime

    model_config = {"from_attributes": True}


class ComplianceReportListResponse(BaseModel):
    profile_id: uuid.UUID
    items: list[ComplianceReportRead] = Field(default_factory=list)
