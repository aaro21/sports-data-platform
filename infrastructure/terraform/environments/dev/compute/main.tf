# Compute Infrastructure - Spin up/down as needed
# VM for Apache Airflow orchestration

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
  description = "Azure region for compute (override if needed)"
  type        = string
  default     = null  # Will use resource group location if not specified
}

variable "compute_location_override" {
  description = "Override location for compute resources"
  type        = string
  default     = null
  # Options:
  # - "eastus" (same as storage) - Lower data transfer costs to Data Lake
  # - "westus2" (same as database) - Faster database queries
  # - null (default) - Uses resource group location
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
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key for VM access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_B2s"  # 2 vCPUs, 4GB RAM
  # Upgrade options:
  # - "Standard_B2ms" = 2 vCPUs, 8GB RAM (~$70/month) - Recommended for Airflow 3.x
  # - "Standard_B4ms" = 4 vCPUs, 16GB RAM (~$140/month)
}

# Data source to get the existing resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Local value to determine which location to use
locals {
  # Use override if specified, otherwise use resource group location
  compute_location = coalesce(var.compute_location_override, var.location, data.azurerm_resource_group.main.location)
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project_name}-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = local.compute_location
  resource_group_name = data.azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Subnet for Airflow VM
resource "azurerm_subnet" "airflow" {
  name                 = "subnet-airflow"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "airflow" {
  name                = "nsg-airflow-${var.environment}"
  location            = local.compute_location
  resource_group_name = data.azurerm_resource_group.main.name

  # SSH access
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"  # TODO: Restrict to your IP
    destination_address_prefix = "*"
  }

  # Airflow Web UI
  security_rule {
    name                       = "Airflow-UI"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"  # TODO: Restrict to your IP
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Public IP for Airflow VM
resource "azurerm_public_ip" "airflow" {
  name                = "pip-airflow-${var.environment}"
  location            = local.compute_location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Network Interface
resource "azurerm_network_interface" "airflow" {
  name                = "nic-airflow-${var.environment}"
  location            = local.compute_location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.airflow.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.airflow.id
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "airflow" {
  network_interface_id      = azurerm_network_interface.airflow.id
  network_security_group_id = azurerm_network_security_group.airflow.id
}

# Linux VM for Airflow
resource "azurerm_linux_virtual_machine" "airflow" {
  name                = "vm-airflow-${var.environment}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = local.compute_location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.airflow.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Custom data to install Docker and Docker Compose
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    # Update system
    apt-get update
    apt-get upgrade -y

    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker ${var.admin_username}

    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Create airflow directory
    mkdir -p /opt/airflow
    chown ${var.admin_username}:${var.admin_username} /opt/airflow

    echo "Setup complete! Docker and Docker Compose installed."
  EOF
  )

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Purpose     = "airflow-orchestration"
    Location    = local.compute_location
  }
}

# Outputs
output "compute_location" {
  description = "The location where compute resources were deployed"
  value       = local.compute_location
}

output "airflow_vm_public_ip" {
  description = "Public IP address of the Airflow VM"
  value       = azurerm_public_ip.airflow.ip_address
}

output "airflow_vm_private_ip" {
  description = "Private IP address of the Airflow VM"
  value       = azurerm_network_interface.airflow.private_ip_address
}

output "airflow_ssh_command" {
  description = "SSH command to connect to Airflow VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.airflow.ip_address}"
}

output "airflow_web_ui_url" {
  description = "URL for Airflow Web UI"
  value       = "http://${azurerm_public_ip.airflow.ip_address}:8080"
}
