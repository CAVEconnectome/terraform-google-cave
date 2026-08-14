# cert-manager Issuer installed via Helm and DNS credentials managed by Terraform

locals {
  cloud_dns_k8s_secret_name = format("clouddns-google-secret-%s-%s", var.cluster_prefix, terraform.workspace)
  google_secret_filename    = "google-secret.json"
}

# Wait for cert-manager controllers to be up before installing the Issuer chart
resource "time_sleep" "wait_for_cert_manager" {
  create_duration = "60s"
  depends_on      = [helm_release.cert_manager]
}

# Install the local certmanager chart that creates the Issuer (namespaced)
resource "helm_release" "cert_issuer" {
  name             = "cert-issuer"
  chart            = "cert-manager-google"
  version          = "0.4.1"
  repository       = "https://caveconnectome.github.io/cave-helm-charts/"
  namespace        = "cert-manager"
  create_namespace = false

  values = [
    yamlencode({
      issuerName                   = var.letsencrypt_issuer_name
      letsEncryptServer            = var.letsencrypt_server
      letsEncryptEmail             = var.letsencrypt_email
      projectName                  = var.project_id
      cloudDnsServiceAccountSecret = local.cloud_dns_k8s_secret_name
      googleSecretFilename         = local.google_secret_filename
      # Dummy value that changes when chart files change to force upgrade
      dns = {
        googleSecret = jsondecode(base64decode(google_service_account_key.clouddns_key.private_key))
      }
    })
  ]

  depends_on = [
    helm_release.cert_manager,
    time_sleep.wait_for_cert_manager
  ]
}
