from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    openai_api_key: Optional[str] = None
    google_ai_api_key: Optional[str] = None
    futu_api_key: Optional[str] = None
    futu_api_secret: Optional[str] = None
    database_url: Optional[str] = None

    class Config:
        env_file = ".env"


settings = Settings()