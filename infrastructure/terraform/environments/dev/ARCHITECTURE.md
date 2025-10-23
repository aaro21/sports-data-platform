# Multi-Region Architecture Overview

## Current Deployment

```
┌─────────────────────────────────────────────────────────────┐
│                   Azure Subscription                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────┐        ┌──────────────────┐           │
│  │   East US        │        │   West US 2      │           │
│  ├──────────────────┤        ├──────────────────┤           │
│  │                  │        │                  │           │
│  │  🟢 Core         │        │  🟡 Database     │           │
│  │  - Resource Grp  │        │  - PostgreSQL    │           │
│  │  - Data Lake     │        │    (required)    │           │
│  │  - Containers    │        │                  │           │
│  │                  │        └──────────────────┘           │
│  │  🔴 Compute      │                                        │
│  │  (optional)      │         OR                            │
│  │  - Airflow VM    │                                        │
│  │  - VNet/NSG      │        ┌──────────────────┐           │
│  │                  │        │   West US 2      │           │
│  └──────────────────┘        ├──────────────────┤           │
│                               │  🔴 Compute      │           │
│                               │  (optional)      │           │
│                               │  - Airflow VM    │           │
│                               │  - VNet/NSG      │           │
│                               └──────────────────┘           │
└─────────────────────────────────────────────────────────────┘

    │                              │
    └──────────────┬───────────────┘
                   │
            Fast cross-region
            communication
            (~20-50ms latency)
```

## Region Selection Matrix

| Workload Type | Storage Location | Database Location | Compute Location | Reasoning |
|---------------|------------------|-------------------|------------------|-----------|
| **Data Ingestion** | eastus | westus2 | **eastus** | Minimize data transfer from APIs → Storage |
| **Data Transformation** | eastus | westus2 | **westus2** | Balance between DB queries and storage I/O |
| **Analytics/Reports** | eastus | westus2 | **westus2** | Heavy database queries, light storage reads |
| **Balanced Pipeline** | eastus | westus2 | **Either** | Both work fine for mixed workloads |

## Network Flow Examples

### Example 1: Data Ingestion Pipeline (Compute in eastus)
```
API → Airflow (eastus) → Data Lake (eastus) ✅ Low latency
                       ↓
                  PostgreSQL (westus2) ⚠️ Cross-region (~30ms)
```

### Example 2: Analytics Pipeline (Compute in westus2)
```
Data Lake (eastus) → Airflow (westus2) ⚠️ Cross-region (~30ms)
                   ↓
              PostgreSQL (westus2) ✅ Low latency
```

## Cost Implications

### Data Transfer Costs
- **Intra-region** (e.g., eastus → eastus): FREE ✅
- **Inter-region** (e.g., eastus → westus2): ~$0.02/GB
- **Outbound to internet**: ~$0.087/GB

### Monthly Cost Estimate
Assuming 100GB data transfer/month between regions:
- Cross-region transfer: 100GB × $0.02 = **$2/month**
- This is negligible compared to compute/database costs ($50-100/month)

## Performance Benchmarks

| Operation | Same Region | Cross Region | Impact |
|-----------|-------------|--------------|--------|
| Storage read/write | <5ms | ~25-40ms | Low for batch |
| Database query | <10ms | ~30-50ms | Low for OLAP |
| API calls | <20ms | ~40-70ms | Negligible |

**Conclusion**: For batch processing workloads, cross-region latency is acceptable.

## Recommendations by Use Case

### 1. Learning/Development (Current Setup)
- **Core**: eastus (cheapest storage)
- **Database**: westus2 (required by Azure student)
- **Compute**: Don't deploy yet (use local Docker instead)
- **Monthly Cost**: $17-35 (core + database only)

### 2. Running Data Pipelines
- **Core**: eastus
- **Database**: westus2
- **Compute**:
  - Use **eastus** if ingesting >10GB/day
  - Use **westus2** if running many dbt transformations
  - Default to **eastus** (same as storage)
- **Monthly Cost**: $47-95 (all running)

### 3. Production (Future)
- Consider deploying all in **westus2** for simplicity
- Use private endpoints for security
- Enable zone redundancy
- **Monthly Cost**: $200-400+ (higher SKUs, redundancy)

## How to Switch Compute Region

### Deploy in eastus (same as storage):
```bash
cd compute
cat > terraform.tfvars <<EOF
resource_group_name = "rg-sports-data-dev"
# Don't set compute_location_override - defaults to eastus
EOF
terraform apply
```

### Deploy in westus2 (same as database):
```bash
cd compute
cat > terraform.tfvars <<EOF
resource_group_name = "rg-sports-data-dev"
compute_location_override = "westus2"
EOF
terraform apply
```

### Switch between regions:
```bash
# Destroy existing
terraform destroy

# Update terraform.tfvars with new location
# Re-deploy
terraform apply
```

## Future Considerations

### When to consolidate to single region:
- ✅ Moving to production
- ✅ Latency becomes measurable issue
- ✅ Cost optimization (reduce cross-region transfer)
- ✅ Simpler networking/security model

### When multi-region makes sense:
- ✅ Disaster recovery requirements
- ✅ Geographic data residency requirements
- ✅ Regional service availability (like current PostgreSQL restriction)
- ✅ Latency optimization for global users

## Monitoring

Track these metrics to decide if you need to consolidate:

1. **Cross-region data transfer costs** (Azure Cost Management)
2. **Pipeline execution times** (Airflow logs)
3. **Database query latency** (PostgreSQL slow query log)
4. **Storage I/O latency** (Azure Monitor)

If cross-region costs exceed $10/month or latency impacts SLAs, consider consolidating.
