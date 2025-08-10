terraform { 
  source = "git::https://github.com/CAVEconnectome/terraform-google-cave.git//modules/local_infrastructure?ref=main"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  sql_instance_name        = "{{ cookiecutter.sql_instance_name }}"
  dns_zone                 = "{{ cookiecutter.dns_zone }}"
  domain_name              = "{{ cookiecutter.domain_name }}"
  letsencrypt_email        = "{{ cookiecutter.letsencrypt_email }}"
  vpc_name_override        = "{{ cookiecutter.vpc_name_override }}"
  pcg_redis_name_override  = "{{ cookiecutter.pcg_redis_name_override }}"
  deletion_protection      = false
}
