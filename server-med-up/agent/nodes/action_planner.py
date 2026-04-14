"""Node 6b: Action planner -- sinh suggested_actions thông minh theo intent.

Chạy giữa `safety_guard` và `response_composer`. Gồm 4 bước:
  1. Thu thập facts từ state (meds, adherence, risk, tool_calls vừa chạy).
  2. Lấy template từ ACTION_MAP theo current_intent.
  3. Render placeholder + filter theo `requires`.
  4. Augment: follow-up chain, boost theo risk/hành vi, intent confidence thấp thì hỏi lại.

Trả tối đa 4 action, sort theo priority desc.
"""

from __future__ import annotations

import logging
from typing import Any

from agent.intents.action_map import (
    ACTION_MAP,
    DEFAULT_ACTIONS,
    FOLLOW_UP_CHAIN,
)
from agent.intents.definitions import Intent
from agent.state import PatientState

_log = logging.getLogger("medintel.agent.action_planner")

MAX_ACTIONS = 4
LOW_CONFIDENCE_THRESHOLD = 0.45


def _collect_facts(state: PatientState) -> dict[str, Any]:
    meds = state.get("medications") or []
    adherence = state.get("adherence_summary") or {}
    tool_calls = state.get("tool_calls") or []
    rag_results = state.get("rag_results") or []

    missed_7d = adherence.get("missed_last_7d", 0) if isinstance(adherence, dict) else 0
    has_major_interaction = any(
        (r.get("section") or "").lower() in {"interactions", "tuong_tac"}
        and "major" in (r.get("content") or "").lower()
        for r in rag_results
    )

    drug = meds[0].get("name") if meds else ""
    next_drug = meds[1].get("name") if len(meds) >= 2 else ""

    return {
        "has_meds": bool(meds),
        "has_two_meds": len(meds) >= 2,
        "has_adherence": bool(adherence),
        "missed_7d": missed_7d,
        "has_major_interaction": has_major_interaction,
        "just_logged_dose": any(tc.get("tool") == "log_dose" for tc in tool_calls),
        "risk_level": state.get("risk_level", "low"),
        "intent_confidence": float(state.get("intent_confidence") or 1.0),
        "drug": drug or "thuốc",
        "next_drug": next_drug or "thuốc khác",
        "profile_name": (state.get("patient_info") or {}).get("name", "bạn"),
    }


def _render(template: dict, facts: dict[str, Any]) -> dict:
    """Render placeholder trong label/prompt/tool_args."""
    out = dict(template)

    def _fmt(v: Any) -> Any:
        if isinstance(v, str):
            return v.format(
                drug=facts["drug"],
                next_drug=facts["next_drug"],
                profile_name=facts["profile_name"],
            )
        if isinstance(v, dict):
            return {k: _fmt(x) for k, x in v.items()}
        return v

    for key in ("label", "prompt", "route"):
        if key in out and isinstance(out[key], str):
            out[key] = _fmt(out[key])
    if "tool_args" in out and isinstance(out["tool_args"], dict):
        out["tool_args"] = _fmt(out["tool_args"])
    return out


def _passes_requires(template: dict, facts: dict[str, Any]) -> bool:
    for req in template.get("requires") or []:
        if not facts.get(req):
            return False
    return True


def _to_output(action: dict) -> dict:
    """Chuẩn hoá về schema SuggestedAction (giữ backward-compat: label/prompt/category bắt buộc).

    Nếu action không có `prompt` (type=tool/navigate/escalate), dùng label làm prompt fallback.
    """
    category = action.get("category", "other")
    label = action.get("label", "")
    prompt = action.get("prompt") or label
    out = {
        "label": label,
        "prompt": prompt,
        "category": category,
    }
    # Optional fields (client có thể ignore nếu chưa hiểu)
    for k in ("type", "route", "tool", "tool_args", "priority"):
        if k in action and action[k] not in (None, ""):
            out[k] = action[k]
    return out


def _deduplicate(actions: list[dict]) -> list[dict]:
    seen: set[str] = set()
    out: list[dict] = []
    for a in actions:
        key = (a.get("label") or "") + "|" + (a.get("tool") or a.get("route") or a.get("prompt") or "")
        if key in seen:
            continue
        seen.add(key)
        out.append(a)
    return out


async def action_planner(state: PatientState) -> dict:
    intent = state.get("current_intent") or Intent.UNKNOWN.value
    facts = _collect_facts(state)

    # 1. Low confidence -> hỏi lại làm rõ, không gợi ý linh tinh.
    if facts["intent_confidence"] < LOW_CONFIDENCE_THRESHOLD:
        clarifications = [
            {
                "label": "Bạn đang hỏi về lịch uống?",
                "prompt": "Tôi muốn hỏi về lịch uống thuốc hôm nay",
                "category": "clarify",
                "priority": 80,
            },
            {
                "label": "Bạn đang hỏi về tác dụng phụ?",
                "prompt": "Tôi muốn hỏi về tác dụng phụ của thuốc đang dùng",
                "category": "clarify",
                "priority": 75,
            },
            {
                "label": "Bạn đang hỏi về tương tác thuốc?",
                "prompt": "Tôi muốn hỏi về tương tác giữa các thuốc tôi đang dùng",
                "category": "clarify",
                "priority": 70,
            },
        ]
        return {"suggested_actions": [_to_output(a) for a in clarifications[:MAX_ACTIONS]]}

    # 2. Lấy template theo intent (fallback default nếu không có).
    templates = ACTION_MAP.get(intent, DEFAULT_ACTIONS)
    candidates: list[dict] = []
    for tpl in templates:
        if not _passes_requires(tpl, facts):
            continue
        candidates.append(_render(tpl, facts))

    # 3. Follow-up chain -> thêm 1 action "xem thêm" từ intent kế tiếp.
    for follow_intent in FOLLOW_UP_CHAIN.get(intent, [])[:1]:
        for tpl in ACTION_MAP.get(follow_intent, [])[:1]:
            if _passes_requires(tpl, facts):
                followed = _render(tpl, facts)
                followed["priority"] = max(0, (followed.get("priority", 50)) - 20)
                followed["category"] = followed.get("category", "follow_up")
                candidates.append(followed)

    # 4. Rule augment theo hành vi/risk.
    if facts["just_logged_dose"]:
        candidates.append({
            "label": "Ghi chú triệu chứng kèm theo",
            "prompt": "Tôi muốn ghi chú triệu chứng sau khi uống thuốc",
            "category": "report",
            "type": "tool",
            "tool": "append_care_note",
            "priority": 75,
        })
    if facts["missed_7d"] >= 3:
        candidates.append({
            "label": f"Bạn đã quên {facts['missed_7d']} liều tuần qua - xem mẹo tuân thủ",
            "prompt": "Cho tôi vài mẹo để nhớ uống thuốc đều hơn",
            "category": "tips",
            "priority": 85,
        })
    if facts["has_major_interaction"]:
        candidates.insert(0, {
            "label": "⚠️ Tương tác MAJOR - Liên hệ dược sĩ",
            "prompt": "Tôi muốn liên hệ dược sĩ/bác sĩ ngay",
            "category": "emergency",
            "type": "escalate",
            "priority": 100,
        })
    if facts["risk_level"] == "high":
        candidates.insert(0, {
            "label": "GỌI 115 / CẤP CỨU",
            "prompt": "Tôi cần cấp cứu",
            "category": "emergency",
            "type": "escalate",
            "priority": 100,
        })

    # 5. Sort + dedupe + cắt.
    candidates.sort(key=lambda a: a.get("priority", 50), reverse=True)
    candidates = _deduplicate(candidates)[:MAX_ACTIONS]

    actions_out = [_to_output(a) for a in candidates]

    _log.info(
        "ACTION_PLANNER intent=%s risk=%s n=%d labels=%s",
        intent,
        facts["risk_level"],
        len(actions_out),
        [a["label"] for a in actions_out],
    )
    return {"suggested_actions": actions_out}
