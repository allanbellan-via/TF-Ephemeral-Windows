set -euo pipefail
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin"
export OCI_CLI_PROFILE="${OCI_CLI_PROFILE:-DEFAULT}"

REPO_DIR="/home/ubuntu/TF-Ephemeral-Windows"
cd "$REPO_DIR"

# ===== Variáveis vindas do n8n (env vars) =====
WS="${WS:-default}"
REGION="${REGION:-sa-saopaulo-1}"
PROFILE="${OCI_CLI_PROFILE:-DEFAULT}"

TENANCY="${TENANCY:-}"
COMPART="${COMPART:-}"
SUBNET="${SUBNET:-}"
NSG_IDS_JSON="${NSG_IDS_JSON:-[]}"

SHAPE="${SHAPE:-VM.Standard.E4.Flex}"
OCPUS="${OCPUS:-2}"
MEM="${MEM:-16}"
BOOT="${BOOT:-256}"
PUBIP="${PUBIP:-false}"

ADNUM="${ADNUM:-1}"
ADOVR="${ADOVR:-}"
IMGOVR="${IMGOVR:-}"

INJ="${INJ:-true}"
TPL="${TPL:-${REPO_DIR}/userdata_win.ps1}"
VIAU="${VIAU:-ViaAdmin}"
VIAP="${VIAP:-}"
TESTU="${TESTU:-TestUser}"
TESTP="${TESTP:-}"
OWNER="${OWNER:-owner}"

# ===== Lock para evitar concorrência =====
LOCK="/tmp/tf-ephemeral.lock"
exec 200>"$LOCK"
flock -n 200 || { echo "Another run is in progress"; exit 1; }

# ===== Init e Workspace =====
terraform init -upgrade
if terraform workspace list | grep -qE "^[* ]\s*$WS\b" ; then
  terraform workspace select "$WS"
else
  terraform workspace new "$WS" && terraform workspace select "$WS"
fi

# ===== tfvars efêmero =====
TFVARS_PATH="/tmp/tfvars-${WS}.auto.tfvars"
cat > "$TFVARS_PATH" <<EOF
oci_config_file_profile = "${PROFILE}"
region                  = "${REGION}"

tenancy_ocid            = "${TENANCY}"
compartment_ocid        = "${COMPART}"
subnet_ocid             = "${SUBNET}"
nsg_ids                 = ${NSG_IDS_JSON}

shape                   = "${SHAPE}"
ocpus                   = ${OCPUS}
memory_in_gbs           = ${MEM}
boot_volume_size_in_gbs = ${BOOT}
assign_public_ip        = ${PUBIP}

ad_number               = ${ADNUM}
availability_domain     = "${ADOVR}"

image_ocid_override     = "${IMGOVR}"

inject_user_data        = ${INJ}
userdata_template_path  = "${TPL}"
viaadmin_username       = "${VIAU}"
viaadmin_password       = "${VIAP}"
test_username           = "${TESTU}"
test_password           = "${TESTP}"

owner_tag               = "${OWNER}"
EOF

terraform fmt -recursive
terraform validate

# ===== Plan (gera arquivo .plan) =====
TFPLAN_PATH="/tmp/tfplan-${WS}"
terraform plan -var-file="$TFVARS_PATH" -input=false -no-color -out="$TFPLAN_PATH"

# ===== Exibir plan humano completo =====
PLAN_TXT="/tmp/plan-${WS}.txt"
terraform show -no-color "$TFPLAN_PATH" | tee "$PLAN_TXT" >/dev/null

# ===== Também salva JSON (útil para automações) =====
PLAN_JSON="/tmp/plan-${WS}.json"
terraform show -json "$TFPLAN_PATH" > "$PLAN_JSON"

echo "==================== PLAN (workspace: ${WS}) ===================="
cat "$PLAN_TXT"
echo "================== FIM DO PLAN (workspace: ${WS}) ==============="

echo ""
echo "Arquivos gerados:"
echo "  - $PLAN_TXT  (legível/humano)"
echo "  - $PLAN_JSON (JSON para automação)"
