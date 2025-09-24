# Description
Creates a Snowflake Cluster and all supporting resources

# Resources
* Snowflake Cluster
* Snowflake Schema, Database, and Table

# Setup

1. Initialize Terraform and Setup Project
```
terraform init
```

2. Set an Environemnt Variable and Login to GCP using CLI
```
export TF_VAR_snowflake_organization=""
export TF_VAR_snowflake_account=""
export TF_VAR_snowflake_user=""
export TF_VAR_snowflake_password=""
```

#https://rjzxees-user30.snowflakecomputing.com/console/login

export SNOWFLAKE_AUTHENTICATOR=""
export SNOWFLAKE_HOST=""

```
export SNOWFLAKE_HOST="temp.snowflakecomputing.com"
export SNOWFLAKE_ORGANIZATION_NAME=""
#export SNOWFLAKE_ACCOUNT_NAME=""
export SNOWFLAKE_ACCOUNT_NAME=""
export SNOWFLAKE_USER=""
export SNOWFLAKE_PASSWORD=''
```



```
export SNOWFLAKE_HOST="temp.central-india.azure.snowflakecomputing.com"
export SNOWFLAKE_ORGANIZATION_NAME=""
export SNOWFLAKE_ACCOUNT_NAME=""
export SNOWFLAKE_USER=""
export SNOWFLAKE_PASSWORD=''
```


Note: Update the values between the < > with your values

Note:
SELECT CURRENT_ORGANIZATION_NAME();
SELECT CURRENT_ACCOUNT_NAME();
SELECT CURRENT_USER();



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

# Useful Links

[Terraform: Snowflake Provider](https://registry.terraform.io/providers/Snowflake-Labs/snowflake/latest/docs)