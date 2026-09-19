from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

# Root project directory containing .env
ROOT_DIR = Path(__file__).resolve().parents[3]
ENV_FILE = ROOT_DIR / ".env"


class Settings(BaseSettings):
    # Supabase credentials (read from centralized root .env or environment)
    PUBLIC_SUPABASE_URL: str = ""
    PUBLIC_SUPABASE_ANON_KEY: str = ""
    SUPABASE_SERVICE_ROLE_KEY: str = ""
    DATABASE_URL: str = ""

    # AI Providers (Backend Only)
    GEMINI_API_KEY: str = ""
    GROQ_API_KEY: str = ""

    # Server configuration
    BACKEND_HOST: str = "0.0.0.0"
    BACKEND_PORT: int = 8000
    BACKEND_ENV: str = "development"
    CRON_SECRET: str = "alur-dev-cron-secret-2026"

    # Chat & Companion Configuration
    COMPANION_SYSTEM_PROMPT: str = ""
    CHAT_CONTEXT_WINDOW_DAYS: int = 7

    model_config = SettingsConfigDict(
        env_file=ENV_FILE if ENV_FILE.exists() else None,
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
