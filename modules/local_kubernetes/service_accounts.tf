# Extract bucket names from bucket_path variables (paths may include /path suffix)
locals {
  # Extract bucket name from materialization_dump_bucket_path if it contains a path
  materialization_dump_bucket_name_clean = var.materialization_dump_bucket_path != "" ? (
    length(split("/", var.materialization_dump_bucket_path)) > 1 ? split("/", var.materialization_dump_bucket_path)[0] : var.materialization_dump_bucket_path
  ) : (var.materialization_dump_bucket_name != "" ? (
    length(split("/", var.materialization_dump_bucket_name)) > 1 ? split("/", var.materialization_dump_bucket_name)[0] : var.materialization_dump_bucket_name
  ) : "")
  # Extract bucket name from materialization_upload_bucket_path if it contains a path
  materialization_upload_bucket_name_clean = var.materialization_upload_bucket_path != "" ? (
    length(split("/", var.materialization_upload_bucket_path)) > 1 ? split("/", var.materialization_upload_bucket_path)[0] : var.materialization_upload_bucket_path
  ) : (var.materialization_upload_bucket_name != "" ? (
    length(split("/", var.materialization_upload_bucket_name)) > 1 ? split("/", var.materialization_upload_bucket_name)[0] : var.materialization_upload_bucket_name
  ) : "")
}

resource "google_service_account" "pycg_service_account" {
  account_id   = "pychunkedgraph-${var.cluster_prefix}-${terraform.workspace}"
  display_name = "PyChunkedGraph-${var.cluster_prefix}-${terraform.workspace}"
}

resource "google_project_iam_member" "pycg_bigtable_user" {
  project = var.bigtable_google_project != "" ? var.bigtable_google_project : var.project_id
  role    = "roles/bigtable.user"
  member  = "serviceAccount:${google_service_account.pycg_service_account.email}"
}

resource "google_project_iam_member" "pycg_datastore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.pycg_service_account.email}"
}
resource "google_project_iam_member" "pycg_pubsub_editor" {
  project = var.project_id
  role    = "roles/pubsub.editor"
  member  = "serviceAccount:${google_service_account.pycg_service_account.email}"
}
resource "google_project_iam_member" "pycg_storage_object_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.pycg_service_account.email}"
}
resource "google_project_iam_member" "pycg_cloudsql_admin" {
  project = var.project_id
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${google_service_account.pycg_service_account.email}"
}
resource "google_project_iam_member" "pycg_storage_object_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.pycg_service_account.email}"
}

resource "google_storage_bucket_iam_member" "pycg_bucket_iam_member" {
  bucket = var.pcg_bucket_name
  role   = "roles/storage.legacyBucketWriter"
  member = "serviceAccount:${google_service_account.pycg_service_account.email}"
}

resource "google_storage_bucket_iam_member" "pycg_object_owner_iam_member" {
  bucket = var.pcg_bucket_name
  role   = "roles/storage.legacyObjectOwner"
  member = "serviceAccount:${google_service_account.pycg_service_account.email}"
}

resource "google_storage_bucket_iam_member" "pycg_object_reader_iam_member" {
  bucket = var.pcg_bucket_name
  role   = "roles/storage.legacyObjectReader"
  member = "serviceAccount:${google_service_account.pycg_service_account.email}"
}

# Optional additional buckets for PyCG
resource "google_storage_bucket_iam_member" "pycg_dump_writer" {
  count  = local.materialization_dump_bucket_name_clean != "" ? 1 : 0
  bucket = local.materialization_dump_bucket_name_clean
  role   = "roles/storage.legacyBucketWriter"
  member = "serviceAccount:${google_service_account.pycg_service_account.email}"
}
resource "google_storage_bucket_iam_member" "pycg_dump_owner" {
  count  = local.materialization_dump_bucket_name_clean != "" ? 1 : 0
  bucket = local.materialization_dump_bucket_name_clean
  role   = "roles/storage.legacyObjectOwner"
  member = "serviceAccount:${google_service_account.pycg_service_account.email}"
}
resource "google_storage_bucket_iam_member" "pycg_dump_reader" {
  count  = local.materialization_dump_bucket_name_clean != "" ? 1 : 0
  bucket = local.materialization_dump_bucket_name_clean
  role   = "roles/storage.legacyObjectReader"
  member = "serviceAccount:${google_service_account.pycg_service_account.email}"
}
resource "google_storage_bucket_iam_member" "pycg_dump_bucket_owner" {
  count  = local.materialization_dump_bucket_name_clean != "" ? 1 : 0
  bucket = local.materialization_dump_bucket_name_clean
  role   = "roles/storage.legacyBucketOwner"
  member = "serviceAccount:${google_service_account.pycg_service_account.email}"
}
resource "google_storage_bucket_iam_member" "pycg_upload_writer" {
  count  = local.materialization_upload_bucket_name_clean != "" ? 1 : 0
  bucket = local.materialization_upload_bucket_name_clean
  role   = "roles/storage.legacyBucketWriter"
  member = "serviceAccount:${google_service_account.pycg_service_account.email}"
}
resource "google_storage_bucket_iam_member" "pycg_upload_owner" {
  count  = local.materialization_upload_bucket_name_clean != "" ? 1 : 0
  bucket = local.materialization_upload_bucket_name_clean
  role   = "roles/storage.legacyObjectOwner"
  member = "serviceAccount:${google_service_account.pycg_service_account.email}"
}
resource "google_storage_bucket_iam_member" "pycg_upload_reader" {
  count  = local.materialization_upload_bucket_name_clean != "" ? 1 : 0
  bucket = local.materialization_upload_bucket_name_clean
  role   = "roles/storage.legacyObjectReader"
  member = "serviceAccount:${google_service_account.pycg_service_account.email}"
}
resource "google_storage_bucket_iam_member" "pycg_upload_bucket_owner" {
  count  = local.materialization_upload_bucket_name_clean != "" ? 1 : 0
  bucket = local.materialization_upload_bucket_name_clean
  role   = "roles/storage.legacyBucketOwner"
  member = "serviceAccount:${google_service_account.pycg_service_account.email}"
}

# Skeleton Service Account
resource "google_service_account" "skeleton_service_account" {
  account_id   = "skeleton-${var.cluster_prefix}-${terraform.workspace}"
  display_name = "SkeletonService-${var.cluster_prefix}-${terraform.workspace}"
}
resource "google_project_iam_member" "skeleton_pubsub_editor" {
  project = var.project_id
  role    = "roles/pubsub.editor"
  member  = "serviceAccount:${google_service_account.skeleton_service_account.email}"
}
resource "google_project_iam_member" "skeleton_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.skeleton_service_account.email}"
}
resource "google_project_iam_member" "skeleton_monitoring_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.skeleton_service_account.email}"
}
resource "google_storage_bucket_iam_member" "skeleton_cache_writer" {
  count  = var.skeleton_cache_cloudpath != "" ? 1 : 0
  bucket = local.skeleton_cache_bucket_name
  role   = "roles/storage.legacyBucketWriter"
  member = "serviceAccount:${google_service_account.skeleton_service_account.email}"
}
resource "google_storage_bucket_iam_member" "skeleton_cache_owner" {
  count  = var.skeleton_cache_cloudpath != "" ? 1 : 0
  bucket = local.skeleton_cache_bucket_name
  role   = "roles/storage.legacyObjectOwner"
  member = "serviceAccount:${google_service_account.skeleton_service_account.email}"
}
resource "google_storage_bucket_iam_member" "skeleton_cache_reader" {
  count  = var.skeleton_cache_cloudpath != "" ? 1 : 0
  bucket = local.skeleton_cache_bucket_name
  role   = "roles/storage.legacyObjectReader"
  member = "serviceAccount:${google_service_account.skeleton_service_account.email}"
}

# Annotation Engine Service Account
resource "google_service_account" "ae_service_account" {
  account_id   = "annotation-${var.cluster_prefix}-${terraform.workspace}"
  display_name = "AnnotationEngine-${var.cluster_prefix}-${terraform.workspace}"
}
resource "google_project_iam_member" "ae_bigtable_user" {
  project = var.project_id
  role    = "roles/bigtable.user"
  member  = "serviceAccount:${google_service_account.ae_service_account.email}"
}

# Project Management Service Account
resource "google_service_account" "pmanagement_service_account" {
  account_id   = "pmanagement-${var.cluster_prefix}-${terraform.workspace}"
  display_name = "PMANAGEMENT-${var.cluster_prefix}-${terraform.workspace}"
}
resource "google_project_iam_member" "pmanagement_datastore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.pmanagement_service_account.email}"
}

# Cloud SQL Client Service Account
resource "google_service_account" "cloud_sql_service_account" {
  account_id   = "cloudsql-${var.cluster_prefix}-${terraform.workspace}"
  display_name = "CloudSQL-${var.cluster_prefix}-${terraform.workspace}"
}
resource "google_project_iam_member" "cloud_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_sql_service_account.email}"
}

# Cloud DNS Service Account
resource "google_service_account" "cloud_dns_service_account" {
  account_id   = "clouddns-${var.cluster_prefix}-${terraform.workspace}"
  display_name = "cloud-dns-${var.cluster_prefix}-${terraform.workspace}"
}
resource "google_project_iam_member" "cloud_dns_admin" {
  project = var.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.cloud_dns_service_account.email}"
}

# Create keys and store in Secret Manager (payload = JSON creds)
locals {
  sa_key_private_type = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

resource "google_service_account_key" "pycg_key" {
  service_account_id = google_service_account.pycg_service_account.name
  private_key_type   = local.sa_key_private_type
}
resource "google_secret_manager_secret" "pycg_secret" {
  secret_id = "pycg-google-secret-${var.cluster_prefix}-${terraform.workspace}"
  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "pycg_secret_version" {
  secret      = google_secret_manager_secret.pycg_secret.id
  secret_data = base64decode(google_service_account_key.pycg_key.private_key)
}

resource "google_service_account_key" "skeleton_key" {
  service_account_id = google_service_account.skeleton_service_account.name
  private_key_type   = local.sa_key_private_type
}
resource "google_secret_manager_secret" "skeleton_secret" {
  secret_id = "skeleton-google-secret-${var.cluster_prefix}-${terraform.workspace}"
  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "skeleton_secret_version" {
  secret      = google_secret_manager_secret.skeleton_secret.id
  secret_data = base64decode(google_service_account_key.skeleton_key.private_key)
}

resource "google_service_account_key" "ae_key" {
  service_account_id = google_service_account.ae_service_account.name
  private_key_type   = local.sa_key_private_type
}
resource "google_secret_manager_secret" "ae_secret" {
  secret_id = "annotation-google-secret-${var.cluster_prefix}-${terraform.workspace}"
  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "ae_secret_version" {
  secret      = google_secret_manager_secret.ae_secret.id
  secret_data = base64decode(google_service_account_key.ae_key.private_key)
}

resource "google_service_account_key" "pmanagement_key" {
  service_account_id = google_service_account.pmanagement_service_account.name
  private_key_type   = local.sa_key_private_type
}
resource "google_secret_manager_secret" "pmanagement_secret" {
  secret_id = "pmanagement-google-secret-${var.cluster_prefix}-${terraform.workspace}"
  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "pmanagement_secret_version" {
  secret      = google_secret_manager_secret.pmanagement_secret.id
  secret_data = base64decode(google_service_account_key.pmanagement_key.private_key)
}

resource "google_service_account_key" "cloudsql_key" {
  service_account_id = google_service_account.cloud_sql_service_account.name
  private_key_type   = local.sa_key_private_type
}
resource "google_secret_manager_secret" "cloudsql_secret" {
  secret_id = "cloudsql-google-secret-${var.cluster_prefix}-${terraform.workspace}"
  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "cloudsql_secret_version" {
  secret      = google_secret_manager_secret.cloudsql_secret.id
  secret_data = base64decode(google_service_account_key.cloudsql_key.private_key)
}

resource "google_service_account_key" "clouddns_key" {
  service_account_id = google_service_account.cloud_dns_service_account.name
  private_key_type   = local.sa_key_private_type
}
resource "google_secret_manager_secret" "clouddns_secret" {
  secret_id = "clouddns-google-secret-${var.cluster_prefix}-${terraform.workspace}"
  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "clouddns_secret_version" {
  secret      = google_secret_manager_secret.clouddns_secret.id
  secret_data = base64decode(google_service_account_key.clouddns_key.private_key)
}

# Read existing CAVE token from Secret Manager (must be manually created)
data "google_secret_manager_secret_version" "cave_token" {
  project = var.project_id
  secret  = var.cave_secret_name
  version = "latest"
}
