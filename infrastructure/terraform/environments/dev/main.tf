# ⚠️ DEPRECATED - This file is no longer used
#
# The Terraform infrastructure has been reorganized into modular components.
# Please use the new directory structure instead:
#
# infrastructure/terraform/environments/dev/
# ├── core/              # Always-on resources (Resource Group + Storage)
# │   └── main.tf
# ├── database/          # On-demand PostgreSQL
# │   └── main.tf
# └── compute/           # On-demand Airflow VM
#     └── main.tf
#
# See README.md for usage instructions.
#
# To migrate:
# 1. DO NOT destroy resources using this file
# 2. Import existing resources into the new modules if needed
# 3. Deploy new resources using the modular structure
#
# For more information, see:
# infrastructure/terraform/environments/dev/README.md

# This file is kept for reference only
# All resources have been moved to the modular structure
