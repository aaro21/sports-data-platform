"""Azure Storage utilities for Data Lake interactions."""

import json
from datetime import datetime
from pathlib import Path
from typing import Any

from azure.storage.blob import BlobServiceClient, ContainerClient

from .config import Config


class AzureStorageClient:
    """Client for interacting with Azure Data Lake Storage."""

    def __init__(self, connection_string: str = None):
        """Initialize Azure Storage client.

        Args:
            connection_string: Azure Storage connection string.
                             If not provided, uses Config.AZURE_STORAGE_CONNECTION_STRING
        """
        conn_str = connection_string or Config.AZURE_STORAGE_CONNECTION_STRING
        if not conn_str:
            raise ValueError("Azure Storage connection string not configured")

        self.blob_service_client = BlobServiceClient.from_connection_string(conn_str)

    def get_container_client(self, container_name: str) -> ContainerClient:
        """Get a container client.

        Args:
            container_name: Name of the container

        Returns:
            ContainerClient instance
        """
        return self.blob_service_client.get_container_client(container_name)

    def upload_json(
        self,
        data: dict[str, Any] | list[dict[str, Any]],
        container_name: str,
        blob_path: str,
        overwrite: bool = True,
    ) -> str:
        """Upload JSON data to a blob.

        Args:
            data: Dictionary or list of dictionaries to upload
            container_name: Target container name
            blob_path: Path within the container (e.g., 'games/2024/game_123.json')
            overwrite: Whether to overwrite existing blob

        Returns:
            Blob URL
        """
        container_client = self.get_container_client(container_name)
        blob_client = container_client.get_blob_client(blob_path)

        json_str = json.dumps(data, indent=2, default=str)
        blob_client.upload_blob(json_str, overwrite=overwrite)

        return blob_client.url

    def upload_file(
        self,
        file_path: str | Path,
        container_name: str,
        blob_path: str = None,
        overwrite: bool = True,
    ) -> str:
        """Upload a file to a blob.

        Args:
            file_path: Local file path
            container_name: Target container name
            blob_path: Path within the container. If None, uses file name
            overwrite: Whether to overwrite existing blob

        Returns:
            Blob URL
        """
        file_path = Path(file_path)
        if not blob_path:
            blob_path = file_path.name

        container_client = self.get_container_client(container_name)
        blob_client = container_client.get_blob_client(blob_path)

        with open(file_path, "rb") as data:
            blob_client.upload_blob(data, overwrite=overwrite)

        return blob_client.url

    def download_json(self, container_name: str, blob_path: str) -> dict | list:
        """Download JSON data from a blob.

        Args:
            container_name: Source container name
            blob_path: Path within the container

        Returns:
            Parsed JSON data
        """
        container_client = self.get_container_client(container_name)
        blob_client = container_client.get_blob_client(blob_path)

        blob_data = blob_client.download_blob().readall()
        return json.loads(blob_data)

    def list_blobs(self, container_name: str, prefix: str = None) -> list[str]:
        """List blobs in a container.

        Args:
            container_name: Container name
            prefix: Optional prefix to filter blobs

        Returns:
            List of blob names
        """
        container_client = self.get_container_client(container_name)
        blob_list = container_client.list_blobs(name_starts_with=prefix)
        return [blob.name for blob in blob_list]

    def create_dated_path(
        self,
        sport: str,
        data_type: str,
        extension: str = "json",
        date: datetime = None,
    ) -> str:
        """Create a date-partitioned path for a blob.

        Args:
            sport: Sport name (e.g., 'nfl', 'nba')
            data_type: Type of data (e.g., 'games', 'players')
            extension: File extension
            date: Date to use for partitioning. Defaults to today.

        Returns:
            Formatted blob path (e.g., 'nfl/games/year=2024/month=10/day=23/data.json')
        """
        if date is None:
            date = datetime.now()

        return (
            f"{sport}/{data_type}/"
            f"year={date.year}/month={date.month:02d}/day={date.day:02d}/"
            f"{date.strftime('%Y%m%d_%H%M%S')}.{extension}"
        )
