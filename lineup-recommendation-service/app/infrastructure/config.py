from __future__ import annotations

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="LINEUP_SVC_")

    port: int = 8100
    log_level: str = "info"
    # CORS: le service n'est appelé que par le backend Express en interne
    # (jamais directement par un client Flutter/navigateur), donc pas
    # d'origine publique à autoriser par défaut.
    allowed_origins: list[str] = []
    service_token: str = ""


settings = Settings()
