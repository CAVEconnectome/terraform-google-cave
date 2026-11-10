#!/usr/bin/env bash
# Import existing Cloud SQL and VPC resources into Terraform state via Terragrunt
# Usage:
#   ./terragrunt_import_sql.sh [--fix-mismatch] [TERRAGRUNT_MODULE_DIR]
# If no directory is provided, the current directory is used. The directory
# must contain a terragrunt.hcl that defines the resources being imported.
#
# An address that is already in state is normally left alone, but "already in
# state" is not the same as "pointing at the resource the config asks for": if
# e.g. sql_instance_name changed after a previous import, state still holds the
# old instance. Those stale entries are reported, and with --fix-mismatch they
# are removed from state and re-imported against the current config.

set -euo pipefail

WORK_DIR=""
FIX_MISMATCH="${FIX_MISMATCH:-0}"
while [ $# -gt 0 ]; do
  case "$1" in
    --fix-mismatch)    FIX_MISMATCH=1 ;;
    --no-fix-mismatch) FIX_MISMATCH=0 ;;
    -h|--help)
      echo "usage: $0 [--fix-mismatch] [TERRAGRUNT_MODULE_DIR]"
      exit 0
      ;;
    *) WORK_DIR="$1" ;;
  esac
  shift
done
WORK_DIR="${WORK_DIR:-$(pwd)}"

if [ ! -f "$WORK_DIR/terragrunt.hcl" ]; then
  echo "error: no terragrunt.hcl found in: $WORK_DIR" >&2
  echo "usage: $0 [--fix-mismatch] /path/to/module" >&2
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

# Snapshot the state once. `state show` output is not machine-readable, so the
# pulled JSON is what we inspect to see which cloud resource each address holds.
# The copy also doubles as a restore point if a removal/re-import goes wrong.
STATE_JSON="$(mktemp)"
trap 'rm -f "$STATE_JSON"' EXIT
if ! terragrunt --working-dir "$WORK_DIR" state pull > "$STATE_JSON" 2>/dev/null || [ ! -s "$STATE_JSON" ]; then
  echo '{"resources":[]}' > "$STATE_JSON"
fi
STATE_BACKUP="${TMPDIR:-/tmp}/terragrunt-import-backup-$(basename "$WORK_DIR").tfstate"
cp "$STATE_JSON" "$STATE_BACKUP"
echo "State snapshot saved to: $STATE_BACKUP"
echo "  (restore with: terragrunt --working-dir $WORK_DIR state push $STATE_BACKUP)"

# Helper: print one attribute of a state address, or nothing if absent.
# Matches with or without a count/for_each index, so "foo.bar" also finds "foo.bar[0]".
state_attr() {
  local addr="$1" attr="$2"
  jq -r --arg addr "$addr" --arg attr "$attr" '
    (.resources // [])[]
    | select(((if (.module // "") == "" then "" else .module + "." end) + .type + "." + .name) == $addr)
    | (.instances // [])[0].attributes[$attr] // empty
  ' "$STATE_JSON" 2>/dev/null | head -1
}

# Helper: classify a state address against what the config asks for.
#   0 -> in state, pointing at the expected resource (nothing to do)
#   1 -> not in state (import it)
#   2 -> in state, pointing at something else (stale entry; sets MISMATCH_DETAIL)
# $2 is the attribute holding the identity ("name", or "instance" for Cloud SQL
# children) and $3 the value the current config expects it to have.
MISMATCH_DETAIL=""
state_status() {
  local addr="$1" attr="$2" expected="$3"
  local actual
  actual="$(state_attr "$addr" "$attr")"
  if [ -z "$actual" ]; then
    # Absent from the snapshot, or present without that attribute. Fall back to
    # `state show` so an unreadable attribute never triggers a bogus re-import.
    has_state "$addr" || return 1
    return 0
  fi
  [ -z "$expected" ] && return 0
  [ "$actual" = "$expected" ] && return 0
  MISMATCH_DETAIL="$addr: state has $attr=\"$actual\", config wants \"$expected\""
  return 2
}

# Collected stale entries, reported together at the end.
MISMATCHES=""

# Helper: import an address unless state already points at the right resource.
# usage: import_resource ADDR ID_ATTR EXPECTED_ID_VALUE IMPORT_ID [FALLBACK_IMPORT_ID]
# The fallback is used when providers accept multiple ID syntaxes.
import_resource() {
  local addr="$1" attr="$2" expected="$3" id_primary="$4" id_fallback="${5:-}"
  local rc=0
  set +e
  state_status "$addr" "$attr" "$expected"
  rc=$?
  set -e
  case $rc in
    0)
      echo "$addr already managed${expected:+ as \"$expected\"} (skipping import)"
      return 0
      ;;
    2)
      echo "WARNING: stale state entry -- $MISMATCH_DETAIL" >&2
      if [ "$FIX_MISMATCH" != "1" ]; then
        MISMATCHES="${MISMATCHES}  ${MISMATCH_DETAIL}
"
        echo "  state left untouched. Re-run with --fix-mismatch, or by hand:" >&2
        echo "    terragrunt --working-dir \"$WORK_DIR\" state rm $addr" >&2
        echo "    terragrunt --working-dir \"$WORK_DIR\" import $addr $id_primary" >&2
        return 0
      fi
      echo "  removing $addr from state so it can be re-imported"
      terragrunt --working-dir "$WORK_DIR" state rm "$addr"
      ;;
  esac
  if [ -z "$id_primary" ]; then
    echo "Skipping import for $addr (missing import ID)"
    return 0
  fi
  echo "Importing $addr with: $id_primary"
  set +e
  terragrunt --working-dir "$WORK_DIR" import "$addr" "$id_primary"
  rc=$?
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
# Identity is the instance it belongs to; the username itself is sensitive in state.
if [ -n "${sql_user_id}" ]; then
  import_resource "google_sql_user.writer" "instance" "$sql_instance_name" "$sql_user_id"
else
  echo "Skipping SQL user import (missing project_id/sql_instance_name/postgres_write_user)"
fi

# Import the compute network (if we have enough info)
if [ -n "${network_id}" ]; then
  import_resource "google_compute_network.vpc" "name" "$network_name" "$network_id"
else
  echo "Skipping VPC network import (missing project_id/network_name)"
fi

# Import the subnetwork
if [ -n "${subnetwork_id}" ]; then
  import_resource "google_compute_subnetwork.subnet" "name" "$subnetwork_name" "$subnetwork_id"
else
  echo "Skipping subnetwork import (missing project_id/region/subnetwork_name)"
fi

# Import the Cloud SQL database instance
if [ -n "${sql_instance_id}" ]; then
  import_resource "google_sql_database_instance.postgres" "name" "$sql_instance_name" "$sql_instance_id"
else
  echo "Skipping SQL instance import (missing project_id/sql_instance_name)"
fi

# Import SQL databases (annotation, materialization) with fallback ID formats
if [ -n "${project_id}" ] && [ -n "${sql_instance_name}" ]; then
  import_resource "google_sql_database.annotation" "instance" "$sql_instance_name" \
    "${project_id}/${sql_instance_name}/annotation" \
    "projects/${project_id}/instances/${sql_instance_name}/databases/annotation"
  import_resource "google_sql_database.materialization" "instance" "$sql_instance_name" \
    "${project_id}/${sql_instance_name}/materialization" \
    "projects/${project_id}/instances/${sql_instance_name}/databases/materialization"
else
  echo "Skipping SQL database imports (missing project_id/sql_instance_name)"
fi

# Import DNS managed zone (primary)
if [ -n "${dns_zone_id_primary}" ]; then
  import_resource "google_dns_managed_zone.primary" "name" "$dns_zone_name" \
    "$dns_zone_id_primary" "$dns_zone_id_fallback"
else
  echo "Skipping DNS managed zone import (missing project_id/dns_zone_name)"
fi

# Import Redis instance (pcg_redis)
if [ -n "${redis_id}" ]; then
  import_resource "google_redis_instance.pcg_redis" "name" "$redis_name" "$redis_id"
else
  echo "Skipping Redis import (missing project_id/region/redis_name)"
fi

# Import materialization buckets (extract bucket name from path if path includes /)
if [ -n "${materialization_dump_bucket_path}" ]; then
  # Extract bucket name from path (first part before /)
  dump_bucket_name=$(echo "$materialization_dump_bucket_path" | sed -n -e 's/^\([^/]*\).*$/\1/p')
  if [ -n "${dump_bucket_name}" ]; then
    echo "Materialization dump bucket: $dump_bucket_name (from path: $materialization_dump_bucket_path)"
    import_resource "google_storage_bucket.materialization_dump" "name" \
      "$dump_bucket_name" "$dump_bucket_name"
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
    echo "Materialization upload bucket: $upload_bucket_name (from path: $materialization_upload_bucket_path)"
    import_resource "google_storage_bucket.materialization_upload" "name" \
      "$upload_bucket_name" "$upload_bucket_name"
  else
    echo "Skipping materialization upload bucket import (unable to extract bucket name from path: $materialization_upload_bucket_path)"
  fi
else
  echo "Skipping materialization upload bucket import (missing materialization_upload_bucket_path)"
fi

if [ -n "${skeleton_cache_cloudpath}" ]; then
  skeleton_cache_bucket_name=$(echo "$skeleton_cache_cloudpath" | sed -n -e 's/^gs:\/\/\([^/]*\).*$/\1/p')
  if [ -n "${skeleton_cache_bucket_name}" ]; then
    import_resource "google_storage_bucket.skeleton_cache" "name" \
      "$skeleton_cache_bucket_name" "$skeleton_cache_bucket_name"
  else
    echo "Skipping skeleton cache bucket import (unable to parse bucket name from skeleton_cache_cloudpath)"
  fi
else
  echo "Skipping skeleton cache bucket import (missing skeleton_cache_cloudpath)"
fi

if [ -n "$MISMATCHES" ]; then
  cat >&2 <<MISMATCH
Import completed, but these state entries point at resources the config no
longer asks for, so they were NOT imported:

$MISMATCHES
Re-run with --fix-mismatch to remove and re-import them, or run the
state rm/import pairs printed above by hand. State backup: $STATE_BACKUP
MISMATCH
  exit 1
fi

echo "Import completed."