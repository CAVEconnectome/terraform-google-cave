resource "google_container_node_pool" "sp" {
  name       = "${var.cluster_prefix}-sp"
  location   = var.zone
  cluster    = google_container_cluster.cluster.name
  initial_node_count = 1

  node_config {
    preemptible  = false
    machine_type = var.standard_machine_type
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  autoscaling {
    min_node_count = 1
    max_node_count = var.max_nodes_standard_pool
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
