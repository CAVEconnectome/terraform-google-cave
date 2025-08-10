output "environment" {
  value = var.environment
}

output "owner" {
  value = var.owner
}

output "project_id" {
  value = var.project_id
}

output "region" {
  value = var.region
}


output "pcg_redis_host" {
  value       = google_redis_instance.pcg_redis.host
  description = "The ip of the pcg_redis host"
}

output "network_name" {
  value       = google_compute_network.vpc.name
  description = "The network name"
}

output "network_self_link" {
  value       = google_compute_network.vpc.self_link
  description = "The self_link of the network"
}

output "subnetwork_self_link" {
  value       = google_compute_subnetwork.subnet.self_link
  description = "The self_link of the sub-network"
}

output "sql_instance_name" {
  value       = var.sql_instance_name
  description = "The name of the SQL instance"
}

