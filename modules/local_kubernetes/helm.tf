resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.1.2"
  namespace  = "kube-system"

  set = [
    {
      name  = "controller.service.loadBalancerIP"
      value = var.cluster_ip
    },
    {
      name  = "controller.service.externalTrafficPolicy"
      value = "Local"
    }
  ]

  depends_on = [data.google_container_cluster.cluster]
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.9.1"
  namespace        = "cert-manager"
  create_namespace = true

  set = [
    {
      name  = "installCRDs"
      value = "true"
    },
    {
      name  = "ingressShim.defaultIssuerName"
      value = var.letsencrypt_issuer_name
    },
    {
      name  = "ingressShim.defaultIssuerKind"
      value = "ClusterIssuer"
    }
  ]

  depends_on = [data.google_container_cluster.cluster]
}

# Install KEDA via Helm
resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  namespace        = "keda"
  create_namespace = true
  wait             = false

  depends_on = [data.google_container_cluster.cluster]
}

# Install the KubeRay operator via Helm.
#
# This is the only standing cost of the Ray platform (~50m CPU / 128Mi). Ray
# clusters are created per-job by the application as RayJob CRs and deleted on
# completion, so nothing else runs at rest.
#
# Pinned deliberately: KEDA above is unpinned, but cert-manager and nginx are
# pinned and that is the convention to follow for anything installing CRDs.
resource "helm_release" "kuberay_operator" {
  count            = var.enable_ray ? 1 : 0
  name             = "kuberay-operator"
  repository       = "https://ray-project.github.io/kuberay-helm/"
  chart            = "kuberay-operator"
  version          = var.kuberay_operator_version
  namespace        = "kuberay-system"
  create_namespace = true

  set = [
    # The operator must never land on a preemptible pool -- losing it mid-job
    # leaves orphaned RayClusters holding mesh-pool nodes.
    {
      name  = "nodeSelector.cloud\\.google\\.com/gke-nodepool"
      value = var.core_pool_name
    },
  ]

  depends_on = [data.google_container_cluster.cluster]
}

# Namespace RayJobs live in. Created here rather than by the operator release so
# it exists independently of the operator's lifecycle -- the ME chart's RBAC
# binds into it, and helm uninstalling the operator should not take the
# namespace (and any running job's CRs) with it.
resource "kubernetes_namespace_v1" "ray" {
  count = var.enable_ray ? 1 : 0

  metadata {
    name = var.ray_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      project                        = var.environment
      owner                          = "cave"
    }
  }

  depends_on = [data.google_container_cluster.cluster]
}
