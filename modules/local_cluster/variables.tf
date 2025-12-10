variable "environment" {
  description = "environment name to identify resources"
}

variable "cluster_prefix" {
  description = "prefix to identify resources associated with this cluster."
}

variable "project_id" {
  description = "google project id"
}

variable "region" {
  description = "region"
}

variable "zone" {
  description = "zone"
}

variable "gcp_user_account" {
  description = "The GCP user account for creating ClusterRoleBinding"
}

variable "letsencrypt_email" {
  description = "email to use for getting certificates"
  type        = string
}

variable "sql_instance_name" {
  description = "Name of the SQL instance"
}

variable "dns_zone" {
  description = "The name of the DNS managed zone"
  type        = string
}

variable "domain_name" {
  description = "The DNS name associated with this managed zone"
  type        = string
}

variable "dns_entries" {
  description = "Map of DNS entries, where each key is a unique identifier, and each value contains zone and domain name details."
  type = map(object({
    zone        = string
    domain_name = string
  }))
}

variable "pcg_bucket_name" {
  description = "name of bucket where bigtable needs to read and write data"
  type        = string
}

variable "owner" {
  type        = string
  description = "added as label to resources, convenient to filter costs based on labels"
  default     = "na"
}

# define the machine types
variable "standard_machine_type" {
  type        = string
  default     = "t2d-standard-4"
  description = "VM instance type for standard pool"
}
variable "lightweight_machine_type" {
  type        = string
  default     = "e2-small"
  description = "VM instance type for lightweight pool"
}
variable "mesh_machine_type" {
  type        = string
  default     = "t2d-standard-4"
  description = "VM instance type for mesh pool"
}
variable "core_machine_type" {
  type        = string
  default     = "e2-standard-2"
  description = "VM instance type for mesh pool"
}

# define autoscaling parameters
variable "max_nodes_standard_pool" {
  type        = number
  default     = 10
  description = "Maximum size of standard pool"
}
variable "max_nodes_lightweight_pool" {
  type        = number
  default     = 10
  description = "Maximum size of lightweight pool"
}
variable "max_nodes_mesh_pool" {
  type        = number
  default     = 50
  description = "Maximum size of mesh pool"
}
variable "max_nodes_core_pool" {
  type        = number
  default     = 4
  description = "Maximum size of lightweight pool"
}

variable "postgres_write_user" {
  description = "Username for the database writer"
  default     = "postgres"
}

variable "bigtable_instance_name" {
  description = "Name of the bigtable instance to be used by pychunkedgraph and l2cache"
  type        = string
  default     = "pychunkedgraph"
}

variable "bigtable_google_project" {
  description = <<EOF
        "name of the google project your bigtable sits in.
        Use only if it sits in a different project. Note: you will need to create
        a service account with the proper permissions"
    EOF
  type        = string
  default     = ""
}

variable "letsencrypt_issuer_name" {
  type        = string
  default     = "letsencrypt-staging"
  description = "which certificate issuer to configure cert-manager with"
}

variable "letsencrypt_server" {
  description = "ACME server URL"
  type        = string
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "helm_config_dir" {
  type        = string
  description = "folder where to output helmfile config files"
}

variable "helm_terraform_state_url" {
  type        = string
  description = "url where to find tfstate state, using helmfile syntax, assuming ref+tfstateURL so for example i.e. ://PATH_TO_STATE, or gs://BUCKET/PATH_TO_STATE"
}

variable "deletion_protection" {
  type        = bool
  description = "enable deletion protection for the cluster"
  default     = false
}

variable "redis_version" {
  type        = string
  default     = "7_2"
  description = "redis version"
}

variable "network" {
  type        = string
  description = "the self_link of the vpc network to put the cluster on "
}

variable "subnetwork" {
  type        = string
  description = "the self_link of the vpc subnetwork to put the cluster on"
}

variable "mat_redis_host" {
  description = "Hostname or IP for the Materialization/Annotation Redis (used by limiter/materialize)"
  type        = string
  default     = ""
}

variable "pcg_redis_host" {
  description = "Hostname or IP for the PyChunkedGraph Redis"
  type        = string
  default     = ""
}

variable "docker_registry" {
  description = "Container registry to use in Helm values"
  type        = string
  default     = "docker.io/caveconnectome"
}

variable "global_server" {
  description = "Fully qualified global server hostname (where auth and info service reside) (e.g., global.daf-apis.com)"
  type        = string
}

variable "materialization_dump_bucket_path" {
  description = "Optional GCS bucket path for materialization dumps (e.g., 'bucket-name' or 'bucket-name/path'); grants PyCG SA access if set"
  type        = string
  default     = ""
}

variable "materialization_upload_bucket_path" {
  description = "Optional GCS bucket path for materialization uploads (e.g., 'bucket-name' or 'bucket-name/path'); grants PyCG SA access if set"
  type        = string
  default     = ""
}

variable "skeleton_cache_cloudpath" {
  description = "Full gs:// cloud path for SkeletonService cache (e.g., gs://bucket/path). The bucket will be used for IAM; full path is passed to Helm."
  type        = string
}

variable "cave_secret_name" {
  description = "Name of the Google Secret Manager secret containing the CAVE token"
  type        = string
}