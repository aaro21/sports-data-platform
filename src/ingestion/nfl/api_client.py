"""NFL data API client.

This module will interact with NFL data sources to retrieve game data,
player stats, team information, etc.

TODO: Decide on NFL data source:
- ESPN API (free, limited)
- NFL.com (unofficial, web scraping)
- Pro Football Reference (web scraping)
- Third-party paid APIs (sportsdata.io, etc.)
"""

from datetime import datetime
from typing import Any

import requests

from src.utils.logging import setup_logger

logger = setup_logger(__name__)


class NFLAPIClient:
    """Client for interacting with NFL data APIs."""

    def __init__(self, api_key: str = None):
        """Initialize NFL API client.

        Args:
            api_key: Optional API key for authenticated endpoints
        """
        self.api_key = api_key
        self.session = requests.Session()
        self.base_url = "https://site.api.espn.com/apis/site/v2/sports/football/nfl"

        if api_key:
            self.session.headers.update({"Authorization": f"Bearer {api_key}"})

    def get_scoreboard(self, date: datetime = None) -> dict[str, Any]:
        """Get NFL scoreboard for a specific date.

        Args:
            date: Date to get scoreboard for. Defaults to today.

        Returns:
            Scoreboard data including games, scores, and basic stats
        """
        if date is None:
            date = datetime.now()

        date_str = date.strftime("%Y%m%d")
        url = f"{self.base_url}/scoreboard"
        params = {"dates": date_str}

        logger.info(f"Fetching NFL scoreboard for {date_str}")
        response = self.session.get(url, params=params)
        response.raise_for_status()

        return response.json()

    def get_teams(self) -> dict[str, Any]:
        """Get list of all NFL teams.

        Returns:
            Team data including names, logos, records, etc.
        """
        url = f"{self.base_url}/teams"

        logger.info("Fetching NFL teams")
        response = self.session.get(url)
        response.raise_for_status()

        return response.json()

    def get_team_roster(self, team_id: str) -> dict[str, Any]:
        """Get roster for a specific team.

        Args:
            team_id: Team identifier

        Returns:
            Roster data including players and their positions
        """
        url = f"{self.base_url}/teams/{team_id}/roster"

        logger.info(f"Fetching roster for team {team_id}")
        response = self.session.get(url)
        response.raise_for_status()

        return response.json()

    def get_standings(self) -> dict[str, Any]:
        """Get current NFL standings.

        Returns:
            Standings data by division and conference
        """
        url = f"{self.base_url}/standings"

        logger.info("Fetching NFL standings")
        response = self.session.get(url)
        response.raise_for_status()

        return response.json()
