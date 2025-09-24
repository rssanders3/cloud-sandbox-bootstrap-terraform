
# Useful Docs:
https://kubernetes.io/docs/reference/kubectl/quick-reference/

# List Availabel Clusters you have configuraions for:
kubectl config get-contexts

Will also show the cluster you are connected to with the '*' in front of it

Also:
kubectl config current-context

# Set Cluster to use
kubectl config use-context <context-or-cluster>

# Get Cluster/Node Status

# Jobs

## Get Jobs
```
kubectl get pods
```
## Create Job
Simple:
```
kubectl create job hello --image=busybox:1.28 -- echo "Hello World"
```
Airflow:
```
kubectl create job apache-airflow --image=apache/airflow:2.2.2 -- airflow standalone
```

# Pods

## Get all pods
```
kubectl get pods
```

## get a specific pod
```
```

# Logs
```
kubectl logs <pod>
```




# Enable port forwarding
From loca:
```
kubectl port-forward apache-airflow-d8nc6 8080:8080
```

#

Look into
Secrets
