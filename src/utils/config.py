"""Configuration management utilities."""

import os
from pathlib import Path
from typing import Optional

from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


class Config:
    """Central configuration class for the application."""

    # Azure Storage
    AZURE_STORAGE_ACCOUNT_NAME: str = os.getenv("AZURE_STORAGE_ACCOUNT_NAME", "")
    AZURE_STORAGE_CONNECTION_STRING: str = os.getenv("AZURE_STORAGE_CONNECTION_STRING", "")

    # PostgreSQL
    POSTGRES_HOST: str = os.getenv("POSTGRES_HOST", "")
    POSTGRES_PORT: int = int(os.getenv("POSTGRES_PORT", "5432"))
    POSTGRES_DB: str = os.getenv("POSTGRES_DB", "sports_data")
    POSTGRES_USER: str = os.getenv("POSTGRES_USER", "")
    POSTGRES_PASSWORD: str = os.getenv("POSTGRES_PASSWORD", "")

    # Environment
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "dev")

    # Data Lake Containers
    BRONZE_NFL_CONTAINER = "bronze-nfl"
    BRONZE_NBA_CONTAINER = "bronze-nba"
    BRONZE_NHL_CONTAINER = "bronze-nhl"
    SILVER_NFL_CONTAINER = "silver-nfl"
    SILVER_NBA_CONTAINER = "silver-nba"
    SILVER_NHL_CONTAINER = "silver-nhl"
    GOLD_NFL_CONTAINER = "gold-nfl"
    GOLD_NBA_CONTAINER = "gold-nba"
    GOLD_NHL_CONTAINER = "gold-nhl"

    @classmethod
    def get_postgres_uri(cls) -> str:
        """Get PostgreSQL connection URI."""
        return f"postgresql://{cls.POSTGRES_USER}:{cls.POSTGRES_PASSWORD}@{cls.POSTGRES_HOST}:{cls.POSTGRES_PORT}/{cls.POSTGRES_DB}"

    @classmethod
    def validate(cls) -> list[str]:
        """Validate required configuration values.

        Returns:
            List of missing configuration keys.
        """
        missing = []
        required_vars = [
            "AZURE_STORAGE_ACCOUNT_NAME",
            "POSTGRES_HOST",
            "POSTGRES_USER",
            "POSTGRES_PASSWORD",
        ]

        for var in required_vars:
            if not getattr(cls, var):
                missing.append(var)

        return missing
