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

  # The controller holds the clients' TCP connections, so it is the sender whose congestion
  # window matters. Linux's default (tcp_slow_start_after_idle=1) drops that window back to
  # ~14 KB whenever a keep-alive connection idles past its retransmission timeout (~0.3 s at
  # a 90 ms round trip), so every API response restarted slow start: a 75-110 KB query
  # response took ~3 extra round trips. Measured on ltv7 (2026-11-10, laptop -> us-east1,
  # zstd Arrow responses): 24 KB 0.21-0.30 s -> 0.13-0.15 s, 383 KB 0.45-0.52 s -> 0.24-0.26
  # s, 1.6 MB 0.89-1.24 s -> 0.60-0.69 s. Linux paces TCP sends, so a full window after idle
  # is not sent as one burst.
  #
  # The sysctl is per network namespace (node-level sysctls don't reach the pod) and
  # Kubernetes counts it unsafe, so pod securityContext.sysctls would need the kubelet's
  # allowed_unsafe_sysctls on the node pool; a privileged init container sets it instead,
  # the way the charts' sysctl-buddy sets net.core.somaxconn.
  values = [yamlencode({
    controller = {
      extraInitContainers = [{
        name            = "sysctl-buddy"
        image           = "alpine:3.4"
        command         = ["sysctl", "-w", "net.ipv4.tcp_slow_start_after_idle=0"]
        securityContext = { privileged = true }
        resources = {
          requests = { cpu = "5m", memory = "10Mi" }
        }
      }]
    }
  })]

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
    # What this module has provisioned for Ray workloads beyond the platform, for
    # the materializationengine chart's preflight to check (it cannot see IAM): with
    # ray.upload on, the chart refuses to install unless the upload grants are at
    # least the version it needs. Bump RAY_UPLOAD_GRANTS_VERSION when they change.
    annotations = local.ray_upload ? {
      "caveconnectome.org/ray-upload-grants" = local.ray_upload_grants_version
    } : {}
  }

  depends_on = [data.google_container_cluster.cluster]
}
