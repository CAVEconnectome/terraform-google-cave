variable "environment" {
  description = "environment name to identify resources"
}

variable "region" {
  description = "region"
}


variable "helm_config_dir" {
  type        = string
  description = "folder where to output helmfile config files"
}

variable "helm_terraform_state_url" {
  type        = string
  description = "url where to find tfstate state, using helmfile syntax, assuming ref+tfstateURL so for example i.e. ://PATH_TO_STATE, or gs://BUCKET/PATH_TO_STATE"
}


variable "project_id" {
  description = "google project id"
}

variable "owner" {
  type        = string
  description = "added as label to resources, convenient to filter costs based on labels"
  default     = "na"
}

variable "sql_instance_name" {
  description = "Name of the SQL instance"
  type        = string
}

variable "postgres_version" {
  description = "PostgreSQL version for the SQL instance (e.g., POSTGRES_13, POSTGRES_14)"
  type        = string
  default     = "POSTGRES_18"
}

variable "sql_edition" {
  description = <<EOF
        "Cloud SQL edition: ENTERPRISE or ENTERPRISE_PLUS.
        Must stay ENTERPRISE while tier is a db-custom-* machine type; ENTERPRISE_PLUS
        only accepts predefined db-perf-optimized-N-* tiers. Left unset, the API
        defaults POSTGRES_16+ instances to ENTERPRISE_PLUS, which then rejects the tier."
    EOF
  type        = string
  default     = "ENTERPRISE"
}

variable "dns_zone" {
  description = "The name of the DNS managed zone"
  type        = string
}

variable "domain_name" {
  description = "The DNS name associated with this managed zone"
  type        = string
}

variable "pcg_redis_name_override" {
  description = "Override for the PCG Redis name"
  type        = string
  default     = ""
}

variable "vpc_name_override" {
  description = "Override for the VPC name"
  type        = string
  default     = ""
}

locals {
  pcg_redis_name     = var.pcg_redis_name_override != "" ? var.pcg_redis_name_override : "${var.owner}-${var.environment}-pcg-redis"
  vpc_name           = var.vpc_name_override != "" ? var.vpc_name_override : "${var.owner}-${var.environment}-vpc"
  sql_google_project = var.sql_google_project != "" ? var.sql_google_project : var.project_id
  # Materialization dumps are written by the Cloud SQL export job, so they default to
  # following the database rather than the cluster.
  materialization_bucket_google_project = var.materialization_bucket_google_project != "" ? var.materialization_bucket_google_project : local.sql_google_project
}

variable "sql_google_project" {
  description = <<EOF
        "name of the google project your Cloud SQL instance sits in.
        Use only if it should sit in a different project than project_id.
        Set at creation time only: changing it on an existing instance forces
        replacement, which prevent_destroy will block."
    EOF
  type        = string
  default     = ""
}

variable "materialization_bucket_google_project" {
  description = <<EOF
        "name of the google project the materialization dump and upload buckets sit in.
        Defaults to sql_google_project, which itself defaults to project_id, so the
        buckets follow the Cloud SQL instance unless overridden.
        A bucket's project is immutable: changing this on an existing deployment
        forces the buckets to be destroyed and recreated."
    EOF
  type        = string
  default     = ""
}

variable "sql_instance_cpu" {
  description = "Number of CPUs for the SQL instance"
  default     = 4
}

variable "sql_instance_memory_gb" {
  description = "Amount of memory for the SQL instance in gb"
  default     = 16 # 10240 Mb in GB
}

variable "sql_temp_file_limit_gb" {
  description = "Temporary file size limit in gigabytes"
  type        = number
  default     = 100 # 104857600 Kb in GB
}

variable "sql_maintenance_work_mem_gb" {
  description = "Maximum amount of memory to be used for maintenance operations in gigabytes"
  type        = number
  default     = 2
}

variable "max_parallel_maintenance_workers" {
  description = "Maximum number of maintenance workers that can be run in parallel"
  type        = number
  default     = 2
}

variable "temp_file_limit" {
  description = "Temporary file size limit in kilobytes"
  type        = number
  default     = 104857600 # 100 GB in KB
}

variable "work_mem" {
  description = "Amount of memory to be used by internal sort operations and hash tables in kilobytes"
  type        = number
  default     = 64000 # 64 MB in KB
}

variable "sql_work_mem_mb" {
  description = "Amount of memory to be used by internal sort operations and hash tables in megabytes"
  type        = number
  default     = 64 # 64000 Kb in MB
}

variable "pcg_redis_memory_size_gb" {
  type        = number
  default     = 1
  description = "redis instance size"
}

variable "redis_version" {
  type        = string
  default     = "7_2"
  description = "redis version"
}

variable "sql_max_connections" {
  description = "Maximum number of Postgres connections (max_connections database flag)"
  type        = number
  default     = 20000
}

# Optional cloud path for SkeletonService cache, e.g., gs://bucket/path/to/save
# If not provided, a default bucket name is generated and the cloudpath defaults to gs://<bucket>
variable "skeleton_cache_cloudpath" {
  description = "Optional gs:// cloud path where skeletons are stored (e.g., gs://bucket/path). If empty, a default bucket is created and used (gs://<bucket>)."
  type        = string
  default     = ""
}

# If true, allow public read access to objects in the Skeleton Cache bucket.
# This grants roles/storage.objectViewer to allUsers and relaxes Public Access Prevention.
variable "skeleton_cache_public_read" {
  description = "Enable public read (allUsers) for the Skeleton Cache bucket."
  type        = bool
  default     = false
}

variable "materialization_dump_bucket_path" {
  description = "Optional GCS bucket path for materialization dumps (e.g., 'bucket-name' or 'bucket-name/path'). If empty, a default bucket is created and used."
  type        = string
  default     = ""
}

variable "materialization_upload_bucket_path" {
  description = "Optional GCS bucket path for materialization uploads (e.g., 'bucket-name' or 'bucket-name/path'). If empty, a default bucket is created and used."
  type        = string
  default     = ""
}

variable "materialization_dump_bucket_uniform_bucket_level_access" {
  description = "Whether to enable uniform bucket-level access for the materialization dump bucket."
  type        = bool
  default     = true
}

variable "materialization_dump_bucket_public_access_prevention" {
  description = "Public Access Prevention setting for the materialization dump bucket. Set to 'enforced' to prevent public access."
  type        = string
  default     = "enforced"
}

variable "skeleton_cache_uniform_bucket_level_access" {
  description = "Whether to enable uniform bucket-level access for the skeleton cache bucket."
  type        = bool
  default     = true
}

variable "sql_backups_enabled" {
  description = "Whether automated backups are enabled on the SQL instance. Turn off only for environments whose data is disposable or reproducible."
  type        = bool
  default     = true
}

variable "sql_point_in_time_recovery_enabled" {
  description = "Whether point-in-time recovery is enabled on the SQL instance. Has no effect when sql_backups_enabled is false, since PITR depends on backups."
  type        = bool
  default     = true
}

variable "sql_backup_start_time" {
  description = "HH:MM (UTC) start of the daily backup window. Leave null to let GCP keep its existing/default window."
  type        = string
  default     = null
}

variable "sql_transaction_log_retention_days" {
  description = "Days of transaction logs to retain for point-in-time recovery. Leave null to keep the GCP default."
  type        = number
  default     = null
}

variable "sql_backup_retained_count" {
  description = "Number of automated backups to retain. Leave null to keep the GCP default."
  type        = number
  default     = null
}