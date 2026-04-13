from fastapi import APIRouter

from agent.tools import ALL_TOOLS

router = APIRouter(prefix="/agent", tags=["agent"])


@router.get("/tools")
def list_tools():
    return {
        "tools": [
            {"name": t.name, "description": t.description}
            for t in ALL_TOOLS
        ]
    }
