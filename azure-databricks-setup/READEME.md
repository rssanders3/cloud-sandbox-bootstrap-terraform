# Description
Creates Azure resources that support a Databricks Workspace

# Resources
* Resource Group
* Databricks Workspace
* Databricks Cluster

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

4. Trigger Terraform to create the required resources in the Cloud Envionrment
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
