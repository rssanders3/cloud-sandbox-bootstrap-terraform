# Define variables for sensitive information
variable "region" {
  default = "East US"
}
variable "databricks_cluster_num_workers" {
  default = 2
}
variable "databricks_cluster_autotermination_minutes" {
  default = 10
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75.0"
    }
    databricks = {
      source = "databricks/databricks"
    }
  }

  required_version = ">= 1.5.7"
}

# Configure the Azure provider
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

# Resource Group
resource "azurerm_resource_group" "databricks_resource_group" {
  name     = "databricks-resource-group"
  location = var.region
}

# Databricks Workspace
resource "azurerm_databricks_workspace" "databricks_workspace" {
  name                = "databricks-workspace"
  resource_group_name = azurerm_resource_group.databricks_resource_group.name
  location            = azurerm_resource_group.databricks_resource_group.location
  sku                 = "standard"
}

# Output the workspace URL
output "databricks_workspace_url" {
  value = azurerm_databricks_workspace.databricks_workspace.workspace_url
}


provider "databricks" {
  host = azurerm_databricks_workspace.databricks_workspace.workspace_url
}

data "databricks_node_type" "smallest" {
  local_disk = true
}
data "databricks_spark_version" "latest_lts" {
  long_term_support = false
}
resource "databricks_cluster" "cluster" {
  cluster_name            = "Cluster"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = var.databricks_cluster_autotermination_minutes
  num_workers             = var.databricks_cluster_num_workers
}

output "databricks_spark_version" {
  value = data.databricks_spark_version.latest_lts.id
}
