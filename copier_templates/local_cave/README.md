# Terragrunt Env Cookiecutter

Use this template to scaffold a new Terragrunt environment repo.

Quickstart:
- pipx install cookiecutter
- cookiecutter terraform-google-cave/cookiecutter_templates/local_cave

This creates {{ repo_name }}/ with:
- environments/<local_environment_name>/root.hcl (remote state + shared inputs)
- environments/<local_environment_name>/static/terragrunt.hcl (infra)
- environments/<local_environment_name>/<environment>/terragrunt.hcl (cluster)
- environments/<local_environment_name>/scripts/ (import helpers)

After generation:
- Edit root.hcl to set your variables
- Follow QUICKSTART.md in repo root

How it all fits:
- Terragrunt drives Terraform to provision infrastructure outside Kubernetes (SQL, Redis, VPC, DNS, Pub/Sub, buckets, service accounts, IAM).
- The Terraform modules render Helm values files with those outputs so apps can connect to the infrastructure.
- Helmfile then deploys Kubernetes apps from the cave-helm-charts repo using the generated values.

Charts repo: https://github.com/CAVEconnectome/cave-helm-charts (targeted to GKE/Google Cloud; other platforms may need adjustments like non-GCP scalers, IAM, or ingress classes.)

