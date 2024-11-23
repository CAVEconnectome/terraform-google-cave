resource "local_file" "helm_values" {
  filename = "${var.helm_config_dir}/cloudsql.yaml"
  content = templatefile("${path.module}/templates/cloudsql.tpl", {
    sql_instance_name   = google_sql_database_instance.postgres.name
    postgres_user       = google_sql_user.writer.name
    terraform_state_url = var.helm_terraform_state_url
    project   = var.project_id
    postgres_secret    = "${var.environment}-postgres-password"
  })
}