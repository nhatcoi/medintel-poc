"""Medication-related tools for the agent."""

from __future__ import annotations

from langchain_core.tools import tool


@tool
def log_dose(medication_name: str, status: str = "taken", note: str = "", recorded_at: str = "") -> str:
    """Ghi nhan mot lieu thuoc (taken/missed/skipped). Client app se dong bo."""
    return f"Da ghi nhan: {medication_name} -> {status}" + (f" ({note})" if note else "")


@tool
def upsert_medication(name: str, dosage_label: str = "", schedule_hint: str = "") -> str:
    """Them hoac cap nhat thuoc trong danh sach benh nhan."""
    return f"Da luu thuoc: {name}" + (f" - {dosage_label}" if dosage_label else "")


@tool
def get_today_medications(profile_id: str) -> str:
    """Lay danh sach thuoc can uong hom nay cua benh nhan."""
    return f"[placeholder] Danh sach thuoc hom nay cho profile {profile_id}"
