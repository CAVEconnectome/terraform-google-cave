resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.1.2"
  namespace  = "kube-system"

  set = [
    {
      name  = "controller.service.loadBalancerIP"
      value = google_compute_address.cluster_ip.address
    },
    {
      name  = "controller.service.externalTrafficPolicy"
      value = "Local"
    }
  ]

  depends_on = [google_compute_address.cluster_ip,
                google_container_cluster.cluster]
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.9.1"
  namespace  = "cert-manager"
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
depends_on = [google_container_cluster.cluster]
}


# Install KEDA via Helm
resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  namespace        = "keda"
  create_namespace = true
  wait             = false

  depends_on = [
    google_container_cluster.cluster
  ]
}