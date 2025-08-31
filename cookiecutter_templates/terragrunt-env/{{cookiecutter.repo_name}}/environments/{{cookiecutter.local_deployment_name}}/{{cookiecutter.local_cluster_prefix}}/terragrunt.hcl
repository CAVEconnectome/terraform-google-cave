terraform { 
  source = "git::https://github.com/CAVEconnectome/terraform-google-cave.git/modules/local_cluster?ref=main"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "static" {
  config_path = "../static"
}

inputs = {
  network                  = dependency.static.outputs.network_self_link
  subnetwork               = dependency.static.outputs.subnetwork_self_link
  zone                     = "{{ cookiecutter.zone }}"
  cluster_prefix           = "{{ cookiecutter.local_cluster_prefix }}"
  letsencrypt_email        = "{{ cookiecutter.gcp_user_account }}"
  pcg_redis_host           = dependency.static.outputs.pcg_redis_host
  skeleton_cache_cloudpath = dependency.static.outputs.skeleton_cache_cloudpath
  dns_entries              = {
      "{{ cookiecutter.local_cluster_prefix }}" = {
        zone        = "{{ cookiecutter.dns_zone }}"
        domain_name = "{{ cookiecutter.local_cluster_prefix }}.{{ cookiecutter.domain_name. }}"
      },
      "{{ cookiecutter.local_deployment_name}} = {
        zone        = "{{ cookiecutter.dns_zone }}"
        domain_name = "{{ cookiecutter.local_deployment_name }}.{{ cookiecutter.domain_name. }}"
      }
    }
  # mat_redis_host   = ""
}

locals {
  prefix = "{{ local_deployment_name }}/${path_relative_to_include()}"
}
