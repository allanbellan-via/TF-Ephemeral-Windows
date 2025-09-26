#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 <WORKSPACE> [OPCIONAIS -var ...]" >&2
  echo "Ex.: $0 public-api-3E40A... -var 'ocpus=4' -var 'memory_in_gbs=16'" >&2
  exit 1
fi

WS="$1"; shift 1

terraform workspace list >/dev/null 2>&1 || terraform init
if ! terraform workspace list | grep -q "^  $WS$\|^* $WS$"; then
  terraform workspace new "$WS"
fi
terraform workspace select "$WS"

terraform apply -auto-approve "$@"

# Outputs úteis para o n8n
terraform output -json