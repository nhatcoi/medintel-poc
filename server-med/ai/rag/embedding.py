"""Embedding module — dùng sentence-transformers (local, offline).

Model mặc định: all-MiniLM-L6-v2 (dim=384, nhẹ, nhanh).
Có thể đổi qua config: EMBEDDING_MODEL=paraphrase-multilingual-MiniLM-L12-v2 (dim=384, hỗ trợ tiếng Việt tốt hơn).
"""

from __future__ import annotations

import logging
from functools import lru_cache

from app.core.config import settings

_log = logging.getLogger(__name__)

EMBEDDING_DIM = settings.embedding_dim


@lru_cache(maxsize=1)
def _get_model():
    """Lazy-load sentence-transformer model (chỉ load 1 lần)."""
    from sentence_transformers import SentenceTransformer

    model_name = settings.embedding_model
    _log.info("Loading embedding model: %s", model_name)
    model = SentenceTransformer(model_name)
    return model


def warmup_embedding_model() -> None:
    """Gọi khi startup: nạp weights + một lần encode tối thiểu — tránh chậm ở tin nhắn/RAG đầu tiên."""
    get_embedding_sync("warmup")


def get_embeddings_sync(texts: list[str]) -> list[list[float]]:
    """Batch encode → list of float vectors."""
    model = _get_model()
    embeddings = model.encode(texts, normalize_embeddings=True, show_progress_bar=False)
    return [vec.tolist() for vec in embeddings]


def get_embedding_sync(text: str) -> list[float]:
    """Single text → single vector."""
    return get_embeddings_sync([text])[0]


async def get_embedding(text: str) -> list[float]:
    """Async wrapper (chạy blocking encode trong thread pool)."""
    import asyncio
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(None, get_embedding_sync, text)


async def get_embeddings(texts: list[str]) -> list[list[float]]:
    """Async batch wrapper."""
    import asyncio
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(None, get_embeddings_sync, texts)
