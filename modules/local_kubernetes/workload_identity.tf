# Configure a default Kubernetes service account bound to the GSA backing the cluster's workload identity.
locals {
  workload_identity_k8s_member = var.workload_identity_gsa_email != "" ? format("serviceAccount:%s.svc.id.goog[%s/%s]", var.project_id, var.workload_identity_kubernetes_namespace, var.workload_identity_kubernetes_sa_name) : null
}

# Create the Kubernetes service account that uses Workload Identity.
resource "kubernetes_service_account" "workload_identity" {
  count = var.workload_identity_gsa_email != "" ? 1 : 0

  metadata {
    name      = var.workload_identity_kubernetes_sa_name
    namespace = var.workload_identity_kubernetes_namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = var.workload_identity_gsa_email
    }
  }

  automount_service_account_token = true

  depends_on = [data.google_container_cluster.cluster]
}

# Permit the Kubernetes service account to impersonate the backing Google service account.
resource "google_service_account_iam_binding" "workload_identity" {
  count = local.workload_identity_k8s_member != null ? 1 : 0

  service_account_id = format("projects/%s/serviceAccounts/%s", var.project_id, var.workload_identity_gsa_email)
  role               = "roles/iam.workloadIdentityUser"
  members            = [local.workload_identity_k8s_member]

  depends_on = [kubernetes_service_account.workload_identity]
}

# Optionally grant cluster-admin to the operator's GCP user account for bootstrap access.
resource "kubernetes_cluster_role_binding" "cluster_admin_binding" {
  count = var.gcp_user_account != "" ? 1 : 0

  metadata {
    name = "${var.cluster_prefix}-cluster-admin-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "User"
    name      = var.gcp_user_account
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [data.google_container_cluster.cluster]
}
