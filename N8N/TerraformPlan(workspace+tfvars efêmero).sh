set -euo pipefail
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin"
export OCI_CLI_PROFILE="${OCI_CLI_PROFILE:-DEFAULT}"

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
TESTU="tec.user"
TESTP="{{ $('Edit Fields').item.json.test_password }}"
OWNER="{{ $('Edit Fields').item.json.owner_tag }}"

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





set -euo pipefail
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin"
export OCI_CLI_PROFILE="${OCI_CLI_PROFILE:-DEFAULT}"

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
TESTU="tec.user"
TESTP="{{ $('Edit Fields').item.json.test_password }}"
OWNER="{{ $('Edit Fields').item.json.owner_tag }}"

# -------- Lock para evitar concorrência --------
LOCK="/tmp/tf-ephemeral.lock"
exec 200>"$LOCK"
flock -n 200 || { echo "Another run is in progress"; exit 1; }

# -------- Terraform init + workspace --------
terraform init -upgrade
if terraform workspace list | grep -qE "^[* ]\s*$WS\b" ; then
  terraform workspace select "$WS"
else
  terraform workspace new "$WS" && terraform workspace select "$WS"
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
EOF

terraform fmt -recursive
terraform validate

# -------- Plan + Apply (sem arquivo .plan compartilhado) --------
terraform plan  -var-file="$TFVARS_PATH" -input=false -no-color
terraform apply -var-file="$TFVARS_PATH" -auto-approve -input=false -no-color

# -------- Outputs p/ webhook --------
terraform output -json > "/tmp/tf-outputs-${WS}.json"
cat "/tmp/tf-outputs-${WS}.json"
