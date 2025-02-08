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

# Default Tags to be applied to all resources
variable "default_tags" {
  default = {
    Environment = "Sandbox"
    Owner       = "Terraform"
    Purpose     = "Resource created for Testing"
    Project     = "cloud-sandbox-bootstrap-terraform.azure-databricks-setup"
  }
}

# Terraform Configuraion Block
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
  tags     = var.default_tags
}

# Databricks Workspace
resource "azurerm_databricks_workspace" "databricks_workspace" {
  name                = "databricks-workspace"
  resource_group_name = azurerm_resource_group.databricks_resource_group.name
  location            = azurerm_resource_group.databricks_resource_group.location
  sku                 = "standard"
  tags                = var.default_tags
}

# Output the workspace URL
output "databricks_workspace_url" {
  value = azurerm_databricks_workspace.databricks_workspace.workspace_url
}


# Configure the Databricks provider
provider "databricks" {
  host = azurerm_databricks_workspace.databricks_workspace.workspace_url
}

data "databricks_node_type" "smallest" {
  local_disk = true
}
data "databricks_spark_version" "latest_lts" {
  long_term_support = false
}
data "databricks_current_user" "user" {
}

# Databricks Shared Cluster
resource "databricks_cluster" "cluster" {
  cluster_name            = "Cluster"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = var.databricks_cluster_autotermination_minutes
  num_workers             = var.databricks_cluster_num_workers
}

# Load a CSV file into DBFS
resource "databricks_dbfs_file" "titanic_passengers_raw_csv" {
  source = "${path.module}/data/titanic_passengers_raw.csv"
  path   = "/mnt/data/titanic_passengers_raw.csv"
}

# Create a SQL Table from the CSV file
resource "databricks_sql_table" "titanic_passengers_raw" {
  name               = "titanic_passengers_raw"
  catalog_name       = "hive_metastore"
  schema_name        = "default"
  table_type         = "MANAGED"
  data_source_format = "CSV"
  storage_location   = databricks_dbfs_file.titanic_passengers_raw_csv.dbfs_path
  cluster_id         = databricks_cluster.cluster.id
  column {
    name = "PassengerId"
    type = "int"
  }
  column {
    name = "Survived"
    type = "int"
  }
  column {
    name = "Pclass"
    type = "int"
  }
  column {
    name = "Name"
    type = "string"
  }
  column {
    name = "Sex"
    type = "string"
  }
  column {
    name = "Age"
    type = "int"
  }
  column {
    name = "SibSp"
    type = "int"
  }
  column {
    name = "Parch"
    type = "string"
  }
  column {
    name = "Ticket"
    type = "string"
  }
  column {
    name = "Fare"
    type = "double"
  }
  column {
    name = "Cabin"
    type = "string"
  }
  column {
    name = "Embarked"
    type = "string"
  }
  options = {
    "skiprows" = 1
  }
  comment = "Titanic Passengers Raw Data"
}

# Upload a sample notebook
resource "databricks_notebook" "sample_ipynb" {
  source = "${path.module}/code/sample.ipynb"
  path   = "${data.databricks_current_user.user.home}/sample.ipynb"
}

# Upload a sample python script
resource "databricks_notebook" "sample_py" {
  source = "${path.module}/code/sample.py"
  path   = "${data.databricks_current_user.user.home}/sample.py"
}
