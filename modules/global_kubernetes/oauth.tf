# Google OAuth 2.0 "Web application" client used by middle_auth for sign-in.
#
# There is no API — and therefore no Terraform resource — for creating this kind
# of OAuth client. `google_iap_client` cannot express redirect URIs, and
# `google_iam_oauth_client` is a Workforce Identity Federation object, not a
# sign-in client. So the client is created by hand in the console and its JSON
# is stored in Secret Manager out of band, exactly like the postgres credentials
# (see QUICKSTART.md). This module takes only the secret's *name*, which keeps
# every credential out of the configuration repository.
#
# See GLOBAL_OAUTH_SETUP.md for the operator procedure.

data "google_secret_manager_secret_version" "auth_oauth_client" {
  project = var.project_id
  secret  = var.auth_oauth_secret_name
}

locals {
  # middle_auth derives its redirect_uri from the host of the incoming request
  # (neuroglancer_auth/server.py: url_for(..., _external=True)), so every
  # hostname that can serve the auth service needs its own registered entry.
  oauth_hosts = distinct(concat(
    [var.global_server],
    [for k, v in var.dns_entries : v.domain_name],
  ))

  oauth_redirect_uris = sort(flatten([
    for h in local.oauth_hosts : [
      "https://${h}/${var.auth_url_prefix}/api/v1/oauth2callback",
      "https://${h}/${var.sticky_auth_url_prefix}/api/v1/oauth2callback",
    ]
  ]))

  oauth_js_origins  = sort([for h in local.oauth_hosts : "https://${h}"])
  oauth_console_url = "https://console.cloud.google.com/apis/credentials?project=${var.project_id}"

  # The downloaded client JSON carries the registered redirect URIs and origins,
  # which is what lets Terraform check that the console step was done in full.
  oauth_client_web = try(
    jsondecode(data.google_secret_manager_secret_version.auth_oauth_client.secret_data).web,
    null
  )

  # Derived from a sensitive attribute, so Terraform taints these. They are
  # public URLs, not secrets — unwrap so they can appear in error messages.
  oauth_missing_uris    = nonsensitive(setsubtract(local.oauth_redirect_uris, try(local.oauth_client_web.redirect_uris, [])))
  oauth_missing_origins = nonsensitive(setsubtract(local.oauth_js_origins, try(local.oauth_client_web.javascript_origins, [])))
}

# Gate: fail the plan with an actionable message rather than letting a
# half-registered OAuth client reach the cluster and break login at runtime.
resource "terraform_data" "oauth_client_gate" {
  input = nonsensitive(try(local.oauth_client_web.client_id, ""))

  lifecycle {
    precondition {
      condition     = local.oauth_client_web != null
      error_message = <<-EOT
        Secret "${var.auth_oauth_secret_name}" does not contain a Google OAuth client JSON.
        Expected an object with a top-level "web" key holding client_id and client_secret.
        Create the client at ${local.oauth_console_url} and store it with:
          gcloud secrets versions add ${var.auth_oauth_secret_name} --data-file=<downloaded.json>
      EOT
    }

    precondition {
      condition     = length(local.oauth_missing_uris) == 0 && length(local.oauth_missing_origins) == 0
      error_message = <<-EOT
        The OAuth client is missing entries. Edit it at ${local.oauth_console_url}

        Missing authorized redirect URIs (${length(local.oauth_missing_uris)}):
        ${join("\n", local.oauth_missing_uris)}

        Missing authorized JavaScript origins (${length(local.oauth_missing_origins)}):
        ${join("\n", local.oauth_missing_origins)}

        Then re-download the JSON and run:
          gcloud secrets versions add ${var.auth_oauth_secret_name} --data-file=<downloaded.json>
      EOT
    }
  }
}

# Flask session signing key for middle_auth. Generated once and kept in Secret
# Manager: rotating it invalidates every active session, so it must be stable
# across releases. Replaces the unsubstituted ${AUTHSERVICE_SECRET_KEY}
# placeholder that the legacy CAVEdeployment configmaps carried.
resource "random_password" "auth_secret_key" {
  length  = 64
  special = false
}

resource "google_secret_manager_secret" "auth_secret_key" {
  secret_id = format("auth-secret-key-%s-%s", var.cluster_prefix, terraform.workspace)
  project   = var.project_id
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "auth_secret_key" {
  secret      = google_secret_manager_secret.auth_secret_key.id
  secret_data = random_password.auth_secret_key.result

  lifecycle {
    ignore_changes = [secret_data]
  }
}
