"""Action registry cho agent planner.

- templates: các action template dùng chung (thêm tủ, quét đơn, xem tủ…).
- registry: map intent -> list action (đã trim, ≤3 action/intent).
"""

from agent.actions.registry import (
    ACTION_MAP,
    DEFAULT_ACTIONS,
    FOLLOW_UP_CHAIN,
)

__all__ = ["ACTION_MAP", "DEFAULT_ACTIONS", "FOLLOW_UP_CHAIN"]
