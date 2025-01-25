# cloud-sandbox-bootstrap-terraform

A Terraform Project used to Boostrap setting up components in a Sandbox Cloud Environment (AWS, Azure, GCP). In particular, a Sandbox Cloud Envionrment that gets destroyed after X number of hours and you needto restart.

# Prerequisites

### Clone the Repository to your Machine
```
git clone https://github.com/rssanders3/cloud-sandbox-bootstrap-terraform
```

### Terraform Installed on your Machine 
[Install Terraform](https://developer.hashicorp.com/terraform/install)
Check Installation
```
terraform --version
```

### Azure CLI Installed on your Machine
[Install Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
Check Installation
```
az --version
```

### AWS CLI Installed on your Machine
[Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
Check Installation
```
aws --version
```

### GCP CLI Installed on your Machine
[Install GCP CLI](https://cloud.google.com/sdk/docs/install)
Check Installation
```
gcloud --version
```

# Project Struture

Within the project there are subdirectories (example: `azure-databricks-setup`). Each subdirectory is its own Terraform Project that integrates with a particualr cloud environment (AWS, Azure, GCP) and creates a specific set of resources depending on what you are doing within the Sandbox. To work with this project, you will need to open a terminal and change directory (`cd`) into the specific project you want to use that contains the resources you need.

# Setup

For more details around what is needed to setup a specific project, see the README.md within that project. Here are some general project setup steps for Terraform:

1. Initialize the Project
```
terraform init
```

2. Validate the Terraform
```
terraform validate
```

3. Show a summary of what Terraform will do and what resources will be created (note: this step doesnt create any resources)
```
terraform plan
```

4. Trigger Terraform to create the required resources in the Cloud Envionrment
```
terraform apply
```

# Destroy

Steps you can take to "restart" in a particular environment. 

Destroy/Delete the Resources that are managed/created by Terraform
```
terraform destroy
```

Delete State Files:
```
sh clear_tfstates.sh
```
