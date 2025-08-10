resource "local_file" "helm_values_cluster" {
  filename = "${var.helm_config_dir}/cluster.yaml"
  content = templatefile("${path.module}/templates/cluster.tpl", {
    terraform_state_url = var.helm_terraform_state_url,
    project_id = var.project_id,
    zone= var.zone,
    cluster = google_container_cluster.cluster.name
    mesh_pool_name = google_container_node_pool.mp.name
  })
}

resource "local_file" "nginx_values_cluster" {
  filename = "${var.helm_config_dir}/nginx-ingress-controller.yaml"
  content = templatefile("${path.module}/templates/nginx-ingress-controller.tpl", {
    cluster_ip = google_compute_address.cluster_ip.address
  })
}

# Defaults values files generated into helm_config_dir (users can create override files next to these)
resource "local_file" "values_materialize" {
  filename = "${var.helm_config_dir}/materialize.defaults.yaml"
  content  = templatefile("${path.module}/templates/materialize.tpl", {
    redis_host        = var.mat_redis_host != "" ? var.mat_redis_host : var.pcg_redis_host
    project_id        = var.project_id
    sql_instance_name = var.sql_instance_name
  })
  file_permission = "0644"
}

resource "local_file" "values_annotation" {
  filename = "${var.helm_config_dir}/annotation.defaults.yaml"
  content  = templatefile("${path.module}/templates/annotation.tpl", {
    redis_host = var.mat_redis_host != "" ? var.mat_redis_host : var.pcg_redis_host
    project_id = var.project_id
  })
  file_permission = "0644"
}

resource "local_file" "values_cloudsql" {
  filename = "${var.helm_config_dir}/cloudsql.defaults.yaml"
  content  = templatefile("${path.module}/templates/cloudsql.tpl", {
    project_id        = var.project_id
    sql_instance_name = var.sql_instance_name
  })
  file_permission = "0644"
}

resource "local_file" "values_dash" {
  filename = "${var.helm_config_dir}/dash.defaults.yaml"
  content  = templatefile("${path.module}/templates/dash.tpl", {
    project_id = var.project_id
  })
  file_permission = "0644"
}

# Bootstrap helmfile example: write helmfile.yaml.example so users can copy/modify helmfile.yaml themselves.
# This avoids Terraform ever owning helmfile.yaml and prevents clobbering user changes.
resource "local_file" "bootstrap_helmfile_example" {
  filename = "${var.helm_config_dir}/helmfile.yaml.example"
  content  = templatefile("${path.module}/templates/helmfile.tpl", {
    cluster_values           = "cluster.yaml"
    materialize_defaults     = "materialize.defaults.yaml"
    annotation_defaults      = "annotation.defaults.yaml"
    cloudsql_defaults        = "cloudsql.defaults.yaml"
    dash_defaults            = "dash.defaults.yaml"
  })
  file_permission = "0644"
}