from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+psycopg2://medintel:medintel@127.0.0.1:5432/medintel"
    cors_origins: list[str] = ["*"]
    create_tables_on_startup: bool = False
    jwt_secret: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    jwt_exp_hours: int = 72


settings = Settings()
