resource "local_file" "helm_values_cluster" {
  filename = "${var.helm_config_dir}/cluster.yaml"
  content  = templatefile("${path.module}/templates/cluster.tpl", {
    project_id            = var.project_id,
    region                = var.region,
    zone                  = var.zone,
    domain_name           = var.domain_name,
    environment           = var.environment,
    cluster_prefix        = var.cluster_prefix,
    global_server         = var.global_server,
    cluster               = data.google_container_cluster.cluster.name,
    standard_pool_name    = var.standard_pool_name,
    docker_registry       = var.docker_registry,
    data_project_id       = var.project_id,
    dns_entries           = [for k, v in var.dns_entries : v.domain_name]
  })
}

resource "local_file" "bootstrap_helmfile_example" {
  filename = "${var.helm_config_dir}/helmfile.yaml.example"
  content  = templatefile("${path.module}/templates/helmfile.tpl", {
    cluster_values     = "cluster.yaml"
    cloudsql_defaults  = "cloudsql.defaults.yaml"
  })
  file_permission = "0644"
}


resource "local_file" "values_cloudsql" {
  filename = "${var.helm_config_dir}/cloudsql.defaults.yaml"
  content  = templatefile("${path.module}/templates/cloudsql.tpl", {
    terraform_state_url  = var.helm_terraform_state_url
    secrets_project_id   = var.project_id
    postgres_credentials = "${var.environment}-postgres-credentials"
    cloudsql_sa_secret   = format("cloudsql-google-secret-%s-%s", var.cluster_prefix, terraform.workspace)
  })
  file_permission = "0644"
}

# Defaults for global services; users can override next to these files.
resource "local_file" "values_auth" {
  filename = "${var.helm_config_dir}/auth.defaults.yaml"
  content = templatefile("${path.module}/templates/auth.tpl", {
    terraform_state_url    = var.helm_terraform_state_url
    secrets_project_id     = var.project_id
    oauth_secret_name      = var.auth_oauth_secret_name
    auth_secret_key_name   = google_secret_manager_secret.auth_secret_key.secret_id
    oauth_secret_filename  = "oauth-secret.json"
    auth_url_prefix        = var.auth_url_prefix
    sticky_auth_url_prefix = var.sticky_auth_url_prefix
  })
  file_permission = "0644"

  # Do not emit helm values pointing at an OAuth client that would fail at login.
  depends_on = [terraform_data.oauth_client_gate]
}
