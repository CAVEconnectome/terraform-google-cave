resource "google_container_cluster" "cluster" {
  name                     = "${var.cluster_prefix}-global"
  location                 = var.zone
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = var.deletion_protection

  network         = var.network
  subnetwork      = var.subnetwork
  networking_mode = "VPC_NATIVE"

  release_channel {
    channel = "STABLE"
  }

  ip_allocation_policy {}

  addons_config {
    http_load_balancing { disabled = true }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  monitoring_config {
    managed_prometheus { enabled = true }
  }

  node_config {
    service_account = google_service_account.workload_identity.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "google_service_account" "workload_identity" {
  project = var.project_id

  account_id   = "svc-workident-${var.cluster_prefix}"
  display_name = "svc-workident-${var.cluster_prefix}"
}
