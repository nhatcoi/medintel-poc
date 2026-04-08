"""ORM models — import thứ tự phụ thuộc FK (metadata đăng ký đầy đủ cho create_all)."""

from app.models.profile import Device, Profile
from app.models.audit_log import AuditLog
from app.models.drug_catalog import Country, DrugGroup, PharmaceuticalCompany
from app.models.medical import DiseaseCategory, MedicalRecord, TreatmentPeriod
from app.models.treatment_medication import Medication, MedicationLog, MedicationSchedule
from app.models.chat import ChatMessage, ChatSession
from app.models.habits import HabitCategory, HabitLog, HabitReminder, HealthHabit
from app.models.care import CareGroup, CareGroupMember, CareGroupPatient, CaregiverPatientLink
from app.models.rag_drug import TbdfDrug, TbdfDrugChunk
from app.models.patient_memory import PatientMemory
from app.models.response_cache import ResponseCache
from app.models.reporting import ComplianceReport, Notification, SystemConfig, SystemStatistic

__all__ = [
    "Profile",
    "Device",
    "AuditLog",
    "Country",
    "DrugGroup",
    "PharmaceuticalCompany",
    "DiseaseCategory",
    "MedicalRecord",
    "TreatmentPeriod",
    "Medication",
    "MedicationSchedule",
    "MedicationLog",
    "ChatSession",
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
    "TbdfDrug",
    "TbdfDrugChunk",
    "PatientMemory",
    "ResponseCache",
]
