resource "google_service_account" "pycg_service_account" {
  account_id   = "pychunkedgraph-${var.cluster_prefix}-${terraform.workspace}"
  display_name = "PyChunkedGraph-${var.cluster_prefix}-${terraform.workspace}"
}

resource "google_project_iam_member" "pycg_bigtable_user" {
  project = coalesce(var.bigtable_google_project, var.project_id)
  role    = "roles/bigtable.user"
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
