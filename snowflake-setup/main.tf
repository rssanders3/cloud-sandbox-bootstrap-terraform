# variable "snowflake_organization" {
#   description = "Snowflake organization name"
#   type        = string
#   default     = ""
# }
# variable "snowflake_account" {
#   description = "Snowflake account name"
#   type        = string
#   default     = ""
# }
# variable "snowflake_user" {
#   description = "Snowflake username"
#   type        = string
#   default     = ""
# }
# variable "snowflake_password" {
#   description = "Snowflake password"
#   type        = string
#   default     = ""
#   sensitive   = true
# }

terraform {
  required_providers {
    snowflake = {
      source = "Snowflake-Labs/snowflake"
    }
  }
}

provider "snowflake" {
  # organization_name = var.snowflake_organization
  # account_name      = var.snowflake_account
  # user              = var.snowflake_user
  # password          = var.snowflake_password
  role              = "SYSADMIN"
}

# Create a Snowflake Warehouse
resource "snowflake_warehouse" "warehouse" {
  name                = "WAREHOUSE"
  warehouse_size      = "XSMALL"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
}

# Create a Snowflake Database
resource "snowflake_database" "sample_db" {
  name = "sampe_db"
}

# Create a Schema
resource "snowflake_schema" "sample_schema" {
  database = snowflake_database.sample_db.name
  name     = "sample_schema"
}

# Create a Table
resource "snowflake_table" "titanic_passengers_raw" {
  database = snowflake_database.sample_db.name
  schema   = snowflake_schema.sample_schema.name
  name     = "titanic_passengers_raw"

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
}

# Create a File Format for CSV
resource "snowflake_file_format" "csv_format" {
  name     = "CSV_FORMAT"
  database = snowflake_database.sample_db.name
  schema   = snowflake_schema.sample_schema.name
  # type     = "CSV"
  format_type = "CSV"

  # options = {
  #   # FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  #   SKIP_HEADER                  = 1
  # }
}

# Create a Stage for Local CSV File
resource "snowflake_stage" "local_stage" {
  name     = "LOCAL_STAGE"
  database = snowflake_database.sample_db.name
  schema   = snowflake_schema.sample_schema.name
  file_format = snowflake_file_format.csv_format.name
}

# Upload CSV File to Stage
resource "snowflake_stage_file" "csv_file" {
  name     = "titanic_passengers.csv"
  stage    = snowflake_stage.local_stage.name
  source   = "/path/to/your/local/titanic_passengers.csv"  # Replace with your actual local file path
}

# Load CSV File into Table
resource "snowflake_task" "load_csv_task" {
  database  = snowflake_database.sample_db.name
  schema    = snowflake_schema.sample_schema.name
  name      = "LOAD_CSV_TASK"
  warehouse = snowflake_warehouse.warehouse.name
  sql_statement = <<EOT
    COPY INTO ${snowflake_table.titanic_passengers_raw.database}.${snowflake_table.titanic_passengers_raw.schema}.${snowflake_table.titanic_passengers_raw.name}
    FROM @${snowflake_stage.local_stage.name}/titanic_passengers.csv
    FILE_FORMAT = (FORMAT_NAME = ${snowflake_file_format.csv_format.name});
  EOT
  enabled = true
}

# # Create a Stage for CSV File
# resource "snowflake_stage" "example_stage" {
#   name     = "MY_STAGE"
#   database = snowflake_database.example_db.name
#   schema   = snowflake_schema.example_schema.name
#   url      = "s3://your-bucket-name/path/"  # Replace with your actual S3 bucket
#   storage_integration = "YOUR_S3_INTEGRATION"
# }

# # Load CSV File into Table
# resource "snowflake_task" "load_csv_task" {
#   database = snowflake_database.example_db.name
#   schema   = snowflake_schema.example_schema.name
#   name     = "LOAD_CSV_TASK"
#   warehouse = snowflake_warehouse.example_warehouse.name
#   sql_statement = <<EOT
#     COPY INTO MY_DATABASE.MY_SCHEMA.MY_TABLE
#     FROM @MY_STAGE
#     FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY='"' SKIP_HEADER=1);
#   EOT
#   enabled = true
# }