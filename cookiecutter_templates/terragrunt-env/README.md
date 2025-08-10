# Terragrunt Env Cookiecutter

Use this template to scaffold a new Terragrunt environment repo.

Quickstart:
- pipx install cookiecutter
- cookiecutter terraform-google-cave/cookiecutter_templates/terragrunt-env

This creates {{ repo_name }}/ with:
- environments/<org>/root.hcl (remote state + shared inputs)
- environments/<org>/static/terragrunt.hcl (infra)
- environments/<org>/<environment>/terragrunt.hcl (cluster)
- environments/<org>/scripts/ (import helpers)

After generation:
- Edit root.hcl to set your GCS bucket a
- Follow QUICKSTART.md in repo root

