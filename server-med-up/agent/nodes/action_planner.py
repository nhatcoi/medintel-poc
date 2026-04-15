"""Action planner node -- sinh suggested_actions theo intent.

Chạy giữa `safety_guard` và `response_composer`. Các bước:
  1. Thu thập facts từ state (meds, adherence, risk, tool_calls, entity drug).
  2. Lookup ACTION_MAP theo `current_intent` (fallback DEFAULT_ACTIONS).
  3. Render placeholder + filter theo `requires`.
  4. Augment: follow-up chain, boost theo risk/hành vi.
  5. Low-confidence -> action hỏi lại thay vì gợi ý linh tinh.

Trả tối đa MAX_ACTIONS action, sort theo priority desc.
"""

from __future__ import annotations

import logging
from typing import Any

from langchain_core.messages import HumanMessage

from agent.actions import ACTION_MAP, DEFAULT_ACTIONS, FOLLOW_UP_CHAIN
from agent.intents.definitions import Intent
from agent.state import PatientState

_log = logging.getLogger("medintel.agent.action_planner")

MAX_ACTIONS = 3
LOW_CONFIDENCE_THRESHOLD = 0.45

_PLACEHOLDER_KEYS = ("drug", "next_drug", "entity_drug", "profile_name")


# ---------------------------------------------------------------------------
# Facts
# ---------------------------------------------------------------------------
def _last_user_text(state: PatientState) -> str:
    for msg in reversed(state.get("messages") or []):
        if isinstance(msg, HumanMessage):
            return (msg.content or "").strip()
    return ""


def _resolve_entity_drug(state: PatientState) -> str:
    entities = state.get("entities") or {}
    if isinstance(entities, dict):
        name = entities.get("drug") or entities.get("medication")
        if name:
            return str(name).strip()
    rag = state.get("rag_results") or []
    if rag and rag[0].get("drug"):
        return str(rag[0]["drug"]).strip()
    txt = _last_user_text(state)
    return txt[:80] if txt else ""


def _collect_facts(state: PatientState) -> dict[str, Any]:
    meds = state.get("medications") or []
    adherence = state.get("adherence_summary") or {}
    tool_calls = state.get("tool_calls") or []
    rag = state.get("rag_results") or []

    missed_7d = adherence.get("missed_last_7d", 0) if isinstance(adherence, dict) else 0
    has_major = any(
        "major" in (r.get("content") or "").lower()
        and (r.get("section") or "").lower() in {"interactions", "tuong_tac"}
        for r in rag
    )

    drug = meds[0].get("name") if meds else ""
    next_drug = meds[1].get("name") if len(meds) >= 2 else ""

    entity_drug = _resolve_entity_drug(state)
    cabinet = {str(m.get("name", "")).strip().lower() for m in meds}
    entity_in_cabinet = entity_drug.lower() in cabinet if entity_drug else False

    return {
        "has_meds": bool(meds),
        "has_two_meds": len(meds) >= 2,
        "missed_7d": missed_7d,
        "has_major_interaction": has_major,
        "just_logged_dose": any(tc.get("tool") == "log_dose" for tc in tool_calls),
        "risk_level": state.get("risk_level", "low"),
        "intent_confidence": float(state.get("intent_confidence") or 1.0),
        "drug": drug or "thuốc",
        "next_drug": next_drug or "thuốc khác",
        "entity_drug": entity_drug,
        "has_entity_drug": bool(entity_drug),
        "entity_drug_not_in_cabinet": bool(entity_drug) and not entity_in_cabinet,
        "profile_name": (state.get("patient_info") or {}).get("name", "bạn"),
    }


# ---------------------------------------------------------------------------
# Template render & filter
# ---------------------------------------------------------------------------
def _render(template: dict, facts: dict[str, Any]) -> dict:
    fmt_kwargs = {k: (facts.get(k) or facts.get("drug", "") if k == "entity_drug" else facts.get(k, ""))
                  for k in _PLACEHOLDER_KEYS}

    def _fmt(v: Any) -> Any:
        if isinstance(v, str):
            return v.format(**fmt_kwargs)
        if isinstance(v, dict):
            return {k: _fmt(x) for k, x in v.items()}
        return v

    out = dict(template)
    for key in ("label", "prompt", "route"):
        if isinstance(out.get(key), str):
            out[key] = _fmt(out[key])
    if isinstance(out.get("tool_args"), dict):
        out["tool_args"] = _fmt(out["tool_args"])
    return out


def _passes(template: dict, facts: dict[str, Any]) -> bool:
    return all(facts.get(req) for req in (template.get("requires") or []))


def _to_output(action: dict) -> dict:
    out = {
        "label": action.get("label", ""),
        "prompt": action.get("prompt") or action.get("label", ""),
        "category": action.get("category", "other"),
    }
    for k in ("type", "route", "tool", "tool_args", "priority"):
        if action.get(k) not in (None, ""):
            out[k] = action[k]
    return out


def _dedupe(actions: list[dict]) -> list[dict]:
    seen: set[str] = set()
    out: list[dict] = []
    for a in actions:
        key = (a.get("label") or "") + "|" + (a.get("tool") or a.get("route") or a.get("prompt") or "")
        if key in seen:
            continue
        seen.add(key)
        out.append(a)
    return out


# ---------------------------------------------------------------------------
# Augment rules
# ---------------------------------------------------------------------------
def _clarify_actions() -> list[dict]:
    mk = lambda lbl, pr, p: {"label": lbl, "prompt": p, "category": "clarify", "priority": pr}
    return [
        mk("Bạn đang hỏi về lịch uống?", 80, "Tôi muốn hỏi về lịch uống thuốc hôm nay"),
        mk("Bạn đang hỏi về tác dụng phụ?", 75, "Tôi muốn hỏi về tác dụng phụ của thuốc đang dùng"),
        mk("Bạn đang hỏi về tương tác?", 70, "Tôi muốn hỏi về tương tác giữa các thuốc tôi đang dùng"),
    ]


def _augment(candidates: list[dict], facts: dict[str, Any]) -> list[dict]:
    if facts["just_logged_dose"]:
        candidates.append({
            "label": "Ghi chú triệu chứng kèm theo", "category": "report",
            "prompt": "Tôi muốn ghi chú triệu chứng sau khi uống thuốc",
            "type": "tool", "tool": "append_care_note", "priority": 75,
        })
    if facts["missed_7d"] >= 3:
        candidates.append({
            "label": f"Bạn đã quên {facts['missed_7d']} liều tuần qua - mẹo tuân thủ",
            "prompt": "Cho tôi vài mẹo để nhớ uống thuốc đều hơn",
            "category": "tips", "priority": 85,
        })
    if facts["has_major_interaction"]:
        candidates.insert(0, {
            "label": "⚠️ Tương tác MAJOR - Liên hệ dược sĩ",
            "prompt": "Tôi muốn liên hệ dược sĩ/bác sĩ ngay",
            "category": "emergency", "type": "escalate", "priority": 100,
        })
    if facts["risk_level"] == "high":
        candidates.insert(0, {
            "label": "GỌI 115 / CẤP CỨU", "prompt": "Tôi cần cấp cứu",
            "category": "emergency", "type": "escalate", "priority": 100,
        })
    return candidates


# ---------------------------------------------------------------------------
# Node entry
# ---------------------------------------------------------------------------
async def action_planner(state: PatientState) -> dict:
    intent = state.get("current_intent") or Intent.UNKNOWN.value
    facts = _collect_facts(state)

    if facts["intent_confidence"] < LOW_CONFIDENCE_THRESHOLD:
        actions = [_to_output(a) for a in _clarify_actions()][:MAX_ACTIONS]
        return {"suggested_actions": actions}

    templates = ACTION_MAP.get(intent, DEFAULT_ACTIONS)
    candidates = [_render(t, facts) for t in templates if _passes(t, facts)]

    # Follow-up chain: lấy 1 action đầu tiên của intent kế tiếp (priority - 20).
    for follow in FOLLOW_UP_CHAIN.get(intent, [])[:1]:
        for t in ACTION_MAP.get(follow, [])[:1]:
            if _passes(t, facts):
                f = _render(t, facts)
                f["priority"] = max(0, f.get("priority", 50) - 20)
                f.setdefault("category", "follow_up")
                candidates.append(f)

    candidates = _augment(candidates, facts)
    candidates.sort(key=lambda a: a.get("priority", 50), reverse=True)
    candidates = _dedupe(candidates)[:MAX_ACTIONS]

    actions = [_to_output(a) for a in candidates]
    _log.info(
        "ACTION_PLANNER intent=%s risk=%s n=%d labels=%s",
        intent, facts["risk_level"], len(actions),
        [a["label"] for a in actions],
    )
    return {"suggested_actions": actions}
