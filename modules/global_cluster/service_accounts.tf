

# CAVE token secret (cave-secret.json)
resource "google_secret_manager_secret" "cave_secret" {
  secret_id  = "cave-secret-${var.cluster_prefix}-${terraform.workspace}"
  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "cave_secret_version" {
  secret      = google_secret_manager_secret.cave_secret.id
  secret_data = jsonencode({ token = var.cave_token })
}
