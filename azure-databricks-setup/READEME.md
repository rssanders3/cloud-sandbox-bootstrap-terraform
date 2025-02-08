# Description
Creates Azure resources that support a Databricks Workspace

# Resources
* Resource Group
* Databricks Workspace
* Databricks Cluster
* Other Databricks Resources - Sample Notebook, Sample Data

# Setup

1. Initialize Terraform and Setup Project
```
terraform init
```

2. Login to Azure from the CLI to obtain Session information - used by Terraform to check status and create resources
```
az login
```
Running this command will open up a Web Browser window where you can enter your credentials
Afterwards, from the commandline you will need to select which subscription you want to sign into

3. Show a summary of what Terraform will do and what resources will be created (note: this step doesnt create any resources)
```
terraform plan
```

4. Trigger Terraform to create the required Azure Resources first since Databricks fails if the workspace doesnt exist
```
terraform apply -target=azurerm_databricks_workspace.databricks_workspace
```

5. Trigger Terraform to create the required resources in the Cloud Envionrment
```
terraform apply
```

# Destory

Destroy/Delete the Resources that are managed/created by Terraform
```
terraform destroy
```

Remove Subscription
```
az account clear
```

# Other Useful Commands

Show the Azure Subscription you are currently configured to access from Azure CLI
```
az account show
```

# Useful Links

[Getting Started with Terraform on Azure](https://medium.com/navara/with-terraform-getting-started-on-microsoft-azure-69f6e0b608ec)

[Terraform: Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
[Terraform: Databricks Provider](https://registry.terraform.io/providers/databricks/databricks/latest/docs)

# Time it Takes

## Create Resources
Most resources can be created quickly. The following are the resources that take longer to create and how long they've typically taken:

* azurerm_databricks_workspace.databricks_workspace: Creation complete after 2m15s
* databricks_cluster.cluster: Creation complete after 4m12s

## Destroy Resources
Most resources can be destroyed quickly. The following are the resources that take longer to destroy and how long they've typically taken:

* azurerm_databricks_workspace.databricks_workspace: Destruction complete after 6m10s
