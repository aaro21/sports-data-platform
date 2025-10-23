"""NFL data ingestion module.

This module orchestrates the ingestion of NFL data into the bronze layer
of the data lake.
"""

from datetime import datetime
from typing import Optional

from src.utils.azure_storage import AzureStorageClient
from src.utils.config import Config
from src.utils.logging import setup_logger

from .api_client import NFLAPIClient

logger = setup_logger(__name__)


class NFLDataIngestion:
    """Orchestrates NFL data ingestion to bronze layer."""

    def __init__(
        self,
        api_key: Optional[str] = None,
        storage_connection_string: Optional[str] = None,
    ):
        """Initialize NFL data ingestion.

        Args:
            api_key: Optional NFL API key
            storage_connection_string: Optional Azure Storage connection string
        """
        self.api_client = NFLAPIClient(api_key=api_key)
        self.storage_client = AzureStorageClient(
            connection_string=storage_connection_string
        )
        self.container_name = Config.BRONZE_NFL_CONTAINER

    def ingest_scoreboard(self, date: datetime = None) -> str:
        """Ingest NFL scoreboard data for a specific date.

        Args:
            date: Date to ingest scoreboard for. Defaults to today.

        Returns:
            Blob URL where data was uploaded
        """
        if date is None:
            date = datetime.now()

        logger.info(f"Starting scoreboard ingestion for {date.date()}")

        # Fetch data from API
        scoreboard_data = self.api_client.get_scoreboard(date=date)

        # Create blob path with date partitioning
        blob_path = self.storage_client.create_dated_path(
            sport="nfl",
            data_type="scoreboard",
            date=date,
        )

        # Upload to bronze layer
        blob_url = self.storage_client.upload_json(
            data=scoreboard_data,
            container_name=self.container_name,
            blob_path=blob_path,
        )

        logger.info(f"Scoreboard data uploaded to {blob_url}")
        return blob_url

    def ingest_teams(self) -> str:
        """Ingest NFL teams data.

        Returns:
            Blob URL where data was uploaded
        """
        logger.info("Starting teams ingestion")

        # Fetch data from API
        teams_data = self.api_client.get_teams()

        # Create blob path
        blob_path = self.storage_client.create_dated_path(
            sport="nfl",
            data_type="teams",
        )

        # Upload to bronze layer
        blob_url = self.storage_client.upload_json(
            data=teams_data,
            container_name=self.container_name,
            blob_path=blob_path,
        )

        logger.info(f"Teams data uploaded to {blob_url}")
        return blob_url

    def ingest_standings(self) -> str:
        """Ingest NFL standings data.

        Returns:
            Blob URL where data was uploaded
        """
        logger.info("Starting standings ingestion")

        # Fetch data from API
        standings_data = self.api_client.get_standings()

        # Create blob path
        blob_path = self.storage_client.create_dated_path(
            sport="nfl",
            data_type="standings",
        )

        # Upload to bronze layer
        blob_url = self.storage_client.upload_json(
            data=standings_data,
            container_name=self.container_name,
            blob_path=blob_path,
        )

        logger.info(f"Standings data uploaded to {blob_url}")
        return blob_url


# Example usage (for testing)
if __name__ == "__main__":
    from dotenv import load_dotenv

    load_dotenv()

    # Validate configuration
    missing = Config.validate()
    if missing:
        logger.error(f"Missing required configuration: {', '.join(missing)}")
        exit(1)

    # Run ingestion
    ingestion = NFLDataIngestion()

    # Ingest today's scoreboard
    ingestion.ingest_scoreboard()

    # Ingest teams and standings
    ingestion.ingest_teams()
    ingestion.ingest_standings()

    logger.info("Ingestion complete!")
