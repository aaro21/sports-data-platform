# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sports Data Platform - A modern data platform for collecting, processing, and analyzing sports data across NFL, NBA, and NHL using Azure cloud infrastructure, Apache Airflow for orchestration, dbt for transformations, and PostgreSQL for storage.

**Tech Stack:**
- Infrastructure: Terraform (Azure)
- Orchestration: Apache Airflow 3.1.0 (Docker Compose on Azure VM)
- Data Transformation: dbt (planned)
- Database: PostgreSQL 15 (Azure Database for PostgreSQL Flexible Server)
- Storage: Azure Data Lake Gen2 (medallion architecture: bronze/silver/gold)

## Terraform Infrastructure Architecture

### Modular Design by Cost Pattern

The infrastructure is split into **three independent Terraform modules** based on usage and cost optimization:

```
infrastructure/terraform/environments/dev/
├── core/        # Always-on (~$3/month) - Resource group + Data Lake storage
├── database/    # On-demand (~$12/month) - PostgreSQL B_Standard_B1ms
└── compute/     # On-demand (~$70/month) - Airflow VM Standard_B2ms
```

**Critical Design Principle:** Each module has its own Terraform state file to enable independent deployment/destruction for cost savings.

### Multi-Region Strategy

Due to Azure student account restrictions, the infrastructure spans two regions:

- **Core (eastus)**: Data Lake storage - lowest cost region
- **Database (westus2)**: PostgreSQL - required due to regional restrictions
- **Compute (flexible)**: VM can deploy in either region based on workload:
  - `eastus` for data-heavy pipelines (closer to storage)
  - `westus2` for query-heavy workloads (closer to database)

**Key Variables:**
- `db_location_override` - Override database region (required for student accounts)
- `compute_location_override` - Choose compute region based on workload
- `vm_size` - VM size for Airflow (default: Standard_B2ms for 8GB RAM needed by Airflow 3.x)

### Common Terraform Commands

**Deploy Core (first time only):**
```bash
cd infrastructure/terraform/environments/dev/core
terraform init
terraform apply
```

**Deploy Database (when needed):**
```bash
cd infrastructure/terraform/environments/dev/database
# Create terraform.tfvars with:
# resource_group_name = "rg-sports-data-dev"
# admin_password = "SecurePassword123!"
# db_location_override = "westus2"
terraform init
terraform apply
```

**Deploy Compute/Airflow (when needed):**
```bash
cd infrastructure/terraform/environments/dev/compute
# Create terraform.tfvars with:
# resource_group_name = "rg-sports-data-dev"
# vm_size = "Standard_B2ms"  # 8GB RAM for Airflow 3.x
terraform init
terraform apply
```

**Destroy to Save Costs (end of day):**
```bash
cd compute && terraform destroy -auto-approve
cd ../database && terraform destroy -auto-approve
# Never destroy core - it's cheap and holds data
```

## Airflow Setup on Azure VM

The Airflow VM is pre-configured via cloud-init with Docker and Docker Compose. After deployment:

**SSH into VM:**
```bash
ssh azureuser@<PUBLIC_IP>
# Public IP from: terraform output airflow_vm_public_ip
```

**Initial Airflow Setup (on VM):**
```bash
cd ~/airflow
curl -LfO 'https://airflow.apache.org/docs/apache-airflow/stable/docker-compose.yaml'
echo "AIRFLOW_UID=$(id -u)" > .env
docker compose up airflow-init
docker compose up -d
```

**Access Airflow UI:**
- URL: `http://<PUBLIC_IP>:8080`
- Default credentials: username=`airflow`, password=`airflow`

**Important:** Airflow 3.x requires minimum 4GB RAM. The VM is configured with Standard_B2ms (8GB) to avoid memory issues.

## Data Architecture - Medallion Pattern

Storage containers follow the medallion architecture:

- **Bronze**: Raw data from APIs (`bronze-nfl`, `bronze-nba`, `bronze-nhl`)
- **Silver**: Cleaned/validated data (`silver-nfl`, `silver-nba`, `silver-nhl`)
- **Gold**: Analytics-ready aggregates (`gold-nfl`, `gold-nba`, `gold-nhl`)

## Cost Management Strategy

**Monthly costs when all running:** ~$85
- Core (storage): $3 (always-on)
- Database (B1ms): $12 (destroy when not in use)
- Compute (B2ms): $70 (destroy when not in use)

**Overnight/weekends:** Destroy database + compute = **$3/month**

## Known Issues & Workarounds

1. **PostgreSQL "LocationIsOfferRestricted" Error**: Azure student accounts can't provision PostgreSQL in `eastus`. Use `db_location_override = "westus2"` in database terraform.tfvars.

2. **Airflow "Unauthorized" Error**: Airflow 3.x needs 4GB+ RAM. Upgrade VM to Standard_B2ms if using smaller size.

3. **SSH Connection Timeout**: After VM resize, manually start VM with `az vm start --resource-group rg-sports-data-dev --name vm-airflow-dev`

4. **Terraform State Conflicts**: Each module (core/database/compute) has separate state files. Never run terraform commands from the root dev/ directory - always from within the specific module directory.

## Git Workflow

**Commit message convention:**
```
feat(component): description
fix(component): description
docs(component): description
refactor(component): description
```

**Important files in .gitignore:**
- `**/.terraform/*` - Terraform provider binaries
- `*.tfstate*` - Contains sensitive infrastructure data
- `*.tfvars` - May contain secrets like passwords

## Development Workflow

**Typical development day:**
1. Morning: `cd database && terraform apply && cd ../compute && terraform apply`
2. SSH into VM, start working on Airflow DAGs
3. Evening: `cd compute && terraform destroy && cd ../database && terraform destroy`

**When to keep running:**
- Database: When actively developing dbt models or running queries
- Compute: Only when testing/running Airflow pipelines
- Core: Always (it's cheap and holds your data)

## Future Components (Not Yet Implemented)

- `/dbt` - Data transformation models (planned)
- `/src` - Python code for data extraction (planned)
- `/airflow/dags` - Airflow DAGs for pipeline orchestration (planned)

## Azure Resources Naming Convention

- Resource Group: `rg-sports-data-{environment}`
- Storage Account: `stdatalake{environment}{random-suffix}`
- PostgreSQL: `psql-sports-data-{environment}`
- VM: `vm-airflow-{environment}`
- Network: `vnet-sports-data-{environment}`
