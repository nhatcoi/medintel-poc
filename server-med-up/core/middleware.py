"""HTTP logging middleware."""

from __future__ import annotations

import logging
import time
from typing import Any

from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response

from core.config import settings

_log = logging.getLogger("medintel.http")


def _clip(value: Any, max_chars: int) -> str:
    text = str(value)
    if len(text) <= max_chars:
        return text
    return f"{text[:max_chars]} ...[truncated {len(text) - max_chars} chars]"


class HttpLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        if not settings.http_access_log:
            return await call_next(request)

        t0 = time.perf_counter()
        request_body = await request.body()
        response = await call_next(request)
        response_body = b""
        async for chunk in response.body_iterator:
            response_body += chunk

        rebuilt = Response(
            content=response_body,
            status_code=response.status_code,
            headers=dict(response.headers),
            media_type=response.media_type,
            background=response.background,
        )
        ms = (time.perf_counter() - t0) * 1000
        req_info = {
            "method": request.method,
            "path": request.url.path,
            "query": str(request.url.query or ""),
            "status": rebuilt.status_code,
            "duration_ms": round(ms, 1),
        }
        if settings.http_log_headers:
            req_info["request_headers"] = dict(request.headers)
            req_info["response_headers"] = dict(rebuilt.headers)
        if settings.http_log_bodies:
            # Avoid logging huge binary blobs (e.g. image uploads)
            content_type = request.headers.get("Content-Type", "").lower()
            is_binary = any(t in content_type for t in ["image/", "multipart/", "application/octet-stream"])
            
            if is_binary:
                req_info["request_body"] = f"<{content_type} binary data>"
            else:
                try:
                    req_info["request_body"] = _clip(
                        request_body.decode("utf-8"),
                        settings.http_log_body_max_chars,
                    )
                except UnicodeDecodeError:
                    req_info["request_body"] = "<binary data (decode failed)>"

            # Similarly for response body
            resp_content_type = rebuilt.headers.get("Content-Type", "").lower()
            resp_is_binary = any(t in resp_content_type for t in ["image/", "application/pdf"])
            
            if resp_is_binary:
                req_info["response_body"] = f"<{resp_content_type} binary data>"
            else:
                try:
                    req_info["response_body"] = _clip(
                        response_body.decode("utf-8"),
                        settings.http_log_body_max_chars,
                    )
                except UnicodeDecodeError:
                    req_info["response_body"] = "<binary data (decode failed)>"
        
        _log.info("API_TRACE %s", req_info)
        return rebuilt
