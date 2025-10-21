# Configure Terraform
terraform {
  required_version = ">= 1.5"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  
  # Skip automatic resource provider registration
  # (Azure student accounts sometimes have conflicts with this)
  skip_provider_registration = true
}

# Variables
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "sports-data"
}

# Resource Group - Our first resource!
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Generate a random string for unique storage account name
# Storage account names must be globally unique across ALL of Azure
resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}

# Storage Account for Data Lake
resource "azurerm_storage_account" "data_lake" {
  name                     = "stdatalake${var.environment}${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"  # Locally Redundant Storage (cheapest)
  account_kind             = "StorageV2"
  is_hns_enabled          = true    # Hierarchical namespace for Data Lake Gen2

  # Security settings
  https_traffic_only_enabled = true
  min_tls_version           = "TLS1_2"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Purpose     = "data-lake"
  }
}

# Bronze layer containers (raw data from APIs)
resource "azurerm_storage_container" "bronze_nfl" {
  name                  = "bronze-nfl"
  storage_account_name  = azurerm_storage_account.data_lake.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "bronze_nba" {
  name                  = "bronze-nba"
  storage_account_name  = azurerm_storage_account.data_lake.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "bronze_nhl" {
  name                  = "bronze-nhl"
  storage_account_name  = azurerm_storage_account.data_lake.name
  container_access_type = "private"
}

# Silver layer containers (cleaned data)
resource "azurerm_storage_container" "silver_nfl" {
  name                  = "silver-nfl"
  storage_account_name  = azurerm_storage_account.data_lake.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "silver_nba" {
  name                  = "silver-nba"
  storage_account_name  = azurerm_storage_account.data_lake.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "silver_nhl" {
  name                  = "silver-nhl"
  storage_account_name  = azurerm_storage_account.data_lake.name
  container_access_type = "private"
}

# Gold layer containers (analytics-ready data)
resource "azurerm_storage_container" "gold_nfl" {
  name                  = "gold-nfl"
  storage_account_name  = azurerm_storage_account.data_lake.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "gold_nba" {
  name                  = "gold-nba"
  storage_account_name  = azurerm_storage_account.data_lake.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "gold_nhl" {
  name                  = "gold-nhl"
  storage_account_name  = azurerm_storage_account.data_lake.name
  container_access_type = "private"
}

# Outputs - So we can see what was created
output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "The location of the resource group"
  value       = azurerm_resource_group.main.location
}

output "resource_group_id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "storage_account_name" {
  description = "The name of the data lake storage account"
  value       = azurerm_storage_account.data_lake.name
}

output "storage_account_id" {
  description = "The ID of the data lake storage account"
  value       = azurerm_storage_account.data_lake.id
}

output "data_lake_endpoint" {
  description = "The Data Lake Gen2 endpoint URL"
  value       = azurerm_storage_account.data_lake.primary_dfs_endpoint
}

output "storage_account_primary_endpoint" {
  description = "The primary blob endpoint"
  value       = azurerm_storage_account.data_lake.primary_blob_endpoint
}

output "bronze_containers" {
  description = "List of bronze layer containers"
  value = [
    azurerm_storage_container.bronze_nfl.name,
    azurerm_storage_container.bronze_nba.name,
    azurerm_storage_container.bronze_nhl.name
  ]
}

output "silver_containers" {
  description = "List of silver layer containers"
  value = [
    azurerm_storage_container.silver_nfl.name,
    azurerm_storage_container.silver_nba.name,
    azurerm_storage_container.silver_nhl.name
  ]
}

output "gold_containers" {
  description = "List of gold layer containers"
  value = [
    azurerm_storage_container.gold_nfl.name,
    azurerm_storage_container.gold_nba.name,
    azurerm_storage_container.gold_nhl.name
  ]
}