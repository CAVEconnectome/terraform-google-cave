resource "google_service_account" "cloud_dns_sa" {
  account_id   = "clouddns-${var.cluster_prefix}"
  display_name = "clouddns-${var.cluster_prefix}"
  project      = var.project_id
}

resource "google_service_account_key" "cloud_dns_sa_key" {
  service_account_id = google_service_account.cloud_dns_sa.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_project_iam_member" "cloud_dns_role" {
  project = var.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.cloud_dns_sa.email}"
}
