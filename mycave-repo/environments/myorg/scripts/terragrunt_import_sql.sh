#!/usr/bin/env bash
# Wrapper that invokes the import script from terraform-cave-private or a vendored copy.
set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd)
SCRIPT_PATH="${DIR}/../../../../terraform-cave-private/environments/scripts/terragrunt_import_sql.sh"
if [ ! -f "$SCRIPT_PATH" ]; then
  echo "error: import script not found at $SCRIPT_PATH; copy it into your repo or update this path" >&2
  exit 1
fi
exec "$SCRIPT_PATH" "$@"
