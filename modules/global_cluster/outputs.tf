output "cluster_name" {
  value       = google_container_cluster.cluster.name
  description = "The name of the GKE cluster"
}

output "ingress_ip" {
  value       = google_compute_address.cluster_ip.address
  description = "Static ingress IP for the cluster"
}
