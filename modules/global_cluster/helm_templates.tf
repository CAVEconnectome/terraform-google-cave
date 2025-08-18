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
    cluster               = google_container_cluster.cluster.name,
    standard_pool_name    = google_container_node_pool.sp.name,
    docker_registry       = var.docker_registry,
    data_project_id       = var.project_id,
    dns_entries           = [for k, v in var.dns_entries : v.domain_name]
  })
}

resource "local_file" "bootstrap_helmfile_example" {
  filename = "${var.helm_config_dir}/helmfile.yaml.example"
  content  = templatefile("${path.module}/templates/helmfile.tpl", {
    cluster_values     = "cluster.yaml"
    authinfo_defaults  = "authinfo.defaults.yaml"
    cloudsql_defaults  = "cloudsql.defaults.yaml"
  })
  file_permission = "0644"
}

resource "local_file" "values_authinfo" {
  filename = "${var.helm_config_dir}/authinfo.defaults.yaml"
  content  = templatefile("${path.module}/templates/authinfo.tpl", {
    global_server       = var.global_server,
    environment         = var.environment,
    domain_name         = var.domain_name,
    standard_pool_name  = google_container_node_pool.sp.name,
    docker_registry     = var.docker_registry
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
  content  = <<-EOT
redis:
  host: "ref+tfstate${var.helm_terraform_state_url}/output.pcg_redis_host"
auth:
  # oauthSecretName: "k8s-secret-name"
  # clientSecretName: "k8s-secret-name"
  # dbName: "auth"
EOT
  file_permission = "0644"
}


resource "local_file" "values_infoservice" {
  filename = "${var.helm_config_dir}/infoservice.defaults.yaml"
  content  = <<-EOT
redis:
  host: "ref+tfstate${var.helm_terraform_state_url}/output.pcg_redis_host"
infoservice:
  # caveSecretName: "k8s-secret-name"
  # dbName: "info"
EOT
  file_permission = "0644"
}

resource "local_file" "values_nglstate" {
  filename = "${var.helm_config_dir}/nglstate.defaults.yaml"
  content  = <<-EOT
redis:
  host: "ref+tfstate${var.helm_terraform_state_url}/output.pcg_redis_host"
nglstate:
  # nglstateServiceAccountSecret: "k8s-secret-name"
  # bucketPath: "gs://bucket/path"
EOT
  file_permission = "0644"
}

resource "local_file" "values_emannotationschemas" {
  filename = "${var.helm_config_dir}/emannotationschemas.defaults.yaml"
  content  = <<-EOT
emannotationschemas:
  # serviceAccountSecret: "k8s-secret-name"
EOT
  file_permission = "0644"
}
