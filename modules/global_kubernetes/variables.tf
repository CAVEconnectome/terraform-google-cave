variable "environment" {
  description = "environment name to identify resources"
}

variable "cluster_name" {
  description = "Name of the target GKE cluster"
  type        = string
}

variable "cluster_prefix" {
  description = "Prefix identifying resources associated with this cluster"
  type        = string
}

variable "cluster_location" {
  description = "Location (zone or region) where the GKE cluster resides"
  type        = string
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

variable "owner" {
  type        = string
  description = "added as label to resources, convenient to filter costs based on labels"
  default     = "na"
}

variable "standard_machine_type" {
  type        = string
  default     = "e2-standard-2"
  description = "VM instance type for standard pool"
}

variable "max_nodes_standard_pool" {
  type        = number
  default     = 4
  description = "Maximum size of standard pool"
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
  default     = true
}

variable "network" {
  type        = string
  description = "the self_link of the vpc network to put the cluster on "
}

variable "subnetwork"{
  type        = string
  description ="the self_link of the vpc subnetwork to put the cluster on"
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

variable "cave_secret_name" {
  description = "Secret Manager secret containing the CAVE token"
  type        = string
}

variable "auth_redis_host" {
  description = "Hostname or IP for the Authorization Redis instance"
  type        = string
  default     = ""
}

variable "cluster_ip" {
  description = "Static IP address for the cluster ingress controller (output of the global_cluster module)"
  type        = string
}

variable "standard_pool_name" {
  description = "Name of the standard node pool (output of the global_cluster module)"
  type        = string
}

variable "auth_oauth_secret_name" {
  description = <<-EOT
    Name of the Secret Manager secret holding the Google OAuth 2.0 "Web
    application" client JSON used by middle_auth for sign-in. The client must be
    created by hand in the Cloud console and the JSON stored with
    `gcloud secrets create/versions add` — Terraform reads it but never writes
    it, so no credential lives in the configuration repository. Run
    `terragrunt output oauth_setup_instructions` on the cluster stage for the
    console URL and the exact list of URIs to register. See GLOBAL_OAUTH_SETUP.md.
  EOT
  type        = string
}

variable "auth_url_prefix" {
  description = "URL prefix serving the regular auth deployment; must match the auth chart's regular.urlPrefix"
  type        = string
  default     = "auth"
}

variable "sticky_auth_url_prefix" {
  description = "URL prefix serving the sticky auth deployment; must match the auth chart's sticky.urlPrefix"
  type        = string
  default     = "sticky_auth"
}