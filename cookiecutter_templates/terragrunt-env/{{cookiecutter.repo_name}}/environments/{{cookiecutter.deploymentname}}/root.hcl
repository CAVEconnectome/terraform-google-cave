remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "{{ cookiecutter.state_bucket }}"
    prefix = "{{ cookiecutter.deploymentname }}/${path_relative_to_include()}"
  }
}

inputs = {
  owner                    = "{{ cookiecutter.owner }}"
  project_id               = "{{ cookiecutter.project_id }}"
  region                   = "{{ cookiecutter.region }}"
  zone                     = "{{ cookiecutter.zone }}"
  environment              = "{{ cookiecutter.environment }}"
  domain_name              = "{{ cookiecutter.domain_name }}"
  docker_registry          = "{{ cookiecutter.docker_registry }}"
  bigtable_google_project  = "{{ cookiecutter.bigtable_google_project }}"
  bigtable_instance_name   = "{{ cookiecutter.bigtable_instance_name }}"
  helm_terraform_state_url = "gs://{{ cookiecutter.state_bucket }}/{{ cookiecutter.deploymentname }}/static/terraform.tfstate"
  helm_config_dir          = "${get_terragrunt_dir()}/helmfile"
  # Optional: set a cloud path for Skeleton Cache (gs://bucket/prefix).
  # Leave commented to let Terraform pick a default bucket.
  # skeleton_cache_cloudpath = "gs://my-bucket/pcg_skeletons"
}
