# Define variables for sensitive information
variable "region" {
  default = "East US"
}


terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75.0"
    }
  }

  required_version = ">= 1.5.7"
}

variable "default_tags" {
  default = {
    Environment = "Sandbox"
    Owner       = "Terraform"
    Purpose     = "Resource created for Testing"
    Project     = "cloud-sandbox-bootstrap-terraform.azure-data-factory-setup"
  }
}

# Configure the Azure provider
provider "azurerm" {
  features {}
  skip_provider_registration = true
}


# Since Data Factory and SQL Server names need to be globally unique, appending a random integer to the name
resource "random_integer" "rand" {
  min = 10000
  max = 99999
}

# Resource Group
resource "azurerm_resource_group" "resource_group" {
  name     = "resource-group"
  location = var.region
  tags     = var.default_tags
}

# Storage Account
resource "azurerm_storage_account" "account" {
  name                     = "storageaccount${random_integer.rand.result}"
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.default_tags
}

resource "azurerm_storage_container" "titanic_data" {
  name                  = "titanicdata"
  storage_account_name  = azurerm_storage_account.account.name
  container_access_type = "private"
}

# Upload only titanic_raw_part_1.csv to the storage container (note: Only the first file will be uploaded and after that you will need to manually upload the rest)
resource "azurerm_storage_blob" "titanic_raw_part_1" {
  name                   = "titanic_raw_part_1.csv" 
  storage_account_name   = azurerm_storage_account.account.name
  storage_container_name = azurerm_storage_container.titanic_data.name
  type                   = "Block"
  source                 = "data/titanic_raw_part_1.csv" # Ensure this file exists
  content_type           = "text/csv"
}

# SQL Server Credentials
variable "sql_admin_username" {
  description = "SQL Server administrator username"
  default     = "sqladminuser"
}
resource "random_password" "sql" {
  length  = 16
  special = false
}

resource "azurerm_mssql_server" "server" {
  name                         = "sql-server-${random_integer.rand.result}"
  resource_group_name          = azurerm_resource_group.resource_group.name
  location                     = azurerm_resource_group.resource_group.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = random_password.sql.result
  tags                         = var.default_tags
}

resource "azurerm_mssql_firewall_rule" "allow_all" {
  name             = "AllowAll"
  server_id        = azurerm_mssql_server.server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

# Note: The following SQL Database resource is commented out because it is NOT WORKING due to permissions. You will need to manually create the DB through the Azure Portal or Azure CLI.
# resource "azurerm_mssql_database" "db" {
#   name                = "db_1"
#   server_id           = azurerm_mssql_server.server.id
#   collation           = "SQL_Latin1_General_CP1_CI_AS"
#   geo_backup_enabled  = false
#   sku_name            = "Basic"
#   storage_account_type = "Local"
#   # min_capacity        = 2
#   auto_pause_delay_in_minutes = -1
#   # short_term_retention_policy {
#   #   retention_days = 1
#   # }
#   # long_term_retention_policy {

#   # }
#   # threat_detection_policy {
#   #   state = "Disabled"
#   # }
#   # tags                = var.default_tags
# }

# Data Factory
resource "azurerm_data_factory" "data_factory" {
  name                = "data-factory-${random_integer.rand.result}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  tags                = var.default_tags
}

# Data Factory Linked Services
resource "azurerm_data_factory_linked_service_azure_blob_storage" "blob" {
  name                = "AzureBlobStorageLinkedService"
  data_factory_id     = azurerm_data_factory.data_factory.id
  connection_string   = azurerm_storage_account.account.primary_connection_string
}

resource "azurerm_data_factory_linked_service_azure_sql_database" "sql" {
  name                = "AzureSQLDatabaseLinkedService"
  data_factory_id     = azurerm_data_factory.data_factory.id
  connection_string   = "Server=tcp:${azurerm_mssql_server.server.fully_qualified_domain_name},1433;Initial Catalog=db;User ID=${azurerm_mssql_server.server.administrator_login};Password=${random_password.sql.result};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}

# Data Factory Datasets
resource "azurerm_data_factory_dataset_delimited_text" "blob_titanic_data" {
  name                = "AzureBlobTitanicDataFolder"
  data_factory_id     = azurerm_data_factory.data_factory.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.blob.name 

  azure_blob_storage_location {
    container = azurerm_storage_container.titanic_data.name
    path      = "titanic*.csv"
  }

  column_delimiter    = ","
  row_delimiter       = "NEW"
  encoding            = "UTF-8"
  quote_character     = "\""
  escape_character    = "f"
  first_row_as_header = true
  null_value          = "NULL"
}

resource "azurerm_data_factory_dataset_azure_sql_table" "sql_titanic_raw_table" {
  name                = "AzureSQLTitanicRawTable"
  data_factory_id     = azurerm_data_factory.data_factory.id
  linked_service_id = azurerm_data_factory_linked_service_azure_sql_database.sql.id

  schema = "dbo"
  table = "titanic_raw"
}

# Data Factory Pipeline (Copy Blob CSV to SQL)
resource "azurerm_data_factory_pipeline" "copy_titanic_blob_to_sql" {
  name            = "CopyTitanicDataBlobToSql"
  data_factory_id = azurerm_data_factory.data_factory.id
  activities_json = <<ACTIVITIES
[
            {
                "name": "Get Metadata of Files in Blob",
                "type": "GetMetadata",
                "dependsOn": [],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "dataset": {
                        "referenceName": "${azurerm_data_factory_dataset_delimited_text.blob_titanic_data.name}",
                        "type": "DatasetReference"
                    },
                    "fieldList": [
                        "childItems"
                    ],
                    "storeSettings": {
                        "type": "AzureBlobStorageReadSettings",
                        "recursive": true,
                        "enablePartitionDiscovery": false
                    },
                    "formatSettings": {
                        "type": "DelimitedTextReadSettings"
                    }
                }
            },
            {
                "name": "For Each File in Blob",
                "type": "ForEach",
                "dependsOn": [
                    {
                        "activity": "Get Metadata of Files in Blob",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "userProperties": [],
                "typeProperties": {
                    "items": {
                        "value": "@activity('Get Metadata of Files in Blob').output.childItems",
                        "type": "Expression"
                    },
                    "activities": [
                        {
                            "name": "Look Up Ingestion History",
                            "type": "Lookup",
                            "dependsOn": [],
                            "policy": {
                                "timeout": "0.12:00:00",
                                "retry": 0,
                                "retryIntervalInSeconds": 30,
                                "secureOutput": false,
                                "secureInput": false
                            },
                            "userProperties": [],
                            "typeProperties": {
                                "source": {
                                    "type": "AzureSqlSource",
                                    "sqlReaderQuery": {
                                        "value": "\nSELECT COUNT(*) AS FileExists\nFROM dbo.titanic_raw_ingest\nWHERE file_ingested = '@{item().name}'",
                                        "type": "Expression"
                                    },
                                    "queryTimeout": "02:00:00",
                                    "partitionOption": "None"
                                },
                                "dataset": {
                                    "referenceName": "${azurerm_data_factory_dataset_azure_sql_table.sql_titanic_raw_table.name}",
                                    "type": "DatasetReference"
                                }
                            }
                        },
                        {
                            "name": "If File Not Ingested",
                            "type": "IfCondition",
                            "dependsOn": [
                                {
                                    "activity": "Look Up Ingestion History",
                                    "dependencyConditions": [
                                        "Succeeded"
                                    ]
                                }
                            ],
                            "userProperties": [],
                            "typeProperties": {
                                "expression": {
                                    "value": "@equals(activity('Look Up Ingestion History').output.firstRow.FileExists, 0)",
                                    "type": "Expression"
                                },
                                "ifTrueActivities": [
                                    {
                                        "name": "Load File to SQL",
                                        "type": "Copy",
                                        "dependsOn": [],
                                        "policy": {
                                            "timeout": "0.12:00:00",
                                            "retry": 0,
                                            "retryIntervalInSeconds": 30,
                                            "secureOutput": false,
                                            "secureInput": false
                                        },
                                        "userProperties": [],
                                        "typeProperties": {
                                            "source": {
                                                "type": "DelimitedTextSource",
                                                "storeSettings": {
                                                    "type": "AzureBlobStorageReadSettings",
                                                    "recursive": true,
                                                    "enablePartitionDiscovery": false,
                                                    "prefix": {
                                                        "value": "@item().name",
                                                        "type": "Expression"
                                                    }
                                                },
                                                "formatSettings": {
                                                    "type": "DelimitedTextReadSettings"
                                                }
                                            },
                                            "sink": {
                                                "type": "AzureSqlSink",
                                                "writeBehavior": "insert",
                                                "sqlWriterUseTableLock": false,
                                                "tableOption": "autoCreate",
                                                "disableMetricsCollection": false
                                            },
                                            "enableStaging": false,
                                            "translator": {
                                                "type": "TabularTranslator",
                                                "typeConversion": true,
                                                "typeConversionSettings": {
                                                    "allowDataTruncation": true,
                                                    "treatBooleanAsNumber": false
                                                }
                                            }
                                        },
                                        "inputs": [
                                            {
                                                "referenceName": "${azurerm_data_factory_dataset_delimited_text.blob_titanic_data.name}",
                                                "type": "DatasetReference"
                                            }
                                        ],
                                        "outputs": [
                                            {
                                                "referenceName": "${azurerm_data_factory_dataset_azure_sql_table.sql_titanic_raw_table.name}",
                                                "type": "DatasetReference"
                                            }
                                        ]
                                    },
                                    {
                                        "name": "Update Ingestion History",
                                        "type": "Script",
                                        "dependsOn": [
                                            {
                                                "activity": "Load File to SQL",
                                                "dependencyConditions": [
                                                    "Succeeded"
                                                ]
                                            }
                                        ],
                                        "policy": {
                                            "timeout": "0.12:00:00",
                                            "retry": 0,
                                            "retryIntervalInSeconds": 30,
                                            "secureOutput": false,
                                            "secureInput": false
                                        },
                                        "userProperties": [],
                                        "linkedServiceName": {
                                            "referenceName": "${azurerm_data_factory_linked_service_azure_sql_database.sql.name}",
                                            "type": "LinkedServiceReference"
                                        },
                                        "typeProperties": {
                                            "scripts": [
                                                {
                                                    "type": "Query",
                                                    "text": {
                                                        "value": "INSERT INTO dbo.titanic_raw_ingest (file_ingested, ingest_date)\nVALUES ('@{item().name}', CURRENT_TIMESTAMP)",
                                                        "type": "Expression"
                                                    }
                                                }
                                            ],
                                            "scriptBlockExecutionTimeout": "02:00:00"
                                        }
                                    }
                                ]
                            }
                        }
                    ]
                }
            }
        ]
ACTIVITIES
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.server.fully_qualified_domain_name
}

output "sql_admin_username" {
  value = azurerm_mssql_server.server.administrator_login
}

output "sql_admin_password" {
  value     = random_password.sql.result
  sensitive = true
}
