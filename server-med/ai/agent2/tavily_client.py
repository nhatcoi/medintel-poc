"""Gọi Tavily Search API để lấy kết quả web có căn cứ nguồn.

API docs: https://docs.tavily.com/docs/rest-api/api-reference
Endpoint: POST https://api.tavily.com/search

Payload:
    {
      "api_key": "...",
      "query": "...",
      "search_depth": "basic" | "advanced",
      "max_results": 5,
      "include_answer": true,
      "include_domains": [...],
    }
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

import httpx

from app.core.config import settings

TAVILY_URL = "https://api.tavily.com/search"


@dataclass
class TavilyHit:
    title: str
    url: str
    content: str
    score: float = 0.0


@dataclass
class TavilyResult:
    query: str
    answer: str | None = None
    hits: list[TavilyHit] = field(default_factory=list)


async def search(
    query: str,
    *,
    max_results: int | None = None,
    include_trusted_only: bool = True,
    timeout: float = 20.0,
) -> TavilyResult:
    """Chạy 1 query Tavily; trả về rỗng nếu thiếu API key hoặc lỗi."""
    query = (query or "").strip()
    if not query:
        return TavilyResult(query=query)

    api_key = settings.tavily_api_key.strip()
    if not api_key or not settings.tavily_enabled:
        return TavilyResult(query=query)

    payload: dict[str, Any] = {
        "api_key": api_key,
        "query": query,
        "search_depth": "basic",
        "max_results": max_results or settings.tavily_max_results,
        "include_answer": True,
    }
    if include_trusted_only and settings.tavily_trusted_domains:
        payload["include_domains"] = list(settings.tavily_trusted_domains)

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            resp = await client.post(TAVILY_URL, json=payload)
            resp.raise_for_status()
            data = resp.json()
    except Exception:  # noqa: BLE001
        return TavilyResult(query=query)

    hits: list[TavilyHit] = []
    for item in data.get("results", []) or []:
        url = str(item.get("url") or "").strip()
        if not url:
            continue
        hits.append(
            TavilyHit(
                title=str(item.get("title") or "").strip(),
                url=url,
                content=str(item.get("content") or "").strip(),
                score=float(item.get("score") or 0.0),
            )
        )

    return TavilyResult(
        query=query,
        answer=data.get("answer"),
        hits=hits,
    )


def build_external_context(result: TavilyResult) -> str | None:
    """Format TavilyResult thành context block cho system prompt."""
    if not result.hits and not result.answer:
        return None
    lines = [
        "### Kiến thức từ nguồn ngoài (Tavily — đã lọc nguồn tin cậy)",
        "LƯU Ý: Đây là dữ liệu web, bạn PHẢI trích nguồn khi dùng và KHÔNG được tự ý khuyến nghị đổi liều.",
        "",
    ]
    if result.answer:
        lines.append(f"**Tóm tắt:** {result.answer}")
        lines.append("")
    for i, h in enumerate(result.hits, 1):
        snippet = h.content[:500].replace("\n", " ")
        lines.append(f"{i}. **{h.title}** — {snippet}")
        lines.append(f"   Nguồn: {h.url}")
    return "\n".join(lines)
