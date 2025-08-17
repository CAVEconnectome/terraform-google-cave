############################################################
# Storage resources (GCS buckets) - shared, reusable infra
############################################################

locals {
  skeleton_cache_bucket_default = lower(replace("${var.owner}-${var.environment}-skeleton-cache", "_", "-"))
  # Extract bucket from gs://bucket[/path...] if provided, else use default
  skeleton_cache_bucket_from_path = var.skeleton_cache_cloudpath != "" ? regex("^gs://([^/]+)", var.skeleton_cache_cloudpath)[0] : ""
  skeleton_cache_bucket_name      = local.skeleton_cache_bucket_from_path != "" ? local.skeleton_cache_bucket_from_path : local.skeleton_cache_bucket_default
  skeleton_cache_cloudpath_final  = var.skeleton_cache_cloudpath != "" ? var.skeleton_cache_cloudpath : format("gs://%s", local.skeleton_cache_bucket_name)
}

resource "google_storage_bucket" "skeleton_cache" {
  name     = local.skeleton_cache_bucket_name
  project  = var.project_id
  location = var.region

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  labels = {
    environment = var.environment
    owner       = var.owner
    component   = "skeletoncache"
  }
}
