output "cluster_name" {
  value       = google_container_cluster.cluster.name
  description = "Name of the created GKE cluster"
}

output "cluster_location" {
  value       = google_container_cluster.cluster.location
  description = "Location (zone or region) of the GKE cluster"
}

output "standard_pool_name" {
  value       = google_container_node_pool.sp.name
  description = "Name of the standard node pool"
}

output "lightweight_pool_name" {
  value       = google_container_node_pool.lp.name
  description = "Name of the lightweight node pool"
}

output "mesh_pool_name" {
  value       = google_container_node_pool.mp.name
  description = "Name of the mesh node pool"
}

output "core_pool_name" {
  value       = google_container_node_pool.cp.name
  description = "Name of the core node pool"
}



output "l2cache_topic" {
  value       = google_pubsub_topic.l2cache.name
  description = "The name of the pubsub topic for l2cache  jobs"
}

output "l2cache_update" {
  value       = google_pubsub_subscription.l2cache_trigger.name
  description = "The name of the pubsub subscription for l2cache jobs"
}

output "pychunkedgraph_edits_topic" {
  value       = google_pubsub_topic.pychunkedgraph_edits.name
  description = "The name of the pubsub topic for pcg remesh jobs"
}

output "pychunkedgraph_remesh" {
  value       = google_pubsub_subscription.pychunkedgraph_remesh.name
  description = "The name of the pubsub subscriptions for pcg remesh jobs"
}

output "pychunkedgraph_low_priority_remesh" {
  value       = google_pubsub_subscription.pychunkedgraph_low_priority_remesh.name
  description = "The name of the pubsub subscription for low priority remesh jobs"
}

output "skeletoncache_high_priority_topic" {
  value       = google_pubsub_topic.skeletoncache_high.name
  description = "Topic for high priority skeletoncache messages"
}

output "skeletoncache_low_priority_topic" {
  value       = google_pubsub_topic.skeletoncache_low.name
  description = "Topic for low priority skeletoncache messages"
}

output "skeletoncache_dead_letter_topic" {
  value       = google_pubsub_topic.skeletoncache_dead_letter.name
  description = "Topic for dead-letter skeletoncache messages"
}

output "skeletoncache_high_priority_retrieve" {
  value       = google_pubsub_subscription.skeletoncache_high_retrieve.name
  description = "Subscription for high priority skeletoncache retrieval"
}

output "skeletoncache_low_priority_retrieve" {
  value       = google_pubsub_subscription.skeletoncache_low_retrieve.name
  description = "Subscription for low priority skeletoncache retrieval"
}

output "skeletoncache_dead_letter_retrieve" {
  value       = google_pubsub_subscription.skeletoncache_dead_letter_retrieve.name
  description = "Subscription for dead-letter skeletoncache retrieval"
}

output "skeleton_cache_bucket_name" {
  value       = local.skeleton_cache_bucket_name
  description = "Name of the GCS bucket used for SkeletonService cache (parsed from cloudpath)"
}

output "skeleton_cache_cloudpath" {
  value       = var.skeleton_cache_cloudpath
  description = "Full gs:// cloud path passed to the skeletoncache chart"
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