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