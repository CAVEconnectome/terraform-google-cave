resource "google_container_node_pool" "defaultpool" {
  name       = "${var.cluster_prefix}-defaultpool"
  location   = var.zone
  cluster    = google_container_cluster.cluster.name
  initial_node_count = 1

  node_config {
    preemptible  = false
    machine_type = var.machine_type
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
  autoscaling {
    min_node_count = 1
    max_node_count = var.max_nodes
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
