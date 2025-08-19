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
  cluster_prefix           = "{{ cookiecutter.cluster_prefix }}"
  zone                     = "{{ cookiecutter.zone }}"
  letsencrypt_email        = "{{ cookiecutter.letsencrypt_email }}"
  pcg_redis_host           = dependency.static.outputs.pcg_redis_host
  skeleton_cache_cloudpath = dependency.static.outputs.skeleton_cache_cloudpath
  dns_entries              = {
      "{{ cookiecutter.cluster_prefix }}" = {
        zone        = "{{ cookiecutter.dns_zone }}"
        domain_name = "{{ cookiecutter.cluster_prefix }}.{{ cookiecutter.domain_name. }}"
      }
    }
  # mat_redis_host   = ""
}

locals {
  prefix = "{{ local_deployment_name }}/${path_relative_to_include()}"
}
