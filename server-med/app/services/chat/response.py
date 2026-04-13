"""Map kết quả LLM / cache → ChatResponse + citation fallback + log trace."""

from __future__ import annotations

import logging

from app.schemas.chat import ChatResponse, Citation, SuggestedAction, ToolCall
from app.services.cag import CachedResponse

_log = logging.getLogger("medintel.chat")


def build_fallback_citations_from_trace(trace) -> tuple[str, float, list[Citation]]:
    """Suy ra nguồn/citation từ ReAct trace khi LLM không trả đủ metadata."""
    if trace is None:
        return (
            "model",
            0.3,
            [Citation(title="Model prior knowledge", url=None, source_type="model")],
        )

    has_external = bool(getattr(trace, "tavily_hit_count", 0) > 0 and getattr(trace, "tavily_urls", []))
    has_internal = bool(getattr(trace, "rag_hit_count", 0) > 0)

    citations: list[Citation] = []
    if has_internal:
        citations.append(
            Citation(
                title="MedIntel internal drug knowledge base",
                url=None,
                source_type="internal",
            )
        )
    if has_external:
        urls = list(getattr(trace, "tavily_urls", []))
        if urls:
            citations.append(
                Citation(
                    title="Trusted external medical web sources",
                    url=urls[0],
                    source_type="external",
                )
            )
    if citations:
        if has_internal and has_external:
            return ("mixed", 0.7, citations)
        if has_external:
            return ("external", 0.6, citations)
        return ("internal", 0.75, citations)

    return (
        "model",
        0.3,
        [Citation(title="Model prior knowledge", url=None, source_type="model")],
    )


def result_to_response(turn, session_id: str | None, trace=None) -> ChatResponse:
    actions = [
        SuggestedAction(
            label=a["label"],
            prompt=a["prompt"] if a.get("prompt") else a["label"],
            category=a.get("category") or "other",
        )
        for a in turn.suggested_actions
    ]
    tools = [ToolCall(tool=t["tool"], args=t.get("args") or {}) for t in turn.tool_calls]
    citations = [
        Citation(
            title=str(c.get("title") or "").strip(),
            url=(str(c.get("url")).strip() if c.get("url") else None),
            source_type=str(c.get("source_type") or "internal").strip().lower(),
        )
        for c in (turn.citations or [])
        if str(c.get("title") or "").strip()
    ]
    source_type = str(turn.source_type or "").strip().lower()
    confidence = float(turn.confidence if turn.confidence is not None else 0.4)
    if not citations or source_type not in {"internal", "external", "mixed", "model"}:
        fb_source_type, fb_confidence, fb_citations = build_fallback_citations_from_trace(trace)
        if not citations:
            citations = fb_citations
        if source_type not in {"internal", "external", "mixed", "model"}:
            source_type = fb_source_type
        if not (0.0 <= confidence <= 1.0):
            confidence = fb_confidence

    return ChatResponse(
        reply=turn.reply,
        source_type=source_type,
        confidence=max(0.0, min(1.0, confidence)),
        citations=citations,
        session_id=session_id,
        suggested_actions=actions,
        tool_calls=tools,
    )


def log_retrieval_trace(trace, final_source_type: str) -> None:
    if trace is None:
        _log.info(
            "chat_trace rag_hit_count=%d tavily_hit_count=%d final_source_type=%s",
            0,
            0,
            final_source_type,
        )
        return
    _log.info(
        "chat_trace rag_hit_count=%d tavily_hit_count=%d final_source_type=%s",
        int(getattr(trace, "rag_hit_count", 0)),
        int(getattr(trace, "tavily_hit_count", 0)),
        final_source_type,
    )


def cached_to_response(cached: CachedResponse, session_id: str | None) -> ChatResponse:
    actions = [
        SuggestedAction(
            label=a.get("label", ""),
            prompt=a.get("prompt") or a.get("label", ""),
            category=a.get("category") or "other",
        )
        for a in cached.suggested_actions
        if a.get("label")
    ]
    tools = [
        ToolCall(tool=t.get("tool", ""), args=t.get("args") or {})
        for t in cached.tool_calls
        if t.get("tool")
    ]
    return ChatResponse(
        reply=cached.reply,
        source_type="internal",
        confidence=0.85,
        citations=[Citation(title="MedIntel cached response", url=None, source_type="internal")],
        session_id=session_id,
        suggested_actions=actions,
        tool_calls=tools,
    )
