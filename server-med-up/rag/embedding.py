"""Local embedding via sentence-transformers (lazy load)."""

from __future__ import annotations

import asyncio
import logging

from core.config import settings

_log = logging.getLogger("medintel.embedding")
_model = None


def _get_model():
    global _model
    if _model is None:
        from sentence_transformers import SentenceTransformer
        _model = SentenceTransformer(settings.embedding_model)
        _log.info("Loaded embedding model: %s", settings.embedding_model)
    return _model


def embed_sync(texts: list[str]) -> list[list[float]]:
    model = _get_model()
    return model.encode(texts, normalize_embeddings=True).tolist()


async def embed_async(texts: list[str]) -> list[list[float]]:
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(None, embed_sync, texts)


def warmup_embedding_model() -> None:
    _get_model()
    _log.info("Embedding model warmed up")
