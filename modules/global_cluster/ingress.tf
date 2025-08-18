# ClusterIssuer for Let's Encrypt
resource "kubernetes_manifest" "letsencrypt_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata   = {
      name = var.letsencrypt_issuer_name
    }
    spec = {
      acme = {
        email  = var.letsencrypt_email
        server = var.letsencrypt_server
        privateKeySecretRef = {
          name = "acme-account-private-key"
        }
        solvers = [{
          http01 = {
            ingress = {
              class = "nginx"
            }
          }
        }]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}
