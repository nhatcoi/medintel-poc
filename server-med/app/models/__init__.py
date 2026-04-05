"""ORM models — import thứ tự phụ thuộc FK (metadata đăng ký đầy đủ cho create_all)."""

from app.models.profile import Device, Profile
from app.models.audit_log import AuditLog
from app.models.drug_catalog import (
    Country,
    DosageForm,
    DrugBasicInfo,
    DrugGroup,
    DrugRegistrationInfo,
    NationalDrug,
    PharmaceuticalCompany,
    QualityStandard,
)
from app.models.medical import DiseaseCategory, MedicalRecord, TreatmentPeriod
from app.models.treatment_medication import Medication, MedicationLog, MedicationSchedule
from app.models.chat import ChatMessage
from app.models.habits import HabitCategory, HabitLog, HabitReminder, HealthHabit
from app.models.care import CareGroup, CareGroupMember, CareGroupPatient, CaregiverPatientLink
from app.models.reporting import ComplianceReport, Notification, SystemConfig, SystemStatistic

__all__ = [
    "Profile",
    "Device",
    "AuditLog",
    "Country",
    "DrugGroup",
    "DosageForm",
    "QualityStandard",
    "PharmaceuticalCompany",
    "NationalDrug",
    "DrugBasicInfo",
    "DrugRegistrationInfo",
    "DiseaseCategory",
    "MedicalRecord",
    "TreatmentPeriod",
    "Medication",
    "MedicationSchedule",
    "MedicationLog",
    "ChatMessage",
    "HabitCategory",
    "HealthHabit",
    "HabitReminder",
    "HabitLog",
    "CaregiverPatientLink",
    "CareGroup",
    "CareGroupMember",
    "CareGroupPatient",
    "ComplianceReport",
    "SystemStatistic",
    "Notification",
    "SystemConfig",
]
