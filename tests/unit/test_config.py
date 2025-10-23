"""Unit tests for configuration module."""

import os
from unittest.mock import patch

import pytest

from src.utils.config import Config


def test_config_postgres_uri():
    """Test PostgreSQL URI generation."""
    with patch.dict(
        os.environ,
        {
            "POSTGRES_USER": "testuser",
            "POSTGRES_PASSWORD": "testpass",
            "POSTGRES_HOST": "localhost",
            "POSTGRES_PORT": "5432",
            "POSTGRES_DB": "testdb",
        },
    ):
        # Reload config to pick up new env vars
        from importlib import reload
        from src.utils import config

        reload(config)

        expected_uri = "postgresql://testuser:testpass@localhost:5432/testdb"
        assert config.Config.get_postgres_uri() == expected_uri


def test_config_validation():
    """Test configuration validation."""
    with patch.dict(os.environ, {}, clear=True):
        from importlib import reload
        from src.utils import config

        reload(config)

        missing = config.Config.validate()
        assert "AZURE_STORAGE_ACCOUNT_NAME" in missing
        assert "POSTGRES_HOST" in missing
        assert "POSTGRES_USER" in missing
        assert "POSTGRES_PASSWORD" in missing
