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
  # Public Access Prevention: omit when public read is enabled (Terraform treats null as "unset").
  # Some provider versions only accept "enforced"; leaving it unset inherits project/org policy.
  public_access_prevention    = var.skeleton_cache_public_read ? null : "enforced"

  labels = {
    environment = var.environment
    owner       = var.owner
    component   = "skeletoncache"
  }
}

# When enabled, grant public read to all objects in the bucket via IAM (additive grant).
resource "google_storage_bucket_iam_member" "skeleton_cache_public" {
  count  = var.skeleton_cache_public_read ? 1 : 0
  bucket = google_storage_bucket.skeleton_cache.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
