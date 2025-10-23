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
- Python 3.9+
- Docker & Docker Compose

### Quick Start

1. Clone the repository
```bash
git clone https://github.com/aaro21/sports-data-platform.git
cd sports-data-platform
```

2. Set up environment
```bash
cp .env.example .env
# Edit .env with your credentials
```

3. Deploy infrastructure
```bash
cd infrastructure/terraform/environments/dev
terraform init
terraform plan
terraform apply
```

4. Start Airflow locally
```bash
cd airflow
docker-compose up -d
```

5. Run dbt models
```bash
cd dbt
dbt run
```

## Project Structure
```
├── infrastructure/  # Terraform IaC
├── dbt/            # Data transformation models
├── airflow/        # Data pipeline orchestration
├── src/            # Python extraction/loading code
└── docs/           # Documentation
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