############################################
# main.tf — Lookup de imagem + criação da VM
############################################

# ---------- LOOKUP DE IMAGEM ----------
# Primeiro tenta Windows Server 2022 Standard; se não achar, cai para "Server 2022" genérico
data "oci_core_images" "win2022_standard" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Windows"
  operating_system_version = "Server 2022 Standard"
  shape                    = var.shape            # garante compatibilidade com o shape escolhido
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_core_images" "win2022_generic" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Windows"
  operating_system_version = "Server 2022"
  shape                    = var.shape            # idem
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# ---------- LOCAIS (seleção da imagem) ----------
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

# ---------- RECURSO: INSTÂNCIA ----------
resource "oci_core_instance" "win" {
  # Usa o AD resolvido automaticamente em ad_auto.tf
  availability_domain = local.ad_final

  compartment_id = var.compartment_ocid
  display_name   = local.display_name
  shape          = var.shape

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = var.subnet_ocid
    assign_public_ip = var.assign_public_ip
    hostname_label   = local.hostname
    # Se você tiver NSGs opcionais nas variáveis, descomente a linha abaixo:
    # nsg_ids        = var.nsg_ids
  }

  source_details {
    source_type             = "image"
    source_id               = local.selected_image_ocid
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

# --- metadata: injeta user_data apenas se habilitado ---
  metadata = var.inject_user_data ? {
    user_data = base64encode(
      templatefile(local.userdata_template_effective, {
        ViaAdminUsername = var.viaadmin_username
        ViaAdminPassword = var.viaadmin_password
        TestUsername     = var.test_username
        TestPassword     = var.test_password
      })
    )
  } : {}


  preserve_boot_volume                  = false
  is_pv_encryption_in_transit_enabled   = true

  freeform_tags = {
    purpose   = "AutomacaoDeTestes-Tecnologia"
    owner     = var.owner_tag
    lifecycle = "short"
    workspace = local.ws
  }

  timeouts {
    create = "15m"
    delete = "15m"
  }

  lifecycle {
    # Falha clara se não achou imagem compatível
    precondition {
      condition     = local.image_found
      error_message = "Nenhuma imagem Windows Server 2022 compatível. Defina -var 'image_ocid_override=ocid1.image...' ou ajuste policies/filtros."
    }
    # Falha clara se não resolveu o AD (ex.: falta permissão para listar ADs)
    precondition {
      condition     = local.ad_final != ""
      error_message = "Não foi possível determinar o Availability Domain (auto-AD). Verifique tenancy_ocid, ad_number (1..3) e permissões para listar ADs."
    }
    # falhar com mensagem clara quando o arquivo metadata não existir e inject_user_data estiver ativo
    precondition {
      condition     = var.inject_user_data ? fileexists(local.userdata_template_abs) : true
      error_message = "Arquivo de template não encontrado em '${local.userdata_template_effective}'."
    }
  }
}