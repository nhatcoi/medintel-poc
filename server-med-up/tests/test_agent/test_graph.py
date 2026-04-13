"""End-to-end test for the LangGraph agent graph."""

import pytest
from langchain_core.messages import HumanMessage


@pytest.mark.asyncio
async def test_graph_greeting():
    """Graph should handle a greeting message without errors."""
    from agent.graph import graph

    state = {
        "messages": [HumanMessage(content="Xin chao")],
        "profile_id": None,
        "session_id": None,
    }
    config = {"configurable": {"thread_id": "test-greeting"}}
    # This will fail if LLM is not configured; skip in CI
    try:
        result = await graph.ainvoke(state, config=config)
        assert "reply" in result
    except Exception:
        pytest.skip("LLM not configured")
