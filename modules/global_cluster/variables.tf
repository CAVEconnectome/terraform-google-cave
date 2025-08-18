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
