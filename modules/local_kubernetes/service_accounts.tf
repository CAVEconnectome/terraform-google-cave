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
  account_id   = "pychunkedgraph-${var.cluster_prefix}"
  display_name = "PyChunkedGraph-${var.cluster_prefix}"
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
  project = local.sql_google_project
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
# The identity is created in the cluster project; only the binding follows the
# instance into sql_google_project.
resource "google_service_account" "cloud_sql_service_account" {
  account_id   = "cloudsql-${var.cluster_prefix}-${terraform.workspace}"
  display_name = "CloudSQL-${var.cluster_prefix}-${terraform.workspace}"
}
resource "google_project_iam_member" "cloud_sql_client" {
  project = local.sql_google_project
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

# --- Ray service account ---------------------------------------------------
#
# Deliberately NOT the materialize service account. Ray's job submission API has
# no authentication at all (CVE-2023-48022, disputed upstream as intended
# behaviour), so anything that can reach a Ray head executes arbitrary Python as
# the Ray process. Mounting the materialize key -- which carries
# roles/cloudsql.admin and project-level roles/storage.objectAdmin -- would turn
# that into a full credential compromise.
#
# This identity is scoped to what the deltalake entrypoint actually needs:
# cloudsql.client (not admin) and objectAdmin on one bucket (not the project).
# Widen it one grant at a time as further entrypoints are added.

locals {
  # Bucket the Ray deltalake entrypoint writes to. Falls back to the
  # materialization dump bucket, reusing the path-stripping done at the top of
  # this file so a "bucket/path" value still yields a bare bucket name.
  ray_deltalake_bucket = var.ray_deltalake_bucket_name != "" ? (
    length(split("/", var.ray_deltalake_bucket_name)) > 1 ? split("/", var.ray_deltalake_bucket_name)[0] : var.ray_deltalake_bucket_name
  ) : local.materialization_dump_bucket_name_clean
}

resource "google_service_account" "ray_service_account" {
  count        = var.enable_ray ? 1 : 0
  account_id   = "ray-${var.cluster_prefix}-${terraform.workspace}"
  display_name = "Ray-${var.cluster_prefix}-${terraform.workspace}"
}

# Client, not admin: the entrypoint connects through the cloud-sql-proxy
# sidecar and never needs to administer the instance.
resource "google_project_iam_member" "ray_cloudsql_client" {
  count   = var.enable_ray ? 1 : 0
  project = local.sql_google_project
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.ray_service_account[0].email}"
}

# Scoped to the single deltalake bucket rather than granted at project level.
resource "google_storage_bucket_iam_member" "ray_deltalake_object_admin" {
  count  = var.enable_ray && local.ray_deltalake_bucket != "" ? 1 : 0
  bucket = local.ray_deltalake_bucket
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ray_service_account[0].email}"
}

# --- Ray bulk uploads (enable_ray_upload) ---
#
# The upload driver writes the processed CSV to the upload bucket and asks Cloud
# SQL to import it (the instance's own service account then reads the bucket);
# workers look up root ids in Bigtable. Each grant is the narrowest one that does
# that.

locals {
  ray_upload = var.enable_ray && var.enable_ray_upload
}

resource "google_storage_bucket_iam_member" "ray_upload_object_admin" {
  count  = local.ray_upload && local.materialization_upload_bucket_name_clean != "" ? 1 : 0
  bucket = local.materialization_upload_bucket_name_clean
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ray_service_account[0].email}"
}

resource "google_storage_bucket_iam_member" "ray_upload_source_reader" {
  for_each = local.ray_upload ? toset(var.ray_upload_read_buckets) : toset([])
  bucket   = each.value
  role     = "roles/storage.objectViewer"
  member   = "serviceAccount:${google_service_account.ray_service_account[0].email}"
}

# cloudsql.admin would hand the (unauthenticated) Ray head the whole instance;
# imports need only these two: import, and get to read the operation it started.
resource "google_project_iam_custom_role" "ray_cloudsql_importer" {
  count       = local.ray_upload ? 1 : 0
  project     = local.sql_google_project
  role_id     = replace("rayCloudSqlImporter_${var.cluster_prefix}_${terraform.workspace}", "-", "_")
  title       = "Ray Cloud SQL importer (${var.cluster_prefix}-${terraform.workspace})"
  description = "Import a CSV into Cloud SQL and watch the operation; for the Ray bulk upload driver."
  permissions = ["cloudsql.instances.get", "cloudsql.instances.import"]
}

resource "google_project_iam_member" "ray_cloudsql_importer" {
  count   = local.ray_upload ? 1 : 0
  project = local.sql_google_project
  role    = google_project_iam_custom_role.ray_cloudsql_importer[0].id
  member  = "serviceAccount:${google_service_account.ray_service_account[0].email}"
  # this instance only
  condition {
    title      = "app-instance-only"
    expression = "resource.name == \"projects/${local.sql_google_project}/instances/${var.sql_instance_name}\""
  }
}

resource "google_bigtable_instance_iam_member" "ray_bigtable_reader" {
  count    = local.ray_upload ? 1 : 0
  project  = var.bigtable_google_project != "" ? var.bigtable_google_project : var.project_id
  instance = var.bigtable_instance_name
  role     = "roles/bigtable.reader"
  member   = "serviceAccount:${google_service_account.ray_service_account[0].email}"
}

resource "google_service_account_key" "ray_key" {
  count              = var.enable_ray ? 1 : 0
  service_account_id = google_service_account.ray_service_account[0].name
  private_key_type   = local.sa_key_private_type
}
resource "google_secret_manager_secret" "ray_secret" {
  count     = var.enable_ray ? 1 : 0
  secret_id = "ray-google-secret-${var.cluster_prefix}-${terraform.workspace}"
  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "ray_secret_version" {
  count       = var.enable_ray ? 1 : 0
  secret      = google_secret_manager_secret.ray_secret[0].id
  secret_data = base64decode(google_service_account_key.ray_key[0].private_key)
}
