# Sports Data Platform

A modern data platform for collecting, processing, and analyzing sports data across NFL, NBA, and NHL.

## Architecture

- **Infrastructure**: Terraform (Azure)
- **Orchestration**: Apache Airflow
- **Data Transformation**: dbt
- **Database**: PostgreSQL
- **Storage**: Azure Data Lake Gen2

## Getting Started

### Prerequisites
- Azure account
- Terraform >= 1.5
- Python 3.12+
- [uv](https://docs.astral.sh/uv/) package manager
- Docker & Docker Compose (for Airflow)

### Quick Start

1. **Clone the repository**
```bash
git clone https://github.com/aaro21/sports-data-platform.git
cd sports-data-platform
```

2. **Set up Python environment**
```bash
# Install uv if not already installed
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install dependencies
uv sync
```

3. **Configure environment variables**
```bash
cp .env.example .env
# Edit .env with your Azure credentials
```

4. **Deploy infrastructure** (see [infrastructure/terraform/environments/dev/README.md](infrastructure/terraform/environments/dev/README.md))
```bash
# Deploy core resources (always-on)
cd infrastructure/terraform/environments/dev/core
terraform init && terraform apply

# Deploy database (on-demand)
cd ../database
terraform init && terraform apply

# Deploy compute/Airflow (on-demand)
cd ../compute
terraform init && terraform apply
```

5. **Run your first data ingestion**
```bash
# Activate virtual environment
source .venv/bin/activate

# Run NFL data ingestion
python -m src.ingestion.nfl.ingest
```

6. **Run dbt transformations**
```bash
cd src/transformation/sports_dbt
dbt run
```

## Project Structure
```
sports-data-platform/
├── .github/                    # GitHub Actions workflows
├── dags/                       # Airflow DAG definitions
│   ├── nfl/                   # NFL-specific DAGs
│   ├── nba/                   # NBA-specific DAGs
│   ├── nhl/                   # NHL-specific DAGs
│   └── common/                # Shared utilities
├── data/                       # Local data samples (gitignored)
│   ├── raw/                   # Sample raw data
│   └── processed/             # Sample processed data
├── docs/                       # Documentation
├── infrastructure/             # Terraform IaC
│   └── terraform/
│       └── environments/dev/
│           ├── core/          # Always-on (Storage, RG)
│           ├── database/      # On-demand (PostgreSQL)
│           └── compute/       # On-demand (Airflow VM)
├── notebooks/                  # Jupyter notebooks
├── scripts/                    # Utility scripts
│   ├── setup/
│   └── deploy/
├── src/                        # Python source code
│   ├── ingestion/             # Data ingestion modules
│   │   ├── nfl/              # NFL data sources
│   │   ├── nba/              # NBA data sources
│   │   └── nhl/              # NHL data sources
│   ├── transformation/        # dbt transformations
│   │   └── sports_dbt/       # dbt project
│   └── utils/                 # Shared utilities
├── tests/                      # Unit & integration tests
│   ├── unit/
│   └── integration/
├── .env.example               # Example environment variables
├── pyproject.toml            # uv project configuration
└── README.md
```

## Sports Coverage

- **NFL**: Scores, stats, teams, players
- **NBA**: Coming soon
- **NHL**: Coming soon

## Documentation

- [Architecture Overview](docs/architecture.md)
- [Setup Guide](docs/setup.md)
- [API Documentation](docs/api-docs/)

## Contributing

This is a personal learning project, but suggestions are welcome!

## License

MIT
```

### 4. Version Control Strategy

**Branch Strategy:**
```
main
├── dev (default branch for development)
├── feature/nfl-pipeline
├── feature/nba-integration
└── feature/terraform-database-module
```

**Commit Message Convention:**
```
feat(nfl): add player stats extraction
fix(terraform): correct storage account naming
docs(readme): update setup instructions
refactor(dbt): optimize team rankings model
test(airflow): add DAG validation tests