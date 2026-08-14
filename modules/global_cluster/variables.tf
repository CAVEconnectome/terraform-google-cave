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
  default     = "cave"
}

variable "machine_type" {
  type        = string
  default     = "e2-medium"
  description = "VM instance type for standard pool"
}

variable "max_nodes" {
  type        = number
  default     = 5
  description = "Maximum size of standard pool"
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

variable "monitoring_enable_components" {
  type = list(string)
  description = <<-EOT
    GKE monitoring components to enable. POD/DEPLOYMENT/STATEFULSET/DAEMONSET/HPA
    are kube-state metrics (replica counts, phases, restarts). CADVISOR and KUBELET
    are what produce the per-container/per-pod CPU and memory series that the GKE
    console's workload observability views read -- without them those views render
    but stay empty.

    All components except SYSTEM_COMPONENTS require managed_prometheus, which this
    module enables unconditionally.

    Cost note: CADVISOR and KUBELET are the highest-cardinality components GKE
    offers (per-container, per-pod, per-volume series billed as GMP samples). On
    clusters with large, short-lived worker fleets they materially increase
    ingestion volume. Override this variable to trim the list per environment.

    Valid values: SYSTEM_COMPONENTS, APISERVER, SCHEDULER, CONTROLLER_MANAGER,
    STORAGE, HPA, POD, DAEMONSET, DEPLOYMENT, STATEFULSET, CADVISOR, KUBELET,
    DCGM, JOBSET. (WORKLOADS is accepted by the API but is a deprecated no-op for
    monitoring -- it is only meaningful in logging_config.)
  EOT
  default = [
    "SYSTEM_COMPONENTS",
    "POD",
    "DEPLOYMENT",
    "STATEFULSET",
    "DAEMONSET",
    "HPA",
    "STORAGE",
    "CADVISOR",
    "KUBELET",
  ]

  validation {
    condition     = contains(var.monitoring_enable_components, "SYSTEM_COMPONENTS")
    error_message = "SYSTEM_COMPONENTS must be included; GKE rejects a monitoring config that enables other components without it."
  }

  validation {
    condition = length(setsubtract(var.monitoring_enable_components, [
      "SYSTEM_COMPONENTS", "APISERVER", "SCHEDULER", "CONTROLLER_MANAGER",
      "STORAGE", "HPA", "POD", "DAEMONSET", "DEPLOYMENT", "STATEFULSET",
      "CADVISOR", "KUBELET", "DCGM", "JOBSET",
    ])) == 0
    error_message = "Unsupported monitoring component. See the variable description for the valid list."
  }
}
