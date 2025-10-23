# Terraform Infrastructure - Dev Environment

This directory contains modular Terraform configurations for the sports data platform, organized by cost and usage patterns.

## Directory Structure

```
infrastructure/terraform/environments/dev/
├── core/              # Always-on resources (cheap)
│   └── main.tf        # Resource group + Storage
├── database/          # Spin up/down as needed
│   └── main.tf        # PostgreSQL
└── compute/           # Spin up/down as needed
    └── main.tf        # Airflow VM
```

## Module Overview

### 🟢 Core (Always-On)
**Cost**: ~$2-5/month
- Azure Resource Group
- Data Lake Gen2 Storage Account
- Storage containers (bronze/silver/gold for NFL, NBA, NHL)

**When to use**: Deploy once and leave running

### 🟡 Database (On-Demand)
**Cost**: ~$15-30/month when running
- PostgreSQL Flexible Server (B_Standard_B1ms)
- Sports data database

**When to use**: Spin up for development/testing, destroy when not needed

### 🔴 Compute (On-Demand)
**Cost**: ~$30-60/month when running
- Ubuntu VM (Standard_B2s)
- Pre-installed Docker & Docker Compose
- Network infrastructure (VNet, NSG, Public IP)

**When to use**: Only when running Airflow pipelines

## 🌍 Multi-Region Architecture

This infrastructure supports flexible region deployment:

| Component | Default Region | Override Variable | Recommendation |
|-----------|---------------|-------------------|----------------|
| **Core (Storage)** | `eastus` | N/A | Keep in eastus (lowest cost) |
| **Database** | `eastus` → `westus2` | `db_location_override` | Use westus2 (student account requirement) |
| **Compute** | `eastus` | `compute_location_override` | Choose based on workload (see below) |

**Compute Region Selection Guide:**
- **Data-heavy pipelines** (reading/writing lots of files): Deploy in `eastus` (same as storage)
- **Query-heavy workloads** (lots of database operations): Deploy in `westus2` (same as database)
- **Balanced workload**: Either works fine - Azure cross-region latency is typically <50ms

**Note**: Multi-region deployment is perfectly fine for your use case (batch processing). Cross-region data transfer within the same geography (US) is fast and inexpensive.

## Quick Start

### 1. Deploy Core Infrastructure (First Time)

```bash
cd core
terraform init
terraform plan
terraform apply
```

**Save the outputs** - you'll need `resource_group_name` for other modules.

### 2. Deploy Database (When Needed)

```bash
cd ../database

# Create a terraform.tfvars file
cat > terraform.tfvars <<EOF
resource_group_name = "rg-sports-data-dev"  # From core outputs
admin_password      = "YourSecurePassword123!"
EOF

terraform init
terraform plan
terraform apply
```

**⚠️ Region Restriction Error?**

If you get `LocationIsOfferRestricted` error (common with Azure student accounts), try a different region:

```bash
# Add this line to your terraform.tfvars
cat >> terraform.tfvars <<EOF
db_location_override = "westus2"  # Or try: westus, centralus, northeurope
EOF

terraform plan
terraform apply
```

Common regions that work with student accounts: `westus`, `westus2`, `centralus`, `northeurope`, `westeurope`

### 3. Deploy Compute/Airflow (When Needed)

```bash
cd ../compute

# Ensure you have an SSH key
# ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Create a terraform.tfvars file
cat > terraform.tfvars <<EOF
resource_group_name = "rg-sports-data-dev"  # From core outputs
EOF

terraform init
terraform plan
terraform apply
```

**💡 Region Performance Tip:**

Choose compute location based on your workload:

```bash
# Option A: Deploy in eastus (same as storage) - Better for data-heavy pipelines
echo 'compute_location_override = "eastus"' >> terraform.tfvars

# Option B: Deploy in westus2 (same as database) - Better for query-heavy workloads
echo 'compute_location_override = "westus2"' >> terraform.tfvars

# Option C: Don't specify (default) - Uses resource group location
```

## Cost Management

### Save Money by Destroying Resources When Not In Use

**Destroy Database** (when not developing):
```bash
cd database
terraform destroy
```

**Destroy Compute** (when not running pipelines):
```bash
cd compute
terraform destroy
```

**Keep Core Running** - it's cheap and contains your data!

### Estimated Monthly Costs

| Module   | Status    | Est. Cost/Month |
|----------|-----------|-----------------|
| Core     | Always-on | $2-5            |
| Database | On-demand | $15-30          |
| Compute  | On-demand | $30-60          |
| **Total (all running)** | | **$47-95** |
| **Total (core only)**   | | **$2-5**   |

## Common Workflows

### Development Day Workflow
```bash
# Morning: Spin up what you need
cd database && terraform apply -auto-approve
cd ../compute && terraform apply -auto-approve

# ... work on your project ...

# Evening: Destroy to save costs
cd ../compute && terraform destroy -auto-approve
cd ../database && terraform destroy -auto-approve
```

### Running Airflow Pipelines
```bash
# 1. Ensure database is running
cd database && terraform apply

# 2. Start Airflow VM
cd ../compute && terraform apply

# 3. Get the SSH command and Web UI URL from outputs
terraform output airflow_ssh_command
terraform output airflow_web_ui_url

# 4. SSH into the VM
ssh azureuser@<PUBLIC_IP>

# 5. Set up Airflow using Docker Compose
# (Follow Airflow setup instructions)
```

### Production-Ready Checklist

Before using in production, update these settings:

**Database (`database/main.tf`)**:
- [ ] Increase `sku_name` for better performance
- [ ] Enable backup retention
- [ ] Set up private networking (remove public access)
- [ ] Use Azure Key Vault for passwords

**Compute (`compute/main.tf`)**:
- [ ] Restrict NSG rules to your IP address
- [ ] Increase VM size if needed
- [ ] Set up managed identity for secure access
- [ ] Configure auto-shutdown schedules

## Environment Variables

Each module uses these common variables:

```hcl
environment    = "dev"           # Environment name
location       = "eastus"        # Azure region
project_name   = "sports-data"   # Project prefix
```

Override in `terraform.tfvars` or via command line:
```bash
terraform apply -var="environment=prod"
```

## State Management

Each module has its own Terraform state file. This allows you to:
- Deploy/destroy modules independently
- Avoid conflicts when multiple people work on different modules
- Keep state files smaller and more manageable

**Important**: State files are in `.gitignore` and should never be committed!

## Troubleshooting

### PostgreSQL "LocationIsOfferRestricted" Error
**Problem**: Azure student accounts have regional restrictions for PostgreSQL Flexible Server.

**Solution**: Override the database location in your `terraform.tfvars`:
```bash
cd database
echo 'db_location_override = "westus2"' >> terraform.tfvars
terraform apply
```

Try these regions in order: `westus2`, `westus`, `centralus`, `northeurope`, `westeurope`

### "Resource group not found" in database/compute
Make sure core infrastructure is deployed first and you've set `resource_group_name` correctly.

### SSH key not found
Generate one with:
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
```

### Can't connect to PostgreSQL
Check the firewall rules in `database/main.tf` and uncomment the local IP rule.

### Airflow VM won't start
Check NSG rules and ensure your SSH public key path is correct.

## Next Steps

After infrastructure is deployed:

1. **Connect to PostgreSQL**: Use the connection string from outputs
2. **Set up Airflow**: SSH into the VM and configure Docker Compose
3. **Configure dbt**: Point it to your PostgreSQL database
4. **Upload data**: Use Azure Storage Explorer or Azure CLI

## Support

For issues or questions:
- Check Terraform documentation: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- Review Azure pricing: https://azure.microsoft.com/en-us/pricing/calculator/
