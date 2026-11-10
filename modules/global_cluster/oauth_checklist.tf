# OAuth client setup checklist.
#
# The Google OAuth 2.0 "Web application" client that middle_auth uses for
# sign-in cannot be created by Terraform — no API exists for it. The operator
# has to make it in the Cloud console and register one redirect URI per
# hostname, which is where mistakes happen.
#
# This lives on the cluster module rather than global_kubernetes on purpose: it
# depends on nothing but variables, so `terragrunt output
# oauth_setup_instructions` works *before* the secret exists. The kubernetes
# stage reads the finished secret and will refuse to plan if entries are
# missing, but by then you need this list already in hand.

locals {
  # middle_auth derives its redirect_uri from the host of the incoming request
  # (neuroglancer_auth/server.py: url_for(..., _external=True)), so every alias
  # that can serve the auth service needs its own registered entry.
  oauth_checklist_hosts = distinct(compact(concat(
    [var.global_server],
    [for k, v in var.dns_entries : v.domain_name],
  )))

  oauth_checklist_redirect_uris = sort(flatten([
    for h in local.oauth_checklist_hosts : [
      "https://${h}/auth/api/v1/oauth2callback",
      "https://${h}/sticky_auth/api/v1/oauth2callback",
    ]
  ]))

  oauth_checklist_js_origins  = sort([for h in local.oauth_checklist_hosts : "https://${h}"])
  oauth_checklist_console_url = "https://console.cloud.google.com/apis/credentials?project=${var.project_id}"
  oauth_checklist_secret_name = "auth-oauth-client-${var.cluster_prefix}"

  oauth_setup_instructions = <<-EOT
    OAuth client setup for ${var.cluster_prefix} (${var.project_id})

    1. Open ${local.oauth_checklist_console_url}
    2. Create credentials > OAuth client ID > Application type: Web application
    3. Name: cave-${var.cluster_prefix}
    4. Add these ${length(local.oauth_checklist_redirect_uris)} authorized redirect URIs:
    ${join("\n    ", local.oauth_checklist_redirect_uris)}
    5. Add these ${length(local.oauth_checklist_js_origins)} authorized JavaScript origins:
    ${join("\n    ", local.oauth_checklist_js_origins)}
    6. Save, then Download JSON.
    7. Store it in Secret Manager (the file never enters this repository):
         gcloud secrets create ${local.oauth_checklist_secret_name} \
           --project=${var.project_id} --data-file=<downloaded.json>
       For an existing secret, add a new version instead:
         gcloud secrets versions add ${local.oauth_checklist_secret_name} \
           --project=${var.project_id} --data-file=<downloaded.json>
    8. Set auth_oauth_secret_name = "${local.oauth_checklist_secret_name}" on the
       kubernetes stage, then apply it. Terraform verifies every URI above is
       registered and names any that are missing.
    9. Delete the downloaded JSON.
  EOT
}

output "oauth_redirect_uris" {
  value       = local.oauth_checklist_redirect_uris
  description = "Authorized redirect URIs that must be registered on the OAuth client"
}

output "oauth_javascript_origins" {
  value       = local.oauth_checklist_js_origins
  description = "Authorized JavaScript origins that must be registered on the OAuth client"
}

output "oauth_console_url" {
  value       = local.oauth_checklist_console_url
  description = "Cloud console credentials page where the OAuth client is created"
}

output "oauth_secret_name" {
  value       = local.oauth_checklist_secret_name
  description = "Suggested Secret Manager secret name to hold the OAuth client JSON; pass as auth_oauth_secret_name to the kubernetes stage"
}

output "oauth_setup_instructions" {
  value       = local.oauth_setup_instructions
  description = "Copy-pasteable operator checklist for creating the OAuth client. Run: terragrunt output -raw oauth_setup_instructions"
}
