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

## Import existing resources (optional)
You will want to do this if you are migrating from existing infrastructure that has data you don't want to lose.  Make sure the names of everything are aligned with what actually exists, which might requires careful editing of the root.hcl and terragrunt.hcl contained variables. 
```
cd <repo_name>/environments/<org>/static
../scripts/terragrunt_import_sql.sh
terragrunt plan -refresh-only
```

## Provision
```
cd <repo_name>/environments/<org>/static
terragrunt init && terragrunt apply

cd ../<cluster_prefix>
terragrunt init && terragrunt apply
```

## Deploy apps with Helmfile
- Install the Helm Diff plugin (Helmfile uses `helm diff` for planning):
  - `/opt/homebrew/bin/helm plugin install https://github.com/databus23/helm-diff`
  - Verify: `/opt/homebrew/bin/helm plugin list` (should list `diff`)
  - If already installed: `/opt/homebrew/bin/helm plugin update diff`

```
cd <repo_name>/environments/<org>/v5/helmfile
cp helmfile.yaml.example helmfile.yaml
./configure.sh
# Edit helmfile.yaml and create overrides (e.g., materialize.yaml) as needed
helmfile apply
# Tip: If you cannot install the plugin, use --skip-diff as a temporary workaround
# helmfile apply --skip-diff
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
