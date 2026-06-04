from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Ollama
    ollama_base_url: str = "http://ollama:11434"

    # Model
    default_model: str = "llama3.2:1b"
    auto_pull_model: bool = True

    # API
    api_key: str = ""

    # Logging
    log_level: str = "info"


@lru_cache
def get_settings() -> Settings:
    return Settings()