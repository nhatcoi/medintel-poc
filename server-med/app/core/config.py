from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "sqlite:///./medintel.db"
    cors_origins: list[str] = ["*"]
    create_tables_on_startup: bool = True
    jwt_secret: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    jwt_exp_hours: int = 72
    llm_base_url: str = "https://rftzycu.9router.com/v1/chat/completions"
    llm_api_key: str = ""
    llm_model: str = "combo-1"
    # Embedding (sentence-transformers local model)
    embedding_model: str = "paraphrase-multilingual-MiniLM-L12-v2"
    embedding_dim: int = 384
    # RAG
    rag_top_k: int = 8
    rag_min_similarity: float = 0.72  # ngưỡng coi RAG là "đủ tốt"; dưới ngưỡng → fallback Agent 2

    # CAG (Cache-Augmented Generation)
    cag_enabled: bool = True
    cag_default_ttl_hours: int = 24
    cag_max_query_len: int = 500
    kb_version: int = 1  # bump khi ingest dữ liệu mới để invalidate cache cũ

    # Agent 2 — External fallback (Tavily)
    tavily_api_key: str = ""
    tavily_max_results: int = 5
    tavily_enabled: bool = True
    tavily_trusted_domains: list[str] = [
        "drugs.com",
        "medlineplus.gov",
        "mayoclinic.org",
        "nih.gov",
        "who.int",
        "ncbi.nlm.nih.gov",
        "vinmec.com",
        "tamanhhospital.vn",
        "bvdaihoc.com.vn",
    ]
    # Profile UUID fallback khi scan không gửi user_id (seed demo trong main.py)
    default_prescription_user_id: str = "00000000-0000-0000-0000-000000000001"

    # HTTP logging (middleware)
    http_access_log: bool = True
    http_log_headers: bool = False
    http_log_bodies: bool = False
    http_log_body_max_chars: int = 2048

    # Swagger UI: /docs , OpenAPI JSON: /openapi.json
    docs_enabled: bool = True
    # Base URL hiển thị trong OpenAPI (Try it out) — đổi khi deploy hoặc dùng tunnel
    openapi_public_url: str = "http://localhost:8000"


settings = Settings()
