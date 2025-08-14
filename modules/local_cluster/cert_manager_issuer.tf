# cert-manager Issuer installed via Helm and DNS credentials managed by Terraform

locals {
  cloud_dns_k8s_secret_name   = format("clouddns-google-secret-%s-%s", var.cluster_prefix, terraform.workspace)
  google_secret_filename      = "google-secret.json"
  certmanager_chart_path      = "/Users/forrestc/ConnectomeStack/cave-helm-charts/charts/certmanager"
  certmanager_chart_files     = fileset(local.certmanager_chart_path, "**/*")
  certmanager_chart_checksum  = sha1(join("", [for f in local.certmanager_chart_files : filesha1("${local.certmanager_chart_path}/${f}")]))
}


# Wait for cert-manager controllers to be up before installing the Issuer chart
resource "time_sleep" "wait_for_cert_manager" {
  create_duration = "60s"
  depends_on      = [helm_release.cert_manager]
}

# Install the local certmanager chart that creates the Issuer (namespaced)
resource "helm_release" "cert_issuer" {
  name             = "cert-issuer"
  chart            = local.certmanager_chart_path
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
      _chartChecksum               = local.certmanager_chart_checksum
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
