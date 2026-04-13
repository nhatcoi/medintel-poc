"""Node 6: Safety guardrail -- risk triage based on intent and confidence."""

from __future__ import annotations

from agent.intents.definitions import Intent
from agent.state import PatientState

_HIGH_RISK_INTENTS = frozenset({
    Intent.OVERDOSE_GUIDANCE.value,
    Intent.EMERGENCY_SYMPTOM.value,
    Intent.POISONING_GUIDANCE.value,
    Intent.SERIOUS_SIDE_EFFECT_ALERT.value,
    Intent.ALLERGIC_REACTION_GUIDANCE.value,
})

_MEDIUM_RISK_INTENTS = frozenset({
    Intent.ADJUST_DOSE.value,
    Intent.CAN_STOP_EARLY.value,
    Intent.DRUG_DRUG_INTERACTION.value,
    Intent.CONTRAINDICATION_CHECK.value,
    Intent.PREGNANCY_LACTATION_SAFE.value,
})


async def safety_guard(state: PatientState) -> dict:
    intent = state.get("current_intent", "")

    if intent in _HIGH_RISK_INTENTS:
        return {
            "risk_level": "high",
            "needs_human_review": True,
        }

    if intent in _MEDIUM_RISK_INTENTS:
        return {
            "risk_level": "medium",
            "needs_human_review": False,
        }

    return {
        "risk_level": "low",
        "needs_human_review": False,
    }
