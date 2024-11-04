resource "local_file" "helm_values" {
  filename = var.helm_config_dir + "/cloudsql.yaml"
  content = templatefile("${path.module}/templates/cloudsql.yaml", {
    sql_instance_name   = var.sql_instance_name
    postgres_user       = var.postgres_user
    postgres_password   = var.postgres_password
    terraform_state_url    = var.helm_terraform_state_url
  })
}