# CAVE on GCP – Quickstart

This guide boots a CAVE environment using Terragrunt and Helmfile.

## Prerequisites
- macOS with Homebrew
- Install tools:
  - `brew install --cask google-cloud-sdk`
  - `brew install terraform terragrunt kubectl helm helmfile jq direnv sops gitleaks`
- Authenticate:
  - `gcloud auth login`
  - `gcloud auth application-default login`
  - `gcloud config set project <PROJECT_ID>`

## Enable APIs
```
gcloud services enable \
  compute.googleapis.com container.googleapis.com dns.googleapis.com \
  redis.googleapis.com sqladmin.googleapis.com secretmanager.googleapis.com \
  iam.googleapis.com cloudresourcemanager.googleapis.com
```

## Create Terraform state bucket
```
gsutil mb -l us gs://<STATE_BUCKET>
```

## Create DB credentials secret
```
printf '%s' '{"username":"postgres","password":"<strong-secret>"}' \
 | gcloud secrets create <ENV>-postgres-credentials --data-file=-
```

## Generate a starter env with Cookiecutter
```
pipx install cookiecutter  # or pip install --user cookiecutter
cookiecutter terraform-google-cave/cookiecutter_templates/terragrunt-env
```
Answer prompts: repo_name, org, environment, project_id, region, zone, etc.

## Provision
```
cd <repo_name>/environments/<org>/static
terragrunt init && terragrunt apply

cd ../v5
terragrunt init && terragrunt apply
```

## Configure kubectl
```
gcloud container clusters get-credentials <cluster-name> --region <region> --project <PROJECT_ID>
```

## Deploy apps with Helmfile
```
cd <repo_name>/environments/<org>/v5/helmfile
cp helmfile.yaml.example helmfile.yaml
# Edit helmfile.yaml and create overrides (e.g., materialize.yaml) as needed
helmfile apply
```

## Import existing resources (optional)
```
./environments/scripts/terragrunt_import_sql.sh environments/<org>/static
terragrunt --working-dir environments/<org>/static plan -refresh-only
```

## Security checklist for making repos public
- Scan for secrets: `gitleaks detect -v`
- Ensure no tfstate files are committed
- Use Secret Manager or SOPS for any app secrets
- Consider exposing project IDs acceptable

## Troubleshooting
- Clear caches if provider/schema errors:
  - `rm -rf .terragrunt-cache` and re-run `terragrunt init -upgrade`
- Verify kube credentials: `kubectl get ns`
- Check Helm repos: `helm repo add jetstack https://charts.jetstack.io && helm repo update`
