# Database Infrastructure - Spin up/down as needed
# PostgreSQL for dbt transformations and analytics

# Configure Terraform
terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

# Variables
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for database (override if eastus doesn't work)"
  type        = string
  default     = null  # Will use resource group location if not specified
}

variable "db_location_override" {
  description = "Override location for database if region restrictions apply"
  type        = string
  default     = null
  # Common alternatives for Azure student accounts:
  # "westus", "westus2", "centralus", "northeurope", "westeurope"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "sports-data"
}

variable "resource_group_name" {
  description = "Name of the resource group (from core)"
  type        = string
}

variable "admin_username" {
  description = "PostgreSQL admin username"
  type        = string
  default     = "psqladmin"
}

variable "admin_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}

variable "server_name_suffix" {
  description = "Optional suffix for server name (useful for recreating deleted servers)"
  type        = string
  default     = ""
}

# Data source to get the existing resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Local value to determine which location to use
locals {
  # Use override if specified, otherwise use resource group location
  db_location = coalesce(var.db_location_override, var.location, data.azurerm_resource_group.main.location)
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${var.project_name}-${var.environment}${var.server_name_suffix != "" ? "-${var.server_name_suffix}" : ""}"
  resource_group_name    = data.azurerm_resource_group.main.name
  location              = local.db_location
  version               = "15"
  administrator_login    = var.admin_username
  administrator_password = var.admin_password
  zone                   = "3"  # Availability zone

  # Cost-optimized configuration for dev
  sku_name   = "B_Standard_B1ms"  # Burstable, 1 vCore, 2GB RAM
  storage_mb = 32768               # 32GB storage (minimum)

  # Auto-pause when idle (saves cost)
  backup_retention_days = 7

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Purpose     = "analytics-database"
    Location    = local.db_location
  }
}

# Database for sports data
resource "azurerm_postgresql_flexible_server_database" "sports_data" {
  name      = "sports_data"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# Firewall rule to allow Azure services
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Optional: Firewall rule for your local IP (update as needed)
# Uncomment and set your IP address for local development
# resource "azurerm_postgresql_flexible_server_firewall_rule" "local_dev" {
#   name             = "allow-local-dev"
#   server_id        = azurerm_postgresql_flexible_server.main.id
#   start_ip_address = "YOUR.IP.ADDRESS.HERE"
#   end_ip_address   = "YOUR.IP.ADDRESS.HERE"
# }

# Outputs
output "database_location" {
  description = "The location where the database was deployed"
  value       = local.db_location
}

output "postgresql_server_name" {
  description = "The name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "postgresql_server_fqdn" {
  description = "The FQDN of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgresql_database_name" {
  description = "The name of the sports data database"
  value       = azurerm_postgresql_flexible_server_database.sports_data.name
}

output "postgresql_connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = "postgresql://${var.admin_username}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.sports_data.name}"
  sensitive   = true
}
