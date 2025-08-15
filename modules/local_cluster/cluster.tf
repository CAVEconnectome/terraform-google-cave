resource "google_service_account" "workload_identity" {
  project = var.project_id

  account_id   = "svc-workident-${var.cluster_prefix}"
  display_name = "svc-workident-${var.cluster_prefix}"
}

resource "google_project_iam_member" "workload_identity_default_node_sa_role" {
  project = var.project_id
  role    = "roles/container.defaultNodeServiceAccount"
  member  = "serviceAccount:${google_service_account.workload_identity.email}"
}

resource "kubernetes_service_account" "ksa" {
  metadata {
    name      = "my-service-account"
    namespace = "default"
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.workload_identity.email
    }
  }

  automount_service_account_token = true
}

resource "google_service_account_iam_binding" "ksa_gsa_binding" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${google_service_account.workload_identity.email}"
  role               = "roles/iam.workloadIdentityUser"
  members            = ["serviceAccount:${var.project_id}.svc.id.goog[k8s-namespace/ksa-name]"]
}

resource "google_container_cluster" "cluster" {
  name                     = "${var.cluster_prefix}-cave"
  location                 = var.zone
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = var.deletion_protection

  network         = var.network
  subnetwork      = var.subnetwork
  networking_mode = "VPC_NATIVE"
  lifecycle {
    ignore_changes = [node_config[0].preemptible,node_config[0].resource_labels ]
     # Ignore API-managed resource labels added by GKE on the VM instances
  }
  resource_labels = {
    project = var.environment
    owner   = var.owner
  }

  release_channel {
    channel = "STABLE"
  }

  ip_allocation_policy {}

  addons_config {
    http_load_balancing { disabled = true }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  monitoring_config {
    managed_prometheus { enabled = true }
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  node_config {
    service_account = google_service_account.workload_identity.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}


resource "kubernetes_cluster_role_binding" "cluster_admin_binding" {
  metadata { name = "cluster-admin-binding" }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "cluster-admin"
  }
  subject {
    kind = "User"
    name = var.gcp_user_account
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "google_compute_address" "cluster_ip" {
  name   = "${var.cluster_prefix}-cave"
  region = var.region
}

