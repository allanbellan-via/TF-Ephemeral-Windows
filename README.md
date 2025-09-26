# Ephemeral Windows 2022 (OCI) — Workspace Flow

Cada workspace = 1 VM. Ideal para testes efêmeros em paralelo, orquestrados pelo n8n.

## Pré-requisitos
- Terraform >= 1.6
- **provider_var.tf** privado com credenciais/região (já no .gitignore)
- Defina uma vez os defaults em `variables.tf`:
  - `compartment_ocid`, `subnet_ocid`, `availability_domain`

## Comandos básicos
terraform init

# Criar/atualizar VM do ChatId (sem precisar passar OCIDs/AD)
./scripts/apply.sh <ChatId> \
  -var 'shape=VM.Standard3.Flex' -var 'ocpus=2' -var 'memory_in_gbs=8'

# Ver outputs
terraform workspace select <ChatId>
terraform output

# Destruir a VM do ChatId
./scripts/destroy.sh <ChatId>

## n8n — Exemplo de fluxo
1. **Webhook** recebe `ChatId` e, opcionalmente, overrides (`ocpus`, `memory_in_gbs`, etc.).
2. **Execute Command**:
   - Command: `bash`
   - Input: `./scripts/apply.sh {{$json.ChatId}} -var 'ocpus={{$json.ocpus}}' -var 'memory_in_gbs={{$json.memory_in_gbs}}'`
3. **Parse Outputs** do `terraform output -json`.
4. **Notifique** IPs/resultados.

## Notas
- **Defaults**: `compartment_ocid`, `subnet_ocid`, `availability_domain` estão em `variables.tf`.
- **provider_var.tf**: mantém fora do git e preenche as credenciais do OCI.
- **Imagem Windows 2022**: lookup automático; se quiser fixar, use `-var 'image_ocid_override=ocid1.image...'`.
- **Artefatos**: ajuste o `userdata_win.ps1` para enviar logs ao Object Storage.