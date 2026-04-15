"""Load capability registry and intent plans from JSON config."""

from __future__ import annotations

import json
from functools import lru_cache
from pathlib import Path
from typing import Any

_BASE = Path(__file__).resolve().parent
_CAP_FILE = _BASE / "capability_registry.json"
_PLAN_FILE = _BASE / "intent_plans.json"


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


@lru_cache(maxsize=1)
def capability_registry() -> dict[str, Any]:
    return _read_json(_CAP_FILE)


@lru_cache(maxsize=1)
def intent_plans() -> dict[str, Any]:
    return _read_json(_PLAN_FILE)


def get_plan(intent: str) -> dict[str, Any]:
    plans = intent_plans()
    by_intent = plans.get("intent_plans", {})
    defaults = plans.get("defaults", {})
    return dict(defaults, **by_intent.get(intent, {}))

