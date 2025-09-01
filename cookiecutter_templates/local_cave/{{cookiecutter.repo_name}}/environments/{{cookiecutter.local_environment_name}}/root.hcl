remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "{{ cookiecutter.state_bucket }}"
    prefix = "{{ cookiecutter.local_environment_name }}/${path_relative_to_include()}"
  }
}

inputs = {
  owner                    = "cave"
  project_id               = "{{ cookiecutter.project_id }}"
  region                   = "{{ cookiecutter.region }}"
  zone                     = "{{ cookiecutter.zone }}"
  environment              = "{{ cookiecutter.local_environment_name }}"
  domain_name              = "{{ cookiecutter.domain_name }}"
  global_server            = "{{ cookiecutter.global_server}}"
  docker_registry          = "{{ cookiecutter.docker_registry }}"
  gcp_user_account         = "{{ cookiecutter.gcp_user_account }}"
  sql_instance_name        = "{{ cookiecutter.local_sql_instance_name }}"
  
  pcg_bucket_name            = "{{ cookiecutter.pcg_bucket_name }}"
  bigtable_google_project  = "{{ cookiecutter.bigtable_google_project }}"
  bigtable_instance_name   = "{{ cookiecutter.bigtable_instance_name }}"
  
  helm_terraform_state_url = "gs://{{ cookiecutter.state_bucket }}/{{ cookiecutter.local_environment_name }}/static/default.tfstate"
  helm_config_dir          = "${get_terragrunt_dir()}/helmfile"
  
  # dns variables
  dns_zone                   = "{{ cookiecutter.dns_zone }}"

  # If migrating from previous setup use these variables 
  # pcg_redis_name_override    = "v1dd-pcg-cache"
  # vpc_name_override          = "daf-api3-network"
  # Leave commented to let Terraform pick a default bucket.
  # skeleton_cache_cloudpath = {{ cookiecutter.skeleton_cache_cloudpath}}
  # will default to private read
  skeleton_cache_public_read = {{ cookiecutter.pcg_skeleton_cache_bucket_public_read }}
  deletion_protection        = false

  sql_instance_memory_gb     = 26
}
