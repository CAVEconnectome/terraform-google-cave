

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

output "mesh_pool_name" {
  value = google_container_node_pool.mp.name
  description = "the name of the mesh pool in the kubernetes cluster"
}

output "cluster_ip" {
  value = google_compute_address.cluster_ip.address
  description = "The IP of the kubernetes cluster"
}