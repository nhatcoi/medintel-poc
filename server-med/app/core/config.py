from pydantic import AliasChoices, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "sqlite:///./medintel.db"
    cors_origins: list[str] = ["*"]
    create_tables_on_startup: bool = True
    jwt_secret: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    jwt_exp_hours: int = 72
    # Groq OpenAI-compatible: https://console.groq.com/docs/openai
    llm_base_url: str = "https://api.groq.com/openai/v1/chat/completions"
    llm_api_key: str = Field(
        default="",
        validation_alias=AliasChoices("LLM_API_KEY", "GROQ_API_KEY"),
    )
    # Chat agent (text). Ví dụ: llama-3.3-70b-versatile, llama-3.1-8b-instant
    llm_model: str = "llama-3.3-70b-versatile"
    # Quét đơn (vision). Groq: meta-llama/llama-4-scout-17b-16e-instruct
    llm_vision_model: str = "meta-llama/llama-4-scout-17b-16e-instruct"
    # Giới hạn token sinh — giảm latency (reply JSON ngắn). 0 = không gửi, để provider tự quyết.
    llm_max_tokens: int = 768
    # Số lượt user/assistant gần nhất đưa vào prompt (càng ít càng nhanh).
    chat_history_limit: int = 8
    # Markdown ngữ cảnh agent (`patient_agent_context`): làm mới nếu bản lưu quá cũ (giây).
    patient_agent_context_max_age_seconds: int = 3600
    # Giới hạn độ dài khi render markdown từ snapshot (tránh TEXT quá lớn).
    patient_agent_context_max_markdown_chars: int = 12000
    # Embedding (sentence-transformers local model)
    embedding_model: str = "paraphrase-multilingual-MiniLM-L12-v2"
    embedding_dim: int = 384
    # true = nạp model khi uvicorn start (request đầu không chờ load BerT). Tắt trong pytest.
    embedding_warmup_on_startup: bool = True
    # RAG
    rag_top_k: int = 6
    rag_min_similarity: float = 0.72  # ngưỡng coi RAG là "đủ tốt"; dưới ngưỡng → fallback Agent 2
    # Giới hạn độ dài block RAG ghép vào system prompt — context ngắn hơn → LLM xử lý nhanh hơn.
    rag_context_max_chars: int = 3800

    # CAG (Cache-Augmented Generation)
    cag_enabled: bool = True
    cag_default_ttl_hours: int = 24
    cag_max_query_len: int = 500
    kb_version: int = 1  # bump khi ingest dữ liệu mới để invalidate cache cũ

    # Agent 2 — External fallback (Tavily)
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
