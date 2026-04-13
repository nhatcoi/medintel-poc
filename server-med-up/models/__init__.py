"""ORM models — import theo thu tu FK de metadata dang ky day du."""

from models.profile import Device, Profile  # noqa: F401
from models.agent_context import PatientAgentContext  # noqa: F401
from models.audit import AuditLog  # noqa: F401
from models.catalog import Country, DrugGroup, PharmaceuticalCompany  # noqa: F401
from models.medical import DiseaseCategory, MedicalRecord, TreatmentPeriod  # noqa: F401
from models.medication import Medication, MedicationLog, MedicationSchedule  # noqa: F401
from models.chat import ChatMessage, ChatSession  # noqa: F401
from models.habits import HabitCategory, HabitLog, HabitReminder, HealthHabit  # noqa: F401
from models.care import CaregiverPatientLink, CareGroup, CareGroupMember, CareGroupPatient  # noqa: F401
from models.rag import TbdfDrug, TbdfDrugChunk  # noqa: F401
from models.memory import PatientMemory  # noqa: F401
from models.cache import ResponseCache  # noqa: F401
from models.reporting import ComplianceReport, Notification, SystemConfig, SystemStatistic  # noqa: F401
from models.auth import AuthCredential, AuthSession  # noqa: F401
