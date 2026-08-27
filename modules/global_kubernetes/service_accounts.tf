locals {
  sa_key_private_type = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

# Cloud SQL Client Service Account
# Key is consumed by the cloudsql-proxy sidecar in every global service chart,
# via ref+gcpsecrets against the Secret Manager secret created below.
resource "google_service_account" "cloud_sql_service_account" {
  account_id   = "cloudsql-${var.cluster_prefix}-${terraform.workspace}"
  display_name = "CloudSQL-${var.cluster_prefix}-${terraform.workspace}"
  project      = var.project_id
}

resource "google_project_iam_member" "cloud_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_sql_service_account.email}"
}

resource "google_service_account_key" "cloudsql_key" {
  service_account_id = google_service_account.cloud_sql_service_account.name
  private_key_type   = local.sa_key_private_type
}

resource "google_secret_manager_secret" "cloudsql_secret" {
  secret_id = format("cloudsql-google-secret-%s-%s", var.cluster_prefix, terraform.workspace)
  project   = var.project_id
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "cloudsql_secret_version" {
  secret      = google_secret_manager_secret.cloudsql_secret.id
  secret_data = base64decode(google_service_account_key.cloudsql_key.private_key)
}

# Cloud DNS Service Account
# Key is passed straight into the cert-manager-google chart (see
# cert_manager_issuer.tf), which materializes its own Kubernetes secret, so this
# one does not need a Secret Manager copy.
resource "google_service_account" "cloud_dns_service_account" {
  account_id   = "clouddns-${var.cluster_prefix}-${terraform.workspace}"
  display_name = "clouddns-${var.cluster_prefix}-${terraform.workspace}"
  project      = var.project_id
}

resource "google_project_iam_member" "cloud_dns_admin" {
  project = var.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.cloud_dns_service_account.email}"
}

resource "google_service_account_key" "clouddns_key" {
  service_account_id = google_service_account.cloud_dns_service_account.name
  private_key_type   = local.sa_key_private_type
}

# NOTE: middle_auth needs no service account of its own. It reads only
# AUTH_OAUTH_SECRET (the OAuth client JSON) — see neuroglancer_auth/server.py —
# and its database access goes through the cloudsql-proxy sidecar above. The
# legacy AUTH_SERVICE_ACCOUNT_SECRET / OAUTH_CLIENT_SECRET pair in
# CAVEdeployment was never read by the application.
