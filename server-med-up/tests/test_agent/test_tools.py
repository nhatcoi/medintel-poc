"""Unit tests for LangChain tool definitions."""

import asyncio

from agent.tools.medication_tools import log_dose, append_care_note
from agent.tools.care_tools import append_care_note as care_note
from agent.tools.reminder_tools import save_reminder_intent


def test_log_dose():
    result = log_dose.invoke({"medication_name": "Metformin", "status": "taken"})
    assert "Metformin" in result
    assert "taken" in result


def test_append_care_note():
    result = care_note.invoke({"text": "buon non sau khi uong"})
    assert "buon non" in result


def test_save_reminder():
    result = save_reminder_intent.invoke({"title": "Uong thuoc sang"})
    assert "Uong thuoc sang" in result
