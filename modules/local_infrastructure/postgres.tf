resource "google_sql_database_instance" "postgres" {
  name             = var.sql_instance_name
  region           = var.region
  project          = var.project_id
  database_version = "POSTGRES_13"

  lifecycle {
    prevent_destroy = true
  }

  settings {
    # convert gb to mb in memory
    tier            = "db-custom-${var.sql_instance_cpu}-${var.sql_instance_memory_gb * 1024}"
    disk_autoresize = false
    
    database_flags {
      name  = "maintenance_work_mem"
      value = "${var.sql_maintenance_work_mem_gb * 1024 * 1024}" # Convert GB to KB
    }
    database_flags {
      name  = "temp_file_limit"
      value = "${var.sql_temp_file_limit_gb * 1024 * 1024}"  # Convert GB to KB
    }
    database_flags {
      name  = "work_mem"
      value = "${var.sql_work_mem_mb * 1024}"  # Convert MB to KB
    }
  }
}

resource "google_sql_database" "annotation" {
  name     = "annotation"
  project = var.project_id
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_database" "materialization" {
  name     = "materialization"
  project = var.project_id
  instance = google_sql_database_instance.postgres.name
}

locals {
  db_credentials = jsondecode(data.google_secret_manager_secret_version.postgres_credentials.secret_data)
}

resource "google_sql_user" "writer" {
  name     = local.db_credentials.username
  instance = google_sql_database_instance.postgres.name
  password = local.db_credentials.password
}

data "google_secret_manager_secret_version" "postgres_credentials" {
  project = data.google_project.project.number
  secret = "${var.environment}-postgres-credentials" 
  version = 1
}


