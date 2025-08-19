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
  network            = dependency.static.outputs.network_self_link
  subnetwork         = dependency.static.outputs.subnetwork_self_link
  cluster_prefix     = "{{ cookiecutter.cluster_name }}"
  zone               = "{{ cookiecutter.zone }}"
  letsencrypt_email  = "{{ cookiecutter.letsencrypt_email }}"
  pcg_redis_host     = dependency.static.outputs.pcg_redis_host
  # mat_redis_host   = ""
}
