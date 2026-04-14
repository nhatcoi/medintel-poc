"""Tests for action_planner node."""

import asyncio

from agent.nodes.action_planner import action_planner


def _run(state: dict) -> dict:
    return asyncio.get_event_loop().run_until_complete(action_planner(state))


def test_emergency_intent_boosts_escalate_to_top():
    state = {
        "current_intent": "overdose_guidance",
        "intent_confidence": 0.95,
        "risk_level": "high",
        "medications": [{"name": "Paracetamol"}],
    }
    out = _run(state)
    actions = out["suggested_actions"]
    assert len(actions) > 0
    assert "115" in actions[0]["label"].upper() or actions[0].get("type") == "escalate"


def test_low_confidence_triggers_clarify():
    state = {
        "current_intent": "unknown",
        "intent_confidence": 0.2,
        "medications": [],
    }
    out = _run(state)
    labels = [a["label"].lower() for a in out["suggested_actions"]]
    assert any("hỏi" in l or "bạn đang" in l for l in labels)


def test_missed_dose_renders_drug_name():
    state = {
        "current_intent": "missed_dose_guidance",
        "intent_confidence": 0.9,
        "medications": [{"name": "Metformin", "dosage": "500mg"}],
    }
    out = _run(state)
    labels = " ".join(a["label"] for a in out["suggested_actions"])
    assert "Metformin" in labels


def test_requires_filters_out_when_no_meds():
    state = {
        "current_intent": "check_med_schedule",
        "intent_confidence": 0.9,
        "medications": [],
    }
    out = _run(state)
    # Action "Đã uống {drug}" yêu cầu has_meds -> không được xuất hiện.
    for a in out["suggested_actions"]:
        assert "Đã uống" not in a["label"]


def test_drug_drug_interaction_needs_two_meds():
    state = {
        "current_intent": "drug_drug_interaction",
        "intent_confidence": 0.9,
        "medications": [{"name": "A"}],  # chỉ 1 thuốc
    }
    out = _run(state)
    # Không có action "Kiểm tra tương tác A & ..." vì cần has_two_meds.
    for a in out["suggested_actions"]:
        assert "Kiểm tra tương tác" not in a["label"]

    state["medications"] = [{"name": "Warfarin"}, {"name": "Aspirin"}]
    out = _run(state)
    labels = " ".join(a["label"] for a in out["suggested_actions"])
    assert "Warfarin" in labels and "Aspirin" in labels


def test_high_missed_count_adds_tips():
    state = {
        "current_intent": "treatment_tracking",
        "intent_confidence": 0.9,
        "medications": [{"name": "Amlodipine"}],
        "adherence_summary": {"missed_last_7d": 4},
    }
    out = _run(state)
    joined = " ".join(a["label"] for a in out["suggested_actions"])
    assert "quên" in joined.lower() or "tuân thủ" in joined.lower()


def test_just_logged_dose_suggests_symptom_note():
    state = {
        "current_intent": "check_med_schedule",
        "intent_confidence": 0.9,
        "medications": [{"name": "Metformin"}],
        "tool_calls": [{"tool": "log_dose", "args": {}}],
    }
    out = _run(state)
    joined = " ".join(a["label"] for a in out["suggested_actions"])
    assert "triệu chứng" in joined.lower() or "ghi chú" in joined.lower()


def test_max_actions_cap():
    state = {
        "current_intent": "greeting",
        "intent_confidence": 0.95,
        "medications": [{"name": "A"}, {"name": "B"}],
    }
    out = _run(state)
    assert len(out["suggested_actions"]) <= 4


def test_output_has_required_fields():
    state = {
        "current_intent": "missed_dose_guidance",
        "intent_confidence": 0.9,
        "medications": [{"name": "Losartan"}],
    }
    out = _run(state)
    for a in out["suggested_actions"]:
        assert "label" in a and a["label"]
        assert "prompt" in a and a["prompt"]
        assert "category" in a
