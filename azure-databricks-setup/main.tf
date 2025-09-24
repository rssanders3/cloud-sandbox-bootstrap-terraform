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

# Databricks Access Toekn
resource "databricks_token" "personal_token" {
  comment  = "Provisioned by Terraform"
  // 100 day token
  lifetime_seconds = 8640000
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

# Upload a python script to create a Test Table
resource "databricks_notebook" "create_titanic_table_py" {
  source = "${path.module}/code/create_titanic_table.py"
  path   = "${data.databricks_current_user.user.home}/create_titanic_table.py"
}


resource "databricks_job" "create_titanic_table_job" {
  name = "Create Titanic Table Job"

  task {
    task_key = "create_titanic_table"
    description = "Job to create Titanic table from CSV file"
    existing_cluster_id = databricks_cluster.cluster.id
    notebook_task {
      notebook_path = databricks_notebook.create_titanic_table_py.path
    }
  }
}

resource "null_resource" "trigger_create_titanic_table_job" {
  provisioner "local-exec" {
    command = <<EOT
      databricks jobs run-now ${databricks_job.create_titanic_table_job.id}
    EOT
    environment = {
      DATABRICKS_HOST  = azurerm_databricks_workspace.databricks_workspace.workspace_url
      DATABRICKS_TOKEN = databricks_token.personal_token.token_value
    }
  }
  depends_on = [databricks_job.create_titanic_table_job]
}
