"""Ghi log HTTP: method, path, client, status, thời gian; tùy chọn body (dev)."""

from __future__ import annotations

import logging
import time
from typing import Any

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response
from starlette.types import ASGIApp, Message, Receive

from app.core.config import settings

log = logging.getLogger("medintel.http")


def _truncate(s: str, max_len: int) -> str:
    if len(s) <= max_len:
        return s
    return s[: max_len - 3] + "..."


def _redact_headers(headers: Any) -> dict[str, str]:
    """Chuỗi header để log; ẩn Authorization / Cookie."""
    out: dict[str, str] = {}
    for k, v in headers.items():
        lk = k.lower()
        if lk in ("authorization", "cookie"):
            out[k] = "<redacted>"
        else:
            out[k] = v
    return out


class HttpLoggingMiddleware(BaseHTTPMiddleware):
    def __init__(self, app: ASGIApp) -> None:
        super().__init__(app)

    async def dispatch(self, request: Request, call_next):
        if not settings.http_access_log:
            return await call_next(request)

        start = time.perf_counter()
        client = request.client.host if request.client else "?"
        path_qs = request.url.path
        if request.url.query:
            path_qs += f"?{request.url.query}"

        req_extra = ""
        if settings.http_log_headers:
            req_extra = f" headers={_redact_headers(request.headers)!r}"

        body_for_rerun: bytes | None = None
        if settings.http_log_bodies:
            ct = request.headers.get("content-type", "")
            if "multipart/form-data" in ct:
                cl = request.headers.get("content-length", "?")
                req_extra += f" req_body=<multipart {cl} bytes>"
            else:
                raw = await request.body()
                body_for_rerun = raw
                if raw:
                    try:
                        req_extra += f" req_body={_truncate(raw.decode('utf-8', errors='replace'), settings.http_log_body_max_chars)!r}"
                    except Exception:
                        req_extra += f" req_body=<binary {len(raw)}B>"

        if body_for_rerun is not None:

            async def receive() -> Message:
                return {"type": "http.request", "body": body_for_rerun, "more_body": False}

            request = Request(request.scope, receive)

        log.info("-> %s %s from %s%s", request.method, path_qs, client, req_extra)

        response = await call_next(request)
        elapsed_ms = (time.perf_counter() - start) * 1000

        resp_extra = ""
        if settings.http_log_bodies and hasattr(response, "body_iterator"):
            chunks: list[bytes] = []
            async for chunk in response.body_iterator:
                chunks.append(chunk)
            full = b"".join(chunks)
            ct = response.headers.get("content-type", "")
            if "application/json" in ct or "text/" in ct:
                try:
                    resp_extra = f" res_body={_truncate(full.decode('utf-8', errors='replace'), settings.http_log_body_max_chars)!r}"
                except Exception:
                    resp_extra = f" res_body=<binary {len(full)}B>"
            else:
                resp_extra = f" res_body=<{len(full)} bytes {ct!r}>"
            response = Response(
                content=full,
                status_code=response.status_code,
                headers=dict(response.headers),
                media_type=response.media_type,
            )

        log.info(
            "<- %s %s -> %s %.1fms%s",
            request.method,
            path_qs,
            response.status_code,
            elapsed_ms,
            resp_extra,
        )
        return response
