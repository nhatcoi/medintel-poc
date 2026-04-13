"""Unit tests for individual graph nodes."""

import pytest


def test_intent_rules_greeting():
    from agent.intents.rules import classify_by_rules
    result = classify_by_rules("xin chao")
    assert result is not None
    intent, conf = result
    assert intent.value == "greeting"
    assert conf > 0.8


def test_intent_rules_missed_dose():
    from agent.intents.rules import classify_by_rules
    result = classify_by_rules("toi quen uong thuoc sang nay")
    assert result is not None
    intent, _ = result
    assert intent.value == "missed_dose_guidance"


def test_intent_rules_no_match():
    from agent.intents.rules import classify_by_rules
    result = classify_by_rules("cho toi hoi ve kinh te vi mo")
    assert result is None


def test_safety_guard_high_risk():
    import asyncio
    from agent.nodes.safety_guard import safety_guard

    state = {"current_intent": "overdose_guidance"}
    result = asyncio.get_event_loop().run_until_complete(safety_guard(state))
    assert result["risk_level"] == "high"
    assert result["needs_human_review"] is True


def test_safety_guard_low_risk():
    import asyncio
    from agent.nodes.safety_guard import safety_guard

    state = {"current_intent": "greeting"}
    result = asyncio.get_event_loop().run_until_complete(safety_guard(state))
    assert result["risk_level"] == "low"
