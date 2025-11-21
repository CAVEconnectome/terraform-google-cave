terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.9.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.32.0"
    }
  }
}

data "google_client_config" "default" {}

data "google_container_cluster" "cluster" {
  name     = google_container_cluster.cluster.name
  location = google_container_cluster.cluster.location
  project  = var.project_id
  depends_on = [google_container_cluster.cluster]
}

locals {
  # Extract bucket from gs://bucket[/path...]
  skeleton_cache_bucket_name = regex("^gs://([^/]+)", var.skeleton_cache_cloudpath)[0]

  # Connection details for the newly created cluster, forcing Terraform to wait
  cluster_endpoint        = "https://${data.google_container_cluster.cluster.endpoint}"
  cluster_ca_certificate  = base64decode(data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
  gke_token               = data.google_client_config.default.access_token
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "helm" {
  kubernetes = {
    host                   = local.cluster_endpoint
    token                  = local.gke_token
    cluster_ca_certificate = local.cluster_ca_certificate
  }
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  token                  = local.gke_token
}