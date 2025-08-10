remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "{{ cookiecutter.state_bucket }}"
    prefix = "{{ cookiecutter.org }}/${path_relative_to_include()}"
  }
}

inputs = {
  owner                    = "{{ cookiecutter.owner }}"
  project_id               = "{{ cookiecutter.project_id }}"
  region                   = "{{ cookiecutter.region }}"
  environment              = "{{ cookiecutter.environment }}"
  helm_terraform_state_url = "gs://{{ cookiecutter.state_bucket }}"
  helm_config_dir          = "${get_terragrunt_dir()}/helmfile"
}
