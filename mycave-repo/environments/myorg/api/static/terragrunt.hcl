terraform { 
  source = "git::https://github.com/CAVEconnectome/terraform-google-cave.git//modules/local_infrastructure?ref=main"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  sql_instance_name        = "sql1"
  dns_zone                 = "cave"
  domain_name              = "cave.example.org"
  letsencrypt_email        = "myemail@myorg.org"
  vpc_name_override        = ""
  pcg_redis_name_override  = ""
  deletion_protection      = false
}
