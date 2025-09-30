# TF-Ephemeral-Windows

Infra as Code para **subir VMs Windows efêmeras na OCI** (Oracle Cloud Infrastructure) com Terraform.  
Foco: **desenvolvimento/testes**, criação rápida, **auto-descoberta de AD**, **lookup automático de imagem** (com *override* por OCID) e **user_data** flexível via template PowerShell.

---

## Sumário

- [Arquitetura & Highlights](#arquitetura--highlights)  
- [Pré-requisitos](#pré-requisitos)  
- [Autenticação (OCI-CLI)](#autenticação-oci-cli)  
- [Estrutura dos arquivos](#estrutura-dos-arquivos)  
- [Variáveis principais](#variáveis-principais)  
- [User Data flexível (templatefile)](#user-data-flexível-templatefile)  
- [Auto-AD (`ad_auto.tf`)](#auto-ad-ad_autotf)  
- [Lookup de Imagem (com override)](#lookup-de-imagem-com-override)  
- [Exemplo de `terraform.tfvars`](#exemplo-de-terraformtfvars)  
- [Como executar](#como-executar)  
- [Políticas IAM necessárias](#políticas-iam-necessárias)  
- [Solução de problemas](#solução-de-problemas)

---

## Arquitetura & Highlights

- **Terraform + oci provider** usando credenciais do **OCI-CLI** (`~/.oci/config`).
- **Auto-AD**: seleciona automaticamente o *Availability Domain* (AD-1/2/3) via `tenancy_ocid` + `ad_number`.  
- **Lookup de Imagem Windows 2022**: tenta *Server 2022 Standard* e cai para *Server 2022* genérico, **filtrando pelo `shape`** para evitar incompatibilidades.  
- **Override de Imagem por OCID**: defina `image_ocid_override` para usar uma imagem específica.  
- **User Data flexível**: caminho do template PowerShell configurável por variável; é possível habilitar/desabilitar a injeção.  
- **Efêmero por padrão**: `freeform_tags.lifecycle = "short"`, `preserve_boot_volume = false`.

---

## Pré-requisitos

- **Terraform** ≥ 1.4  
- **OCI-CLI** configurado em `~/.oci/config` (perfil, `user`, `tenancy`, `fingerprint`, `key_file`, `region`).  
  > Permissões dos arquivos devem ser restritas:
  >
  > ```bash
  > oci setup repair-file-permissions --file ~/.oci/config
  > oci setup repair-file-permissions --file ~/.oci/*.pem
  > chmod 600 ~/.oci/config ~/.oci/*.pem
  > ```

---

## Autenticação (OCI-CLI)

O provider usa o **perfil** do OCI-CLI:

```hcl
provider "oci" {
  region              = var.region                   # pode herdar do profile
  config_file_profile = var.oci_config_file_profile  # ex.: "DEFAULT"
}
```

> **Não** usamos `auth = "InstancePrincipal"`.  
> Se `region` ficar vazia (`""`), o provider usa a região do perfil no `~/.oci/config`.

---

## Estrutura dos arquivos

```text
.
├─ providers.tf            # provider OCI (via OCI-CLI)
├─ variables.tf            # variáveis do projeto
├─ locals.tf               # nomes, workspace, etc.
├─ ad_auto.tf              # auto-descoberta do AD
├─ main.tf                 # lookup de imagem + criação da VM
├─ userdata_win.ps1        # template padrão do user_data (pode mudar via var)
├─ outputs.tf              # outputs úteis
└─ terraform.tfvars        # valores (pode vir do n8n)
```

---

## Variáveis principais

**Autenticação / Região**
- `oci_config_file_profile` *(string)*: Perfil do OCI-CLI (padrão: `"DEFAULT"`).  
- `region` *(string)*: Região OCI (ex.: `"sa-saopaulo-1"`). Pode ficar vazio para herdar do profile.

**Auto-AD**
- `tenancy_ocid` *(string)*: Tenancy para listar ADs.  
- `availability_domain` *(string)*: Se preenchido, força um AD específico (ex.: `"aGcE:SA-SAOPAULO-1-AD-1"`).  
- `ad_number` *(number, default `1`)*: Quando **não** há `availability_domain`, usa AD-1/2/3 via este índice.

**Infra**
- `compartment_ocid` *(string)*, `subnet_ocid` *(string)*, `nsg_ids` *(list(string), default `[]`)*.  
- `shape` *(string, ex.: `"VM.Standard.E4.Flex"`)*, `ocpus` *(number)*, `memory_in_gbs` *(number)*, `boot_volume_size_in_gbs` *(number)*, `assign_public_ip` *(bool)*.

**Imagem**
- Lookup tenta `"Server 2022 Standard"` e `"Server 2022"` **com `shape` filtrado**.  
- `image_ocid_override` *(string, default `""`)*: se definido, ignora o lookup e usa esse OCID.

**User Data**
- `inject_user_data` *(bool, default `true`)*: liga/desliga envio de `metadata.user_data`.  
- `userdata_template_path` *(string, default `"${path.module}/userdata_win.ps1"`)*: caminho do template (relativo ou absoluto).  
- Credenciais usadas pelo template: `viaadmin_username`, `viaadmin_password`, `test_username`, `test_password`.

**Tags / nomes**
- `owner_tag` *(string)*: dono (vai em `freeform_tags.owner`).  
- `locals.tf` define `local.display_name`, `local.hostname`, `local.ws` etc.

---

## User Data flexível (templatefile)

**Trecho do `main.tf`:**
```hcl
metadata = var.inject_user_data ? {
  user_data = base64encode(
    templatefile(var.userdata_template_path, {
      ViaAdminUsername = var.viaadmin_username
      ViaAdminPassword = var.viaadmin_password
      TestUsername     = var.test_username
      TestPassword     = var.test_password
    })
  )
} : {}
```

> Há uma **precondition** para falhar se `inject_user_data = true` e o arquivo não existir.

---

## Auto-AD (`ad_auto.tf`)

```hcl
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

locals {
  ads           = try(data.oci_identity_availability_domains.ads.availability_domains, [])
  ad_index      = var.ad_number - 1
  ad_by_number  = (length(local.ads) > local.ad_index && local.ad_index >= 0)
                  ? local.ads[local.ad_index].name
                  : ""
  ad_final      = var.availability_domain != "" ? var.availability_domain : local.ad_by_number
}
```

No recurso:
```hcl
availability_domain = local.ad_final
```

> Outra **precondition** informa caso o AD não seja determinado (ex.: falta permissão para listar ADs).

---

## Lookup de Imagem (com override)

```hcl
data "oci_core_images" "win2022_standard" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Windows"
  operating_system_version = "Server 2022 Standard"
  shape                    = var.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_core_images" "win2022_generic" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Windows"
  operating_system_version = "Server 2022"
  shape                    = var.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

locals {
  image_from_override = var.image_ocid_override
  image_from_std      = try(data.oci_core_images.win2022_standard.images[0].id, "")
  image_from_generic  = try(data.oci_core_images.win2022_generic.images[0].id, "")

  selected_image_ocid = (
    local.image_from_override != "" ? local.image_from_override :
    (local.image_from_std != "" ? local.image_from_std : local.image_from_generic)
  )

  image_found = local.selected_image_ocid != ""
}
```

No recurso:
```hcl
source_details {
  source_type             = "image"
  source_id               = local.selected_image_ocid
  boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
}

lifecycle {
  precondition {
    condition     = local.image_found
    error_message = "Nenhuma imagem Windows Server 2022 compatível. Defina -var 'image_ocid_override=ocid1.image...' ou ajuste policies/filtros."
  }
}
```

> Se aparecer **`InvalidParameter: Shape ... is not valid for image ...`**, a imagem não é compatível com o `shape`.  
> Solução: troque a imagem (use `oci compute image list --shape ...`) ou troque o `shape` (ex.: `VM.Standard3.Flex` para imagens PV antigas).

---

## Exemplo de `terraform.tfvars`

> **N8N**: você pode popular a maioria das variáveis dinamicamente; fixe apenas o necessário.

```hcl
# Autenticação via OCI-CLI
oci_config_file_profile = "DEFAULT"
region                  = "sa-saopaulo-1"

# Auto-AD
tenancy_ocid        = "ocid1.tenancy.oc1..AAAA..."
ad_number           = 1
availability_domain = ""   # vazio => auto-AD

# Infra
compartment_ocid    = "ocid1.compartment.oc1..BBBB..."
subnet_ocid         = "ocid1.subnet.oc1.sa-saopaulo-1.CCCC..."
nsg_ids             = []

# Shape / recursos
shape                    = "VM.Standard.E4.Flex"
ocpus                    = 2
memory_in_gbs            = 16
boot_volume_size_in_gbs  = 256
assign_public_ip         = false

# Imagem (override opcional)
image_ocid_override = ""

# User Data
inject_user_data       = true
userdata_template_path = "${path.module}/userdata_win.ps1"
viaadmin_username      = "ViaAdmin"
viaadmin_password      = "Troque-Segura#2025"
test_username          = "TestUser"
test_password          = "Troque-Segura#2025"

# Tags / nomes (locals complementam)
owner_tag = "allan"
```

---

## Como executar

```bash
terraform fmt
terraform init -upgrade
terraform plan   -var "compartment_ocid=ocid1.compartment.oc1..BBBB..."   -var "subnet_ocid=ocid1.subnet.oc1.sa-saopaulo-1.CCCC..."   -var "tenancy_ocid=ocid1.tenancy.oc1..AAAA..."   -var "region=sa-saopaulo-1"
terraform apply -auto-approve
```

**Dicas de descoberta de imagem compatível com o shape:**
```bash
oci compute image list   --compartment-id <TENANCY_OCID>   --operating-system Windows   --operating-system-version "Server 2022"   --shape VM.Standard.E4.Flex   --region sa-saopaulo-1 --all | jq -r '.data[] | "\(.["display-name"])  \(.id)"' | sort
```

---

## Políticas IAM necessárias

Políticas devem ser atribuídas ao **grupo** do usuário do OCI-CLI:

**Tenancy (raiz):**
```
Allow group <SEU_GRUPO> to inspect compartments in tenancy
Allow group <SEU_GRUPO> to read instance-images in tenancy
```

**Compartment de Compute (onde a VM é criada):**
```
Allow group <SEU_GRUPO> to manage instance-family in compartment <COMP_COMPUTE>
Allow group <SEU_GRUPO> to manage volume-family in compartment <COMP_COMPUTE>
```

**Compartment de Rede** (se for diferente):
```
Allow group <SEU_GRUPO> to use virtual-network-family in compartment <COMP_NETWORK>
# Se usar IP público reservado:
# Allow group <SEU_GRUPO> to manage public-ips in compartment <COMP_NETWORK>
# Se usar NSGs:
# Allow group <SEU_GRUPO> to use network-security-groups in compartment <COMP_NETWORK>
```

---

## Solução de problemas

- **401 NotAuthenticated**: verifique `~/.oci/config` (perfil, `user`, `tenancy`, `region`, `fingerprint`, `key_file`) e se a **API Key pública** está **cadastrada** no usuário (fingerprint deve bater).  
  Repare permissões de arquivos:
  ```bash
  oci setup repair-file-permissions --file ~/.oci/config
  oci setup repair-file-permissions --file ~/.oci/*.pem
  chmod 600 ~/.oci/config ~/.oci/*.pem
  ```
- **404 NotAuthorizedOrNotFound**: políticas IAM insuficientes (veja seção acima).  
- **`InvalidParameter: Shape ... is not valid for image ...`**: imagem incompatível com o `shape`; ajuste imagem ou shape.  
- **Falha em auto-AD**: falta permissão para listar ADs ou `tenancy_ocid` inválido.  
- **Template não encontrado**: com `inject_user_data = true`, confirme `userdata_template_path` (use caminho absoluto se o arquivo vier por automação/N8N).

---

**Licença:** MIT (ou a que você definir no repositório).  
**Contribuições:** PRs (Pull Requests) e issues são bem-vindos.
