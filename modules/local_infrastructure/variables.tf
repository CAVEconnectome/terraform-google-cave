variable "environment" {
  description = "environment name to identify resources"
}

variable "region" {
  description = "region"
}


variable "helm_config_dir" {
  type = string
  description = "folder where to output helmfile config files"
}

variable "helm_terraform_state_url" {
  type = string
  description = "url where to find tfstate state, using helmfile syntax, assuming ref+tfstateURL so for example i.e. ://PATH_TO_STATE, or gs://BUCKET/PATH_TO_STATE"
}


variable "project_id" {
  description = "google project id"
}

variable "owner" {
  type = string
  description = "added as label to resources, convenient to filter costs based on labels"
  default = "na"
}

variable "sql_instance_name" {
  description = "Name of the SQL instance"
  type = string
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
  pcg_redis_name = var.pcg_redis_name_override != "" ? var.pcg_redis_name_override : "${var.owner}-${var.environment}-pcg-redis"
  vpc_name = var.vpc_name_override != "" ? var.vpc_name_override : "${var.owner}-${var.environment}-vpc"
}

variable "sql_instance_cpu" {
  description = "Number of CPUs for the SQL instance"
  default = 4
}

variable "sql_instance_memory_gb" {
  description = "Amount of memory for the SQL instance in gb"
  default = 16 # 10240 Mb in GB
}

variable "sql_temp_file_limit_gb" {
  description = "Temporary file size limit in gigabytes"
  type        = number
  default     = 100  # 104857600 Kb in GB
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
  default     = 104857600  # 100 GB in KB
}

variable "work_mem" {
  description = "Amount of memory to be used by internal sort operations and hash tables in kilobytes"
  type        = number
  default     = 64000  # 64 MB in KB
}

variable "sql_work_mem_mb" {
  description = "Amount of memory to be used by internal sort operations and hash tables in megabytes"
  type        = number
  default     = 64  # 64000 Kb in MB
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