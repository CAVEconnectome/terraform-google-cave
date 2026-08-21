resource "google_sql_database_instance" "postgres" {
  name             = var.sql_instance_name
  region           = var.region
  project          = local.sql_google_project
  database_version = var.postgres_version

  lifecycle {
    prevent_destroy = true
  }

  settings {
    # convert gb to mb in memory
    tier                        = "db-custom-${var.sql_instance_cpu}-${var.sql_instance_memory_gb * 1024}"
    edition                     = var.sql_edition
    disk_autoresize             = false
    deletion_protection_enabled = true

    database_flags {
      name  = "maintenance_work_mem"
      value = var.sql_maintenance_work_mem_gb * 1024 * 1024 # Convert GB to KB
    }
    database_flags {
      name  = "temp_file_limit"
      value = var.sql_temp_file_limit_gb * 1024 * 1024 # Convert GB to KB
    }
    database_flags {
      name  = "work_mem"
      value = var.sql_work_mem_mb * 1024 # Convert MB to KB
    }
    database_flags {
      name  = "max_connections"
      value = tostring(var.sql_max_connections)
    }

    backup_configuration {
      enabled = var.sql_backups_enabled
      # PITR requires backups, so it can never outlive them being turned off.
      point_in_time_recovery_enabled = var.sql_backups_enabled && var.sql_point_in_time_recovery_enabled
      # These stay null unless explicitly set, so GCP's existing schedule and
      # retention are left as-is rather than churning on every apply.
      start_time                     = var.sql_backup_start_time
      transaction_log_retention_days = var.sql_transaction_log_retention_days

      dynamic "backup_retention_settings" {
        for_each = var.sql_backup_retained_count == null ? [] : [var.sql_backup_retained_count]
        content {
          retained_backups = backup_retention_settings.value
        }
      }
    }
  }
}

resource "google_sql_database" "annotation" {
  name     = "annotation"
  project  = local.sql_google_project
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_database" "materialization" {
  name     = "materialization"
  project  = local.sql_google_project
  instance = google_sql_database_instance.postgres.name
}

locals {
  db_credentials = jsondecode(data.google_secret_manager_secret_version.postgres_credentials.secret_data)
}

resource "google_sql_user" "writer" {
  name     = local.db_credentials.username
  project  = local.sql_google_project
  instance = google_sql_database_instance.postgres.name
  password = local.db_credentials.password
}

# The credentials secret stays in the cluster project even when the instance
# lives elsewhere, so helm's ref+gcpsecrets lookups keep resolving there.
data "google_secret_manager_secret_version" "postgres_credentials" {
  project = data.google_project.project.number
  secret  = "${var.environment}-postgres-credentials"
  version = 1
}


