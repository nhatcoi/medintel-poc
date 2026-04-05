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
    # Profile UUID fallback khi scan không gửi user_id (seed demo trong main.py)
    default_prescription_user_id: str = "00000000-0000-0000-0000-000000000001"

    # HTTP logging (middleware)
    http_access_log: bool = True
    http_log_headers: bool = False
    http_log_bodies: bool = False
    http_log_body_max_chars: int = 2048


settings = Settings()
