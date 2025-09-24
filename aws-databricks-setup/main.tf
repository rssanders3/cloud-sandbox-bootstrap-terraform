# Define variables
variable "databricks_account_id" {
  description = "Account ID that can be found in the dropdown under the email address in the upper-right corner of https://accounts.cloud.databricks.com/"
  default = ""
}
variable "workspace_name" {
  default = "sandbox"
}
variable "region" {
  default = "us-east-1"
}


# Terraform Configuraion Block
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    databricks = {
      source = "databricks/databricks"
    }
  }

  required_version = ">= 1.5.7"
}

provider "aws" {
  region = var.region
}

# Configure the Databricks provider
provider "databricks" {
  alias = "mws"
  host  = "https://accounts.cloud.databricks.com"
}



// register cross-account ARN
resource "databricks_mws_credentials" "credentials" {
  provider         = databricks.mws
  account_id       = var.databricks_account_id
  credentials_name = "${var.workspace_name}-creds"
  role_arn         = "arn:aws:iam::999999999999:role/Workspace-Deployment-Role"
}

// register root bucket
resource "databricks_mws_storage_configurations" "storage_configuration" {
  provider                   = databricks.mws
  account_id                 = var.databricks_account_id
  storage_configuration_name = "${var.workspace_name}-storage"
  bucket_name                = "999999999999-data-bricks-dataset-bucket-bhemccgwemhxxwexgein"
}

// register VPC
# resource "databricks_mws_networks" "netowrks" {
#   provider           = databricks.mws
#   account_id         = var.databricks_account_id
#   network_name       = "${var.workspace_name}-network"
#   vpc_id             = var.vpc_id
#   subnet_ids         = var.subnets_private
#   security_group_ids = [var.security_group]
# }

// create workspace in given VPC with DBFS on root bucket
resource "databricks_mws_workspaces" "workspace" {
  provider       = databricks.mws
  account_id     = var.databricks_account_id
  workspace_name = var.workspace_name
  aws_region     = var.region

  credentials_id           = databricks_mws_credentials.credentials.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.storage_configuration.storage_configuration_id
  # network_id               = databricks_mws_networks.networks.network_id

  token {}
}






# resource "aws_s3_bucket" "databricks_root_bucket" {
#   bucket = "databricks-root-bucket"
# }

# resource "aws_iam_role" "databricks_role" {
#   name = "databricks-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "databricks.amazonaws.com"
#       }
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "databricks_policy" {
#   role       = aws_iam_role.databricks_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
# }