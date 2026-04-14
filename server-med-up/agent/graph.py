"""LangGraph StateGraph builder -- the orchestration core of server-med-up.

Pipeline:
  intent_router -> context_loader -> (rag_retriever?) -> reasoning
  -> (tool_executor? -> reasoning) -> safety_guard -> action_planner -> response_composer
"""

from __future__ import annotations

from langgraph.graph import END, StateGraph

from agent.checkpointer import get_checkpointer
from agent.intents.definitions import INTENTS_NEEDING_RAG
from agent.nodes.action_planner import action_planner
from agent.nodes.context_loader import context_loader
from agent.nodes.intent_router import intent_router
from agent.nodes.rag_retriever import rag_retriever
from agent.nodes.reasoning import reasoning
from agent.nodes.response_composer import response_composer
from agent.nodes.safety_guard import safety_guard
from agent.nodes.tool_executor import tool_executor
from agent.state import PatientState


def _route_after_intent(state: PatientState) -> str:
    intent = state.get("current_intent", "")
    if intent in {i.value for i in INTENTS_NEEDING_RAG}:
        return "rag_retriever"
    return "reasoning"


def _route_after_reasoning(state: PatientState) -> str:
    if state.get("tool_calls"):
        return "tool_executor"
    return "safety_guard"


def _route_after_tools(state: PatientState) -> str:
    return "reasoning"


def build_graph():
    builder = StateGraph(PatientState)

    builder.add_node("intent_router", intent_router)
    builder.add_node("context_loader", context_loader)
    builder.add_node("rag_retriever", rag_retriever)
    builder.add_node("reasoning", reasoning)
    builder.add_node("tool_executor", tool_executor)
    builder.add_node("safety_guard", safety_guard)
    builder.add_node("action_planner", action_planner)
    builder.add_node("response_composer", response_composer)

    builder.set_entry_point("intent_router")

    builder.add_edge("intent_router", "context_loader")
    builder.add_conditional_edges("context_loader", _route_after_intent)
    builder.add_edge("rag_retriever", "reasoning")
    builder.add_conditional_edges("reasoning", _route_after_reasoning)
    builder.add_conditional_edges("tool_executor", _route_after_tools)
    builder.add_edge("safety_guard", "action_planner")
    builder.add_edge("action_planner", "response_composer")
    builder.add_edge("response_composer", END)

    checkpointer = get_checkpointer()
    return builder.compile(checkpointer=checkpointer)


graph = build_graph()
