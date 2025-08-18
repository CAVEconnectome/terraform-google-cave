provider "google" {
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  host                   = google_container_cluster.cluster.endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = google_container_cluster.cluster.endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
  }
}

data "google_client_config" "default" {}
