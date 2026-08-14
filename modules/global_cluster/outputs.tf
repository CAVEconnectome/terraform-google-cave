output "cluster_name" {
  value       = google_container_cluster.cluster.name
  description = "Name of the created GKE cluster"
}

output "cluster_location" {
  value       = google_container_cluster.cluster.location
  description = "Location (zone or region) of the GKE cluster"
}

output "pool_name" {
  value       = google_container_node_pool.defaultpool.name
  description = "Name of the node pool"
}

output "cluster_ip" {
  value       = google_compute_address.cluster_ip.address
  description = "The IP of the kubernetes cluster"
}

output "dns_entries" {
  value       = var.dns_entries
  description = "DNS entries map provided to the cluster module"
}

output "workload_identity_service_account_email" {
  value       = google_service_account.workload_identity.email
  description = "Email address of the GCP service account used for Workload Identity"
}

