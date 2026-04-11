"""API báo cáo tuân thủ."""

from __future__ import annotations

import uuid
from datetime import date, timedelta

from fastapi import APIRouter, HTTPException, Query
from sqlalchemy import func, select

from app.api.deps import DbSession
from app.models.reporting import ComplianceReport
from app.models.treatment_medication import MedicationLog
from app.models.mixins import utc_now
from app.schemas.reports import ComplianceReportCreate, ComplianceReportListResponse, ComplianceReportRead

router = APIRouter()


@router.get("", response_model=ComplianceReportListResponse)
def list_reports(db: DbSession, profile_id: uuid.UUID = Query(...), limit: int = Query(20, le=100)):
    rows = db.scalars(
        select(ComplianceReport)
        .where(ComplianceReport.profile_id == profile_id)
        .order_by(ComplianceReport.period_end.desc())
        .limit(limit)
    ).all()
    items = [
        ComplianceReportRead(
            report_id=r.id,
            profile_id=r.profile_id,
            report_type=r.report_type,
            period_start=r.period_start,
            period_end=r.period_end,
            total_scheduled=r.total_scheduled,
            total_completed=r.total_completed,
            total_missed=r.total_missed,
            total_skipped=r.total_skipped,
            compliance_rate=float(r.compliance_rate) if r.compliance_rate is not None else None,
            generated_at=r.generated_at,
        )
        for r in rows
    ]
    return ComplianceReportListResponse(profile_id=profile_id, items=items)


@router.post("/generate", response_model=ComplianceReportRead, status_code=201)
def generate_report(body: ComplianceReportCreate, db: DbSession):
    """Tính toán và tạo báo cáo tuân thủ cho khoảng thời gian chỉ định."""
    from datetime import datetime, timezone

    start_dt = datetime(body.period_start.year, body.period_start.month, body.period_start.day, tzinfo=timezone.utc)
    end_dt = datetime(body.period_end.year, body.period_end.month, body.period_end.day, 23, 59, 59, tzinfo=timezone.utc)

    logs = db.scalars(
        select(MedicationLog).where(
            MedicationLog.profile_id == body.profile_id,
            MedicationLog.scheduled_datetime >= start_dt,
            MedicationLog.scheduled_datetime <= end_dt,
        )
    ).all()

    total = len(logs)
    taken = sum(1 for l in logs if l.status == "taken")
    missed = sum(1 for l in logs if l.status == "missed")
    skipped = sum(1 for l in logs if l.status == "skipped")
    rate = round(taken / total * 100, 2) if total > 0 else 0.0

    report = ComplianceReport(
        profile_id=body.profile_id,
        report_type=body.report_type,
        period_start=body.period_start,
        period_end=body.period_end,
        total_scheduled=total,
        total_completed=taken,
        total_missed=missed,
        total_skipped=skipped,
        compliance_rate=rate,
    )
    db.add(report)
    db.commit()
    db.refresh(report)
    return ComplianceReportRead(
        report_id=report.id,
        profile_id=report.profile_id,
        report_type=report.report_type,
        period_start=report.period_start,
        period_end=report.period_end,
        total_scheduled=report.total_scheduled,
        total_completed=report.total_completed,
        total_missed=report.total_missed,
        total_skipped=report.total_skipped,
        compliance_rate=float(report.compliance_rate) if report.compliance_rate is not None else None,
        generated_at=report.generated_at,
    )


@router.delete("/{report_id}", status_code=204)
def delete_report(report_id: uuid.UUID, db: DbSession):
    r = db.get(ComplianceReport, report_id)
    if not r:
        raise HTTPException(404, "Không tìm thấy báo cáo")
    db.delete(r)
    db.commit()
