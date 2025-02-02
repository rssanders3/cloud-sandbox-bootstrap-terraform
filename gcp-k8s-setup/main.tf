# Define variables for sensitive information
variable "project_id" {
  type = string
}
variable "region" {
  default = "us-east1"
}
variable "node_count" {
  default = 2
}


terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.18.1"
    }
  }
}

variable "default_labels" {
  type = map(string)
  default = {
    environment = "sandbox"
    owner       = "terraform"
    purpose     = "resource_created_for_testing"
    project     = "cloud-sandbox-bootstrap-terraform_gcp-k8s-setup"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_container_cluster" "cluster" {
  name                     = "cluster"
  location                 = var.region
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false
  resource_labels          = var.default_labels

  networking_mode = "VPC_NATIVE"
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  location   = var.region
  cluster    = google_container_cluster.cluster.name
  node_count = var.node_count

  node_config {
    preemptible  = false
    machine_type = "e2-medium"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}


output "get_kubeconfig" {
  value = <<EOT
  gcloud container clusters get-credentials ${google_container_cluster.cluster.name} --region ${var.region} --project ${var.project_id}
  EOT
}
