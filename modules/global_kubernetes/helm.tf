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
  # ~14 KB whenever a keep-alive connection idles past its retransmission timeout, so every
  # response after a pause restarts slow start and pays extra round trips. Measured through
  # ltv7's controller (2026-11-10, laptop -> us-east1): 24 KB 0.21-0.30 s -> 0.13-0.15 s,
  # 383 KB 0.45-0.52 s -> 0.24-0.26 s. The sysctl is per network namespace and Kubernetes
  # counts it unsafe, so a privileged init container sets it in the controller's pod, as in
  # local_kubernetes. ingress_disable_tcp_slow_start_after_idle = false leaves the default.
  values = [yamlencode({
    controller = {
      extraInitContainers = var.ingress_disable_tcp_slow_start_after_idle ? [{
        name            = "sysctl-buddy"
        image           = "alpine:3.4"
        command         = ["sysctl", "-w", "net.ipv4.tcp_slow_start_after_idle=0"]
        securityContext = { privileged = true }
        resources = {
          requests = { cpu = "5m", memory = "10Mi" }
        }
      }] : []
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
