remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "my-terraform-state-bucket"
    prefix = "myorg/${path_relative_to_include()}"
  }
}

inputs = {
  owner                    = "cave"
  project_id               = "my-gcp-project"
  region                   = "us-west1"
  environment              = "api"
  helm_terraform_state_url = "gs://my-terraform-state-bucket"
  helm_config_dir          = "${get_terragrunt_dir()}/helmfile"
}
