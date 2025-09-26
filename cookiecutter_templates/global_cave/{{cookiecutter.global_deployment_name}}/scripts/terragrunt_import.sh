#!/usr/bin/env bash
# Import existing GLOBAL infra resources (VPC, Subnet, DNS, Redis, Cloud SQL, SQL DBs/users) into Terraform state via Terragrunt
# Usage:
#   ./terragrunt_import_global.sh [TERRAGRUNT_MODULE_DIR]
# If no directory is provided, the current directory is used. The directory
# must contain a terragrunt.hcl that defines the resources being imported.

set -euo pipefail

WORK_DIR="${1:-$(pwd)}"
if [ ! -f "$WORK_DIR/terragrunt.hcl" ]; then
  echo "error: no terragrunt.hcl found in: $WORK_DIR" >&2
  echo "usage: $0 /path/to/module" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required (brew install jq)" >&2
  exit 1
fi
if ! command -v gcloud >/dev/null 2>&1; then
  echo "error: gcloud is required (brew install --cask google-cloud-sdk)" >&2
  exit 1
fi

echo "Using Terragrunt working dir: $WORK_DIR"

# Helper functions
has_state() { terragrunt --working-dir "$WORK_DIR" state show "$1" >/dev/null 2>&1; }
import_try() {
  local addr="$1"; shift
  local id_primary="$1"; shift
  local id_fallback="${1:-}"; shift || true
  if has_state "$addr"; then
    echo "$addr already managed (skipping import)"; return 0; fi
  [ -z "$id_primary" ] && { echo "Skipping import for $addr (missing import ID)"; return 0; }
  echo "Importing $addr with: $id_primary"
  set +e
  terragrunt --working-dir "$WORK_DIR" import "$addr" "$id_primary"
  local rc=$?
  set -e
  if [ $rc -ne 0 ] && [ -n "$id_fallback" ]; then
    echo "Primary import failed, retrying $addr with fallback: $id_fallback"
    terragrunt --working-dir "$WORK_DIR" import "$addr" "$id_fallback"
  elif [ $rc -ne 0 ]; then
    return $rc
  fi
}

cfg_json=$(terragrunt --working-dir "$WORK_DIR" render --json)

project_id=$(echo "$cfg_json" | jq -r '.inputs.project_id // empty')
owner=$(echo "$cfg_json" | jq -r '.inputs.owner // empty')
environment=$(echo "$cfg_json" | jq -r '.inputs.environment // empty')
region=$(echo "$cfg_json" | jq -r '.inputs.region // empty')
vpc_name_override=$(echo "$cfg_json" | jq -r '.inputs.vpc_name_override // empty')
subnet_name_override=$(echo "$cfg_json" | jq -r '.inputs.subnetwork_name_override // empty')
dns_zone_name_input=$(echo "$cfg_json" | jq -r '.inputs.dns_zone // .inputs.dns_zone_name // empty')
redis_name_input=$(echo "$cfg_json" | jq -r '.inputs.pcg_redis_name_override // .inputs.pcg_redis_name // .inputs.redis_instance_name // empty')
sql_instance_name=$(echo "$cfg_json" | jq -r '.inputs.sql_instance_name // empty')
postgres_write_user=$(echo "$cfg_json" | jq -r '.inputs.postgres_write_user // empty')

# Compute names
if [ -n "${vpc_name_override}" ]; then
  network_name="${vpc_name_override}"
else
  if [ -n "$owner" ] || [ -n "$environment" ]; then
    network_name="${owner}-${environment}-vpc"
  else network_name=""; fi
fi

if [ -z "${postgres_write_user}" ] && [ -n "${project_id}" ] && [ -n "${environment}" ]; then
  secret_name="${environment}-postgres-credentials"
  set +e
  secret_json=$(gcloud secrets versions access 1 --secret="${secret_name}" --project="${project_id}" 2>/dev/null)
  rc=$?
  if [ $rc -ne 0 ] || [ -z "$secret_json" ]; then
    secret_json=$(gcloud secrets versions access latest --secret="${secret_name}" --project="${project_id}" 2>/dev/null)
  fi
  set -e
  if [ -n "$secret_json" ]; then
    sm_username=$(echo "$secret_json" | jq -r '.username // empty')
    if [ -n "$sm_username" ] && [ "$sm_username" != "null" ]; then
      postgres_write_user="$sm_username"; echo "Resolved SQL user from Secret Manager: $postgres_write_user"; fi
  fi
fi

if [ -n "$subnet_name_override" ]; then
  subnetwork_name="$subnet_name_override"
elif [ -n "$network_name" ]; then
  subnetwork_name="${network_name}-sub"
else subnetwork_name=""; fi

if [ -n "$dns_zone_name_input" ]; then
  dns_zone_name="$dns_zone_name_input"
else dns_zone_name="$environment"; fi

if [ -n "$project_id" ] && [ -n "$sql_instance_name" ]; then
  sql_instance_id="projects/${project_id}/instances/${sql_instance_name}"; fi
if [ -n "$project_id" ] && [ -n "$network_name" ]; then
  network_id="projects/${project_id}/global/networks/${network_name}"; fi
if [ -n "$project_id" ] && [ -n "$sql_instance_name" ] && [ -n "$postgres_write_user" ]; then
  sql_user_id="${project_id}/${sql_instance_name}/${postgres_write_user}"; fi
if [ -n "$project_id" ] && [ -n "$region" ] && [ -n "$subnetwork_name" ]; then
  subnetwork_id="projects/${project_id}/regions/${region}/subnetworks/${subnetwork_name}"; fi
if [ -n "$project_id" ] && [ -n "$dns_zone_name" ]; then
  dns_zone_id_primary="projects/${project_id}/managedZones/${dns_zone_name}"; dns_zone_id_fallback="${dns_zone_name}"; fi

cat <<INFO
Importing resources with the following values:
  Project ID:          ${project_id:-<empty>}
  Environment:         ${environment:-<empty>}
  Owner:               ${owner:-<empty>}
  Region:              ${region:-<empty>}
  SQL Instance:        ${sql_instance_name:-<empty>}
  SQL User (writer):   ${postgres_write_user:-<empty>}
  Network (name):      ${network_name:-<empty>}
  Subnetwork (name):   ${subnetwork_name:-<empty>}
  DNS Zone (name):     ${dns_zone_name:-<empty>}
  SQL Instance ID:     ${sql_instance_id:-<none>}
  SQL User ID:         ${sql_user_id:-<none>}
  VPC Network ID:      ${network_id:-<none>}
  Subnetwork ID:       ${subnetwork_id:-<none>}
  DNS Managed Zone ID: ${dns_zone_id_primary:-<none>} (fallback: ${dns_zone_id_fallback:-<none>})
INFO

# Import resources expected in global_infrastructure
[ -n "${network_id:-}" ]       && import_try "google_compute_network.vpc"            "$network_id"
[ -n "${subnetwork_id:-}" ]    && import_try "google_compute_subnetwork.subnet"     "$subnetwork_id"
[ -n "${dns_zone_id_primary:-}" ] && import_try "google_dns_managed_zone.primary"    "$dns_zone_id_primary" "$dns_zone_id_fallback"
[ -n "${sql_instance_id:-}" ]  && import_try "google_sql_database_instance.postgres" "$sql_instance_id"
[ -n "${sql_user_id:-}" ]      && import_try "google_sql_user.writer"                "$sql_user_id"
# Databases under the instance
if [ -n "${project_id}" ] && [ -n "${sql_instance_name}" ]; then
  import_try "google_sql_database.annotation"     "${project_id}/${sql_instance_name}/annotation"     "projects/${project_id}/instances/${sql_instance_name}/databases/annotation"
  import_try "google_sql_database.materialization" "${project_id}/${sql_instance_name}/materialization" "projects/${project_id}/instances/${sql_instance_name}/databases/materialization"
fi

echo "Global import completed."
