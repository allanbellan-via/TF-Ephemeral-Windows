#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 <WORKSPACE>" >&2
  exit 1
fi
WS="$1"

terraform workspace list >/dev/null 2>&1 || terraform init
terraform workspace select "$WS"
terraform destroy -auto-approve || true

# opcional: remover workspace após destruir
terraform workspace select default || true
terraform workspace delete -force "$WS" || true