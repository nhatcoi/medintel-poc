from pydantic import AliasChoices, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Database
    database_url: str = "sqlite:///./medintel.db"
    create_tables_on_startup: bool = True
    cors_origins: list[str] = ["*"]

    # Security
    jwt_secret: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    jwt_exp_hours: int = 72

    # LLM (OpenAI-compatible)
    llm_base_url: str = "https://api.groq.com/openai/v1"
    llm_api_key: str = Field(
        default="",
        validation_alias=AliasChoices("LLM_API_KEY", "GROQ_API_KEY"),
    )
    llm_model: str = "llama-3.3-70b-versatile"
    llm_vision_model: str = "meta-llama/llama-4-scout-17b-16e-instruct"
    llm_max_tokens: int = 768
    llm_temperature: float = 0.3
    llm_timeout_seconds: float = 20.0
    llm_max_retries: int = 1

    # Chat
    chat_history_limit: int = 8
    agent_reply_max_tokens: int = 320
    patient_agent_context_max_age_seconds: int = 3600
    patient_agent_context_max_markdown_chars: int = 12000

    # Embedding
    embedding_model: str = "paraphrase-multilingual-MiniLM-L12-v2"
    embedding_dim: int = 384
    embedding_warmup_on_startup: bool = True

    # RAG
    rag_top_k: int = 6
    rag_min_similarity: float = 0.72
    rag_context_max_chars: int = 3800

    # CAG
    cag_enabled: bool = True
    cag_default_ttl_hours: int = 24
    cag_max_query_len: int = 500
    kb_version: int = 1

    # Tavily
    tavily_api_key: str = ""
    tavily_max_results: int = 5
    tavily_enabled: bool = True
    tavily_timeout_seconds: float = 12.0
    tavily_trusted_domains: list[str] = [
        "drugs.com",
        "medlineplus.gov",
        "mayoclinic.org",
        "nih.gov",
        "who.int",
        "ncbi.nlm.nih.gov",
        "vinmec.com",
    ]

    # Misc
    default_prescription_user_id: str = "00000000-0000-0000-0000-000000000001"
    docs_enabled: bool = True
    openapi_public_url: str = "http://localhost:8000"
    http_access_log: bool = True
    http_log_headers: bool = True
    http_log_bodies: bool = True
    http_log_body_max_chars: int = 4000
    agent_trace_log: bool = True
    agent_trace_max_chars: int = 4000


settings = Settings()
