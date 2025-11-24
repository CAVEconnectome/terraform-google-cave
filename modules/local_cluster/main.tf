terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.9.0"
    }
  }
}
locals {
  skeleton_cache_bucket_name = regex("^gs://([^/]+)", var.skeleton_cache_cloudpath)[0]
}
provider "google" {
  project = var.project_id
  region  = var.region
}