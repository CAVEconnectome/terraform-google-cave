#!/usr/bin/env bash
# Import existing Cloud SQL and VPC resources into Terraform state via Terragrunt
# Usage:
#   ./terragrunt_import_sql.sh [TERRAGRUNT_MODULE_DIR]
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
# Added: Ensure gcloud CLI is available for Secret Manager lookups
if ! command -v gcloud >/dev/null 2>&1; then
  echo "error: gcloud is required (brew install --cask google-cloud-sdk)" >&2
  exit 1
fi

echo "Using Terragrunt working dir: $WORK_DIR"

# Helper: return 0 if resource address exists in state, else 1
has_state() {
  local addr="$1"
  set +e
  terragrunt --working-dir "$WORK_DIR" state show "$addr" >/dev/null 2>&1
  local rc=$?
  set -e
  return $rc
}

# Helper: import with optional fallback ID (used when providers accept multiple ID syntaxes)
import_try() {
  local addr="$1"; shift
  local id_primary="$1"; shift
  local id_fallback="${1:-}"; shift || true
  if has_state "$addr"; then
    echo "$addr already managed (skipping import)"
    return 0
  fi
  if [ -z "$id_primary" ]; then
    echo "Skipping import for $addr (missing import ID)"
    return 0
  fi
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

# Read Terragrunt inputs (no state required) and derive names exactly as the module does
# Use modern command: `terragrunt render --json`
cfg_json=$(terragrunt --working-dir "$WORK_DIR" render --json)

project_id=$(echo "$cfg_json" | jq -r '.inputs.project_id // empty')
owner=$(echo "$cfg_json" | jq -r '.inputs.owner // empty')
environment=$(echo "$cfg_json" | jq -r '.inputs.environment // empty')
region=$(echo "$cfg_json" | jq -r '.inputs.region // empty')
vpc_name_override=$(echo "$cfg_json" | jq -r '.inputs.vpc_name_override // empty')
subnet_name_override=$(echo "$cfg_json" | jq -r '.inputs.subnetwork_name_override // empty')
# Prefer dns_zone, fallback to dns_zone_name
dns_zone_name_input=$(echo "$cfg_json" | jq -r '.inputs.dns_zone // .inputs.dns_zone_name // empty')
# Prefer override, then other possible input names
redis_name_input=$(echo "$cfg_json" | jq -r '.inputs.pcg_redis_name_override // .inputs.pcg_redis_name // .inputs.redis_instance_name // empty')
sql_instance_name=$(echo "$cfg_json" | jq -r '.inputs.sql_instance_name // empty')
postgres_write_user=$(echo "$cfg_json" | jq -r '.inputs.postgres_write_user // empty')
materialization_dump_bucket_path=$(echo "$cfg_json" | jq -r '.inputs.materialization_dump_bucket_path // .inputs.materialization_dump_bucket_name // empty')
materialization_upload_bucket_path=$(echo "$cfg_json" | jq -r '.inputs.materialization_upload_bucket_path // .inputs.materialization_upload_bucket_name // empty')
# Extract bucket name from path (remove /path suffix if present) for imports
materialization_dump_bucket_name=$(echo "$materialization_dump_bucket_path" | sed -n -e 's/^\([^/]*\).*$/\1/p')
materialization_upload_bucket_name=$(echo "$materialization_upload_bucket_path" | sed -n -e 's/^\([^/]*\).*$/\1/p')
skeleton_cache_cloudpath=$(echo "$cfg_json" | jq -r '.inputs.skeleton_cache_cloudpath // empty')


if [ -z "$project_id$owner$environment$region$vpc_name_override$sql_instance_name$postgres_write_user" ]; then
  echo "warn: Terragrunt inputs appear empty in $WORK_DIR. Ensure this env defines inputs (or inherits via include) before import." >&2
fi

# Recompute VPC name using the module rule
if [ -n "${vpc_name_override}" ]; then
  network_name="${vpc_name_override}"
else
  # Only compute default if we have owner/environment
  if [ -n "$owner" ] || [ -n "$environment" ]; then
    network_name="${owner}-${environment}-vpc"
  else
    network_name=""
  fi
fi

# New: Resolve SQL writer username from Secret Manager if not provided via inputs
# Matches module data source: secret name "${environment}-postgres-credentials"
if [ -z "${postgres_write_user}" ] && [ -n "${project_id}" ] && [ -n "${environment}" ]; then
  secret_name="${environment}-postgres-credentials"
  # Try version 1 first (module pins version=1), then fallback to latest
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
      postgres_write_user="$sm_username"
      echo "Resolved SQL user from Secret Manager: $postgres_write_user"
    else
      echo "warn: Secret '${secret_name}' did not contain 'username' field" >&2
    fi
  else
    echo "warn: Unable to access Secret Manager secret '${secret_name}' in project '${project_id}'" >&2
  fi
fi

# Derive additional resource names
# Subnetwork: use override or default to "${network_name}-sub"
if [ -n "$subnet_name_override" ]; then
  subnetwork_name="$subnet_name_override"
elif [ -n "$network_name" ]; then
  subnetwork_name="${network_name}-sub"
else
  subnetwork_name=""
fi

# DNS zone: input var or fall back to environment (e.g., "em")
if [ -n "$dns_zone_name_input" ]; then
  dns_zone_name="$dns_zone_name_input"
else
  dns_zone_name="$environment"
fi

# Redis instance name: input var, else discover via authorized network filter
if [ -n "$redis_name_input" ]; then
  redis_name="$redis_name_input"
elif [ -n "$project_id" ] && [ -n "$region" ] && [ -n "$network_name" ]; then
  network_id_discover="projects/${project_id}/global/networks/${network_name}"
  network_url="https://www.googleapis.com/compute/v1/${network_id_discover}"
  set +e
  redis_list=$(gcloud redis instances list --project "$project_id" --regions "$region" --format=json --filter="authorizedNetwork:${network_url}" 2>/dev/null)
  set -e
  if [ -n "$redis_list" ] && [ "$(echo "$redis_list" | jq 'length')" -gt 0 ]; then
    # name may be full resource path; take last path segment
    redis_name=$(echo "$redis_list" | jq -r '.[0].name | (split("/") | last)')
    echo "Discovered Redis instance by VPC: $redis_name"
  else
    redis_name=""
  fi
else
  redis_name=""
fi

# Construct resource IDs (only if values exist)
sql_instance_id=""
network_id=""
sql_user_id=""
subnetwork_id=""
dns_zone_id_primary=""
dns_zone_id_fallback=""
redis_id=""

if [ -n "${project_id}" ] && [ -n "${sql_instance_name}" ]; then
  sql_instance_id="projects/${project_id}/instances/${sql_instance_name}"
fi
if [ -n "${project_id}" ] && [ -n "${network_name}" ]; then
  network_id="projects/${project_id}/global/networks/${network_name}"
fi
# For Postgres users, import ID format is "{project}/{instance}/{name}" (no "projects/.../users") per provider docs
if [ -n "${project_id}" ] && [ -n "${sql_instance_name}" ] && [ -n "${postgres_write_user}" ]; then
  sql_user_id="${project_id}/${sql_instance_name}/${postgres_write_user}"
fi
# Subnetwork (Compute): projects/{project}/regions/{region}/subnetworks/{name}
if [ -n "${project_id}" ] && [ -n "${region}" ] && [ -n "${subnetwork_name}" ]; then
  subnetwork_id="projects/${project_id}/regions/${region}/subnetworks/${subnetwork_name}"
fi
# DNS managed zone: prefer full path; fallback to just zone name
if [ -n "${project_id}" ] && [ -n "${dns_zone_name}" ]; then
  dns_zone_id_primary="projects/${project_id}/managedZones/${dns_zone_name}"
  dns_zone_id_fallback="${dns_zone_name}"
fi
# Memorystore Redis: projects/{project}/locations/{region}/instances/{name}
if [ -n "${project_id}" ] && [ -n "${region}" ] && [ -n "${redis_name}" ]; then
  redis_id="projects/${project_id}/locations/${region}/instances/${redis_name}"
fi

cat <<INFO
Importing resources with the following values:
  Project ID:                ${project_id:-<empty>}
  Environment:               ${environment:-<empty>}
  Owner:                     ${owner:-<empty>}
  Region:                    ${region:-<empty>}
  SQL Instance:              ${sql_instance_name:-<empty>}
  SQL User (writer):         ${postgres_write_user:-<empty>}
  Network (name):            ${network_name:-<empty>}
  Subnetwork (name):         ${subnetwork_name:-<empty>}
  DNS Zone (name):           ${dns_zone_name:-<empty>}
  Redis Instance (name):     ${redis_name:-<empty>}
  SQL Instance ID:           ${sql_instance_id:-<none>}
  SQL User ID:               ${sql_user_id:-<none>}
  VPC Network ID:            ${network_id:-<none>}
  Subnetwork ID:             ${subnetwork_id:-<none>}
  DNS Managed Zone ID:       ${dns_zone_id_primary:-<none>} (fallback: ${dns_zone_id_fallback:-<none>})
  Redis Instance ID:         ${redis_id:-<none>}
  Materialization Dump Bucket Path:   ${materialization_dump_bucket_path:-<none>}
  Materialization Upload Bucket Path: ${materialization_upload_bucket_path:-<none>}
  Skeleton Cache Cloudpath:     ${skeleton_cache_cloudpath:-<none>}
INFO

# Import the SQL user (if we have enough info)
if [ -n "${sql_user_id}" ]; then
  if has_state "google_sql_user.writer"; then
    echo "SQL user already managed: google_sql_user.writer (skipping import)"
  else
    echo "Importing SQL user..."
    terragrunt --working-dir "$WORK_DIR" import "google_sql_user.writer" "$sql_user_id"
  fi
else
  echo "Skipping SQL user import (missing project_id/sql_instance_name/postgres_write_user)"
fi

# Import the compute network (if we have enough info)
if [ -n "${network_id}" ]; then
  if has_state "google_compute_network.vpc"; then
    echo "VPC network already managed: google_compute_network.vpc (skipping import)"
  else
    echo "Importing compute network..."
    terragrunt --working-dir "$WORK_DIR" import "google_compute_network.vpc" "$network_id"
  fi
else
  echo "Skipping VPC network import (missing project_id/network_name)"
fi

# Import the subnetwork
if [ -n "${subnetwork_id}" ]; then
  if has_state "google_compute_subnetwork.subnet"; then
    echo "Subnetwork already managed: google_compute_subnetwork.subnet (skipping import)"
  else
    echo "Importing subnetwork..."
    terragrunt --working-dir "$WORK_DIR" import "google_compute_subnetwork.subnet" "$subnetwork_id"
  fi
else
  echo "Skipping subnetwork import (missing project_id/region/subnetwork_name)"
fi

# Import the Cloud SQL database instance
if [ -n "${sql_instance_id}" ]; then
  if has_state "google_sql_database_instance.postgres"; then
    echo "SQL instance already managed: google_sql_database_instance.postgres (skipping import)"
  else
    echo "Importing SQL instance..."
    terragrunt --working-dir "$WORK_DIR" import "google_sql_database_instance.postgres" "$sql_instance_id"
  fi
else
  echo "Skipping SQL instance import (missing project_id/sql_instance_name)"
fi

# Import SQL databases (annotation, materialization) with fallback ID formats
if [ -n "${project_id}" ] && [ -n "${sql_instance_name}" ]; then
  import_try "google_sql_database.annotation"     "${project_id}/${sql_instance_name}/annotation"     "projects/${project_id}/instances/${sql_instance_name}/databases/annotation"
  import_try "google_sql_database.materialization" "${project_id}/${sql_instance_name}/materialization" "projects/${project_id}/instances/${sql_instance_name}/databases/materialization"
else
  echo "Skipping SQL database imports (missing project_id/sql_instance_name)"
fi

# Import DNS managed zone (primary)
if [ -n "${dns_zone_id_primary}" ]; then
  import_try "google_dns_managed_zone.primary" "$dns_zone_id_primary" "$dns_zone_id_fallback"
else
  echo "Skipping DNS managed zone import (missing project_id/dns_zone_name)"
fi

# Import Redis instance (pcg_redis)
if [ -n "${redis_id}" ]; then
  if has_state "google_redis_instance.pcg_redis"; then
    echo "Redis instance already managed: google_redis_instance.pcg_redis (skipping import)"
  else
    echo "Importing Redis instance..."
    terragrunt --working-dir "$WORK_DIR" import "google_redis_instance.pcg_redis" "$redis_id"
  fi
else
  echo "Skipping Redis import (missing project_id/region/redis_name)"
fi

# Import materialization buckets (extract bucket name from path if path includes /)
if [ -n "${materialization_dump_bucket_path}" ]; then
  # Extract bucket name from path (first part before /)
  dump_bucket_name=$(echo "$materialization_dump_bucket_path" | sed -n -e 's/^\([^/]*\).*$/\1/p')
  if [ -n "${dump_bucket_name}" ]; then
    if has_state "google_storage_bucket.materialization_dump"; then
      echo "Materialization dump bucket already managed: google_storage_bucket.materialization_dump (skipping import)"
    else
      echo "Importing materialization dump bucket: $dump_bucket_name (extracted from path: $materialization_dump_bucket_path)"
      terragrunt --working-dir "$WORK_DIR" import "google_storage_bucket.materialization_dump" "$dump_bucket_name"
    fi
  else
    echo "Skipping materialization dump bucket import (unable to extract bucket name from path: $materialization_dump_bucket_path)"
  fi
else
  echo "Skipping materialization dump bucket import (missing materialization_dump_bucket_path)"
fi

if [ -n "${materialization_upload_bucket_path}" ]; then
  # Extract bucket name from path (first part before /)
  upload_bucket_name=$(echo "$materialization_upload_bucket_path" | sed -n -e 's/^\([^/]*\).*$/\1/p')
  if [ -n "${upload_bucket_name}" ]; then
    if has_state "google_storage_bucket.materialization_upload"; then
      echo "Materialization upload bucket already managed: google_storage_bucket.materialization_upload (skipping import)"
    else
      echo "Importing materialization upload bucket: $upload_bucket_name (extracted from path: $materialization_upload_bucket_path)"
      terragrunt --working-dir "$WORK_DIR" import "google_storage_bucket.materialization_upload" "$upload_bucket_name"
    fi
  else
    echo "Skipping materialization upload bucket import (unable to extract bucket name from path: $materialization_upload_bucket_path)"
  fi
else
  echo "Skipping materialization upload bucket import (missing materialization_upload_bucket_path)"
fi

if [ -n ${skeleton_cache_cloudpath}] ;then 
  skeleton_cache_bucket_name=$(echo "$skeleton_cache_cloudpath" | sed -n -e 's/^gs:\/\/\([^/]*\).*$/\1/p')
  if [ -n "${skeleton_cache_bucket_name}" ]; then
    if has_state "google_storage_bucket.skeleton_cache"; then
      echo "Skeleton cache bucket already managed: google_storage_bucket.skeleton_cache (skipping import)"
    else
      echo "Importing skeleton cache bucket..."
      terragrunt --working-dir "$WORK_DIR" import "google_storage_bucket.skeleton_cache" "$skeleton_cache_bucket_name"
    fi
  else
    echo "Skipping skeleton cache bucket import (unable to parse bucket name from skeleton_cache_cloudpath)"
  fi
else
  echo "Skipping skeleton cache bucket import (missing skeleton_cache_cloudpath)"
fi

echo "Import completed."