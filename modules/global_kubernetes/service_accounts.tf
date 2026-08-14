
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

# Auth Service Account
resource "google_service_account" "cloud_dns_service_account" {
  account_id   = "auth-${var.cluster_prefix}-${terraform.workspace}"
  display_name = "auth-${var.cluster_prefix}-${terraform.workspace}"
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