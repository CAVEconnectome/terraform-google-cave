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

# pcgl2cache worker Pub/Sub subscription names, sourced from local_cluster outputs
# so the naming format lives only in the local_cluster pubsub definitions.
variable "l2cache_worker_subscription" {
  description = "Pub/Sub subscription for the pcgl2cache update/missing worker (from local_cluster)"
  type        = string
}

variable "l2cache_high_priority_trigger_subscription" {
  description = "Pub/Sub subscription for the pcgl2cache high-priority worker (from local_cluster)"
  type        = string
}

variable "l2cache_low_priority_trigger_subscription" {
  description = "Pub/Sub subscription for the pcgl2cache low-priority worker (from local_cluster)"
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

variable "sql_google_project" {
  description = "Optional Google project hosting the Cloud SQL instance. Empty means project_id."
  type        = string
  default     = ""
}

locals {
  sql_google_project = var.sql_google_project != "" ? var.sql_google_project : var.project_id
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

# --- Ray / KubeRay ---------------------------------------------------------
# Ephemeral RayJob platform for long-running jobs that Celery-over-Redis struggles
# with. Ray workers run on the existing mesh-pool; there is no dedicated node pool.

variable "enable_ray" {
  description = <<-EOT
    Install the KubeRay operator and create the Ray service account + secret.
    Ray clusters themselves are ephemeral: the application creates a RayJob CR,
    KubeRay stands up a cluster, runs it, and deletes it. Nothing runs at rest
    except the operator pod. On by default: Ray is the preferred way to run bulk
    uploads and Delta Lake exports. materializationengine charts before 5.30
    have no Ray templates and ignore the generated ray values.
  EOT
  type        = bool
  default     = true
}

variable "kuberay_operator_version" {
  description = "Pinned kuberay-operator Helm chart version."
  type        = string
  default     = "1.6.2"
}

variable "ray_version" {
  description = <<-EOT
    Ray version declared on the RayCluster spec. MUST match the ray package
    actually installed in the materializationengine image -- KubeRay uses this
    for health checks and feature gating, and a mismatch fails in confusing ways.
    Keep current; the floor from the 2023 CVEs is 2.8.1.
  EOT
  type        = string
  default     = "2.57.0"
}

variable "ray_namespace" {
  description = <<-EOT
    Namespace RayJobs are created in. Deliberately not "default": Ray's job
    submission API has no authentication (CVE-2023-48022), so RayJobs are kept
    out of the shared namespace to scope RBAC and to leave room for a
    NetworkPolicy if enforcement is ever enabled on the cluster.
  EOT
  type        = string
  default     = "ray-jobs"
}

variable "enable_ray_upload" {
  description = <<-EOT
    Run bulk uploads as RayJobs (the chart's ray.upload, emitted into the generated
    ray values). Grants the Ray service account what the upload driver and its
    workers need, and nothing more: objectAdmin on the upload bucket, a custom
    role with only cloudsql.instances.import/get on the app's Cloud SQL instance,
    and bigtable.reader on the PyChunkedGraph instance (root id lookups).
    Requires enable_ray. On by default; false keeps bulk uploads on Celery.
  EOT
  type        = bool
  default     = true
}

variable "ray_cloudsql_import_role" {
  description = <<-EOT
    Role that lets the Ray service account import CSVs into the app's Cloud SQL
    instance (bound with a condition naming that instance). Empty creates a custom
    role holding only cloudsql.instances.import and .get, which needs
    iam.roles.create on the SQL project; otherwise an existing role, e.g. a custom
    role an admin created, or roles/cloudsql.admin (the only predefined role with
    import).
  EOT
  type        = string
  default     = ""
}

variable "ray_upload_read_buckets" {
  description = <<-EOT
    Further buckets the Ray service account may read (objectViewer) for uploads read
    in place from a cloud location (gs://bucket/... sources outside the upload
    bucket). Public buckets need no grant.
  EOT
  type        = list(string)
  default     = []
}

variable "ray_deltalake_bucket_name" {
  description = <<-EOT
    Bucket the Ray deltalake entrypoint writes to. The Ray service account is
    granted objectAdmin on this bucket ALONE rather than at project level --
    anything that reaches the Ray head gets arbitrary code execution, so the
    mounted credential is scoped as tightly as the workload allows.
    Defaults to the materialization dump bucket when empty.
  EOT
  type        = string
  default     = ""
}
