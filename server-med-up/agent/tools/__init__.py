"""Tool registry: all LangChain tools available to the agent."""

from agent.tools.medication_tools import log_dose, upsert_medication, get_today_medications
from agent.tools.care_tools import append_care_note
from agent.tools.reminder_tools import save_reminder_intent
from agent.tools.memory_tools import update_patient_memory
from agent.tools.drug_kb_tools import search_drug_kb
from agent.tools.interaction_tools import check_drug_interaction
from agent.tools.external_tools import tavily_search

ALL_TOOLS = [
    log_dose,
    upsert_medication,
    get_today_medications,
    append_care_note,
    save_reminder_intent,
    update_patient_memory,
    search_drug_kb,
    check_drug_interaction,
    tavily_search,
]

TOOL_MAP = {t.name: t for t in ALL_TOOLS}
