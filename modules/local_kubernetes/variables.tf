variable "project_id" {
  description = "Google project ID hosting the GKE cluster and workloads"
  type        = string
}

variable "region" {
  description = "Region used for regional resources"
  type        = string
}

variable "zone" {
  description = "Primary zone of the deployment"
  type        = string
}

variable "cluster_location" {
  description = "Location (zone or region) where the GKE cluster resides"
  type        = string
}

variable "cluster_name" {
  description = "Name of the target GKE cluster"
  type        = string
}

variable "cluster_prefix" {
  description = "Prefix identifying resources associated with this cluster"
  type        = string
}

variable "gcp_user_account" {
  description = "Email for the GCP user to grant cluster-admin via ClusterRoleBinding"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name used for labeling and templating"
  type        = string
}

variable "domain_name" {
  description = "Primary DNS domain for the deployment"
  type        = string
}

variable "global_server" {
  description = "Fully qualified hostname of the global API server"
  type        = string
}

variable "docker_registry" {
  description = "Container registry used by Helm chart values"
  type        = string
  default     = "docker.io/caveconnectome"
}

variable "dns_entries" {
  description = "Map of DNS entries keyed by identifier with zone and domain name"
  type = map(object({
    zone        = string
    domain_name = string
  }))
}

variable "cluster_ip" {
  description = "Static IP address reserved for the ingress load balancer"
  type        = string
}

variable "standard_pool_name" {
  description = "Name of the standard node pool in the cluster"
  type        = string
}

variable "lightweight_pool_name" {
  description = "Name of the lightweight node pool in the cluster"
  type        = string
}

variable "mesh_pool_name" {
  description = "Name of the mesh node pool in the cluster"
  type        = string
}

variable "core_pool_name" {
  description = "Name of the core node pool in the cluster"
  type        = string
}

variable "letsencrypt_email" {
  description = "Contact email used with Let's Encrypt"
  type        = string
}

variable "letsencrypt_server" {
  description = "ACME server URL used by cert-manager"
  type        = string
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "letsencrypt_issuer_name" {
  description = "Name of the cert-manager issuer to configure"
  type        = string
  default     = "letsencrypt-staging"
}

variable "helm_config_dir" {
  description = "Directory where Helm configuration files will be rendered"
  type        = string
}

variable "workload_identity_gsa_email" {
  description = "Email of the Google service account used for workload identity binding"
  type        = string
  default     = ""
}

variable "workload_identity_kubernetes_sa_name" {
  description = "Name of the Kubernetes service account to bind to the workload identity GSA"
  type        = string
  default     = "workload-identity"
}

variable "workload_identity_kubernetes_namespace" {
  description = "Namespace where the workload identity Kubernetes service account resides"
  type        = string
  default     = "default"
}

variable "helm_terraform_state_url" {
  description = "URL to the Terraform state used by Helmfile references"
  type        = string
}

variable "sql_instance_name" {
  description = "Cloud SQL instance name referenced by Helm values"
  type        = string
}

variable "pcg_bucket_name" {
  description = "Primary GCS bucket backing PyChunkedGraph"
  type        = string
}

variable "pcg_redis_host" {
  description = "Hostname or IP for the PyChunkedGraph Redis instance"
  type        = string
  default     = ""
}

variable "mat_redis_host" {
  description = "Hostname or IP for the Materialization/Annotation Redis instance"
  type        = string
  default     = ""
}

variable "bigtable_google_project" {
  description = "Optional Google project hosting the Bigtable instance"
  type        = string
  default     = ""
}

variable "bigtable_instance_name" {
  description = "Bigtable instance name used by PyChunkedGraph and related charts"
  type        = string
  default     = "pychunkedgraph"
}

variable "skeleton_cache_cloudpath" {
  description = "Full gs:// path used for the SkeletonService cache"
  type        = string
}

variable "materialization_dump_bucket_path" {
  description = "GCS bucket path for materialization dumps (e.g., 'bucket-name' or 'bucket-name/path'). Extracted bucket name is used for IAM permissions."
  type        = string
  default     = ""
}

variable "materialization_upload_bucket_path" {
  description = "GCS bucket path for materialization uploads (e.g., 'bucket-name' or 'bucket-name/path'). Extracted bucket name is used for IAM permissions."
  type        = string
  default     = ""
}

# Deprecated: kept for backward compatibility, use bucket_path instead
variable "materialization_dump_bucket_name" {
  description = "Deprecated: Use materialization_dump_bucket_path instead. Kept for backward compatibility."
  type        = string
  default     = ""
}

# Deprecated: kept for backward compatibility, use bucket_path instead
variable "materialization_upload_bucket_name" {
  description = "Deprecated: Use materialization_upload_bucket_path instead. Kept for backward compatibility."
  type        = string
  default     = ""
}

variable "cave_secret_name" {
  description = "Secret Manager secret containing the CAVE token"
  type        = string
}
