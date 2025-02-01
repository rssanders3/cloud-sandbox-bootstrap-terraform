# Description
Creates a Kubernetes (K8s) Cluster in Google Cloud and all supporting resources

# Resources
* Google Kubernetes Engine Cluster and Node Pool

# Prerequisites

You may be required to Enable the Kubernestes Engine API from the GCP Console before being able to run this

To connect to the Kubernetest Cluster from your cli using kubectl, you will need to install gke-gcloud-auth-plugin:
```
gcloud components install gke-gcloud-auth-plugin
```

# Setup

1. Initialize Terraform and Setup Project
```
terraform init
```

2. Set an Environemnt Variable and Login to GCP using CLI
```
export TF_VAR_project_id="<gcp-project-id>"
```
Note: Update the values between the < > with your values

```
gcloud auth application-default login
```
Running this command will open up a Web Browser window where you can enter your credentials

```
gcloud config set project <gcp-project-id>
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
