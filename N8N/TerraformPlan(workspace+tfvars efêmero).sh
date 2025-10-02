#!/usr/bin/env bash
set -euo pipefail

export PATH="$PATH:/usr/local/bin:/usr/bin:/bin"
export TF_IN_AUTOMATION=1
export OCI_CLI_PROFILE="${OCI_CLI_PROFILE:-DEFAULT}"
export OCI_CLI_CONFIG_FILE="${OCI_CLI_CONFIG_FILE:-$HOME/.oci/config}"

REPO_DIR="/home/ubuntu/TF-Ephemeral-Windows"
cd "$REPO_DIR"

# ===== Variáveis vindas do n8n (env vars) =====
WS="{{ $('Edit Fields').item.json.ws }}"
REGION="{{ $('Edit Fields').item.json.region }}"
PROFILE="{{ $('Edit Fields').item.json.oci_config_file_profile }}"

TENANCY="{{ $('Edit Fields').item.json.tenancy_ocid }}"
COMPART="{{ $('Edit Fields').item.json.compartment_ocid }}"
SUBNET="{{ $('Edit Fields').item.json.subnet_ocid }}"

SHAPE="{{ $('Edit Fields').item.json.shape }}"
OCPUS="{{ $('Edit Fields').item.json.ocpus }}"
MEM="{{ $('Edit Fields').item.json.memory_in_gbs }}"
BOOT="{{ $('Edit Fields').item.json.boot_volume_size_in_gbs }}"
PUBIP="{{ $('Edit Fields').item.json.assign_public_ip }}"

ADNUM="{{ $('Edit Fields').item.json.ad_number }}"
ADOVR="{{ $('Edit Fields').item.json.availability_domain }}"

INJ="{{ $('Edit Fields').item.json.inject_user_data }}"
TPL="${TPL:-${REPO_DIR}/userdata_win.ps1}"
VIAU="Viaadmin"
VIAP="{{ $('Edit Fields').item.json.viaadmin_password }}"
TESTU="{{ $('Edit Fields').item.json.test_username }}"
TESTP="{{ $('Edit Fields').item.json.test_password }}"
OWNER="{{ $('Edit Fields').item.json.owner_tag }}"

DEBUG_LOGS="${DEBUG_LOGS:-false}" # true para mostrar logs

bool() { case "$1" in true|True|TRUE|1) echo true;; *) echo false;; esac; }

PUBIP=$(bool "${PUBIP}")
INJ=$(bool "${INJ}")

# ------- Lock para evitar corridas -------
LOCK="/tmp/tf-ephemeral.lock"
exec 200>"$LOCK"
flock -n 200 || { echo '{"ok":false,"error":"Another run is in progress"}'; exit 1; }

# ------- Checagens rápidas -------
if [ -z "${WS:-}" ]; then
  echo '{"ok":false,"error":"WS (workspace) não informado"}'
  exit 1
fi

# Validar template antes (se for injetar)
if [ "$INJ" = "true" ] && [ ! -f "$TPL" ]; then
  echo "{\"ok\":false,\"error\":\"Template de user_data não encontrado em $TPL\"}"
  exit 1
fi

# ------- Mensuração de tempo -------
SECONDS=0

# ------- Terraform init/workspace -------
terraform init -upgrade -no-color > /tmp/tf-init.log 2>&1 || {
  echo '{"ok":false,"error":"terraform init failed"}'
  $DEBUG_LOGS && cat /tmp/tf-init.log
  exit 1
}

# Seleção de workspace sem regex
if terraform workspace list | sed 's/*//g' | awk '{$1=$1};1' | grep -Fq "$WS"; then
  terraform workspace select "$WS" -no-color >/dev/null
else
  terraform workspace new "$WS" -no-color >/dev/null && terraform workspace select "$WS" -no-color >/dev/null
fi

# -------- tfvars efêmero por workspace --------
TFVARS_PATH="/tmp/tfvars-${WS}.auto.tfvars"
cat > "$TFVARS_PATH" <<EOF
oci_config_file_profile = "${PROFILE}"
region                  = "${REGION}"

tenancy_ocid            = "${TENANCY}"
compartment_ocid        = "${COMPART}"
subnet_ocid             = "${SUBNET}"

shape                   = "${SHAPE}"
ocpus                   = ${OCPUS}
memory_in_gbs           = ${MEM}
boot_volume_size_in_gbs = ${BOOT}
assign_public_ip        = ${PUBIP}

ad_number               = ${ADNUM}
availability_domain     = "${ADOVR}"

inject_user_data        = ${INJ}
userdata_template_path  = "${TPL}"
viaadmin_username       = "${VIAU}"
viaadmin_password       = "${VIAP}"
test_username           = "${TESTU}"
test_password           = "${TESTP}"

owner_tag               = "${OWNER}"
ws                      = "${WS}"
EOF

terraform fmt -recursive >/dev/null 2>&1 || true
terraform validate -no-color > /tmp/tf-validate.log 2>&1 || {
  echo '{"ok":false,"error":"terraform validate failed"}'
  $DEBUG_LOGS && cat /tmp/tf-validate.log
  exit 1
}

# ------- Plan (apenas validação pré-apply) -------
terraform plan -var-file="$TFVARS_PATH" -input=false -no-color > /tmp/tf-plan.log 2>&1 || {
  echo '{"ok":false,"error":"terraform plan failed"}'
  $DEBUG_LOGS && cat /tmp/tf-plan.log
  exit 1
}

# ------- Apply -------
terraform apply -var-file="$TFVARS_PATH" -auto-approve -input=false -no-color > /tmp/tf-apply.log 2>&1 || {
  echo '{"ok":false,"error":"terraform apply failed"}'
  $DEBUG_LOGS && cat /tmp/tf-apply.log
  exit 1
}

# ------- Coleta de outputs -------
OUT_JSON=$(terraform output -json || echo '{}')

# Extrai campos de forma segura
name=$(echo "$OUT_JSON"  | jq -r '.display_name.value // empty' 2>/dev/null || echo "")
iid=$(echo "$OUT_JSON"   | jq -r '.instance_id.value // empty' 2>/dev/null || echo "")
pip=$(echo "$OUT_JSON"   | jq -r '.private_ip.value // empty'  2>/dev/null || echo "")
pubip=$(echo "$OUT_JSON" | jq -r '.public_ip.value // empty'   2>/dev/null || echo "")

# Monta URL genérica do console (página de compute)
console_url="https://cloud.oracle.com/?region=${REGION}&service=compute"

elapsed=$SECONDS

# JSON final “bonito”
jq -n \
  --arg name "$name" \
  --arg iid "$iid" \
  --arg pip "$pip" \
  --arg pubip "$pubip" \
  --arg region "$REGION" \
  --arg ws "$WS" \
  --arg owner "$OWNER" \
  --arg console "$console_url" \
  --arg lifecycle "short" \
  --arg purpose "AutomacaoDeTestes-Tecnologia" \
  --argjson elapsed "$elapsed" '
{
  ok: true,
  message: "VM criada com sucesso",
  workspace: $ws,
  elapsed_sec: $elapsed,
  instance: {
    id: $iid,
    name: $name,
    region: $region,
    private_ip: $pip,
    public_ip: $pubip,
    console_url: $console
  },
  tags: {
    owner: $owner,
    lifecycle: $lifecycle,
    purpose: $purpose
  }
}'
