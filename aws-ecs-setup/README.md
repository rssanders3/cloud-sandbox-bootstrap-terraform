# Description
Creates AWS resources that support an Elastic Container Service (Kubernetes) Instance

# Resources
* Elastic Container Registry Repo
* Elastic Container Service Cluster

# Setup

1. Initialize Terraform and Setup Project
```
terraform init
```

2. Set Environment Variables for Login
```
export AWS_ACCESS_KEY_ID="<your-aws-access-key-id>"
export AWS_SECRET_ACCESS_KEY="<your-aws-secret-access-key>"
export AWS_REGION="<region-you-are-working-in>"
```
Note: Update the values between the < > with your values

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

Unsert the Environemtn Variables
```
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_REGION
```
