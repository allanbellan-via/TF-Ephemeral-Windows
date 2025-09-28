############################################
# main.tf — somente lógica de imagem + VM
############################################

# ---------- LOOKUP DE IMAGEM ----------
data "oci_core_images" "win2022_standard" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Windows"
  operating_system_version = "Server 2022 Standard"
  shape                    = var.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_core_images" "win2022_generic" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Windows"
  operating_system_version = "Server 2022"
  shape                    = var.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# ---------- LOCAIS (apenas os de imagem p/ evitar duplicata com locals.tf) ----------
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
  availability_domain = var.availability_domain   # ex.: "aGcE:SA-SAOPAULO-1-AD-1"
  compartment_id      = var.compartment_ocid
  display_name        = local.display_name        # definido em locals.tf
  shape               = var.shape

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = var.subnet_ocid
    assign_public_ip = var.assign_public_ip       # bool
    hostname_label   = local.hostname             # definido em locals.tf
    nsg_ids          = var.nsg_ids                # opcional
  }

  source_details {
    source_type             = "image"
    source_id               = local.selected_image_ocid
    boot_volume_size_in_gbs = var.boot_volume_size_gbs    # number; remova se quiser default
  }

  metadata = {
    user_data = base64encode(
      templatefile("${path.module}/userdata_win.ps1", {
        ViaAdminUsername = var.viaadmin_username
        ViaAdminPassword = var.viaadmin_password
        TestUsername     = var.test_username
        TestPassword     = var.test_password
      })
    )
  }

  preserve_boot_volume                = false
  is_pv_encryption_in_transit_enabled = true

  freeform_tags = {
    purpose   = "AutomacaoDeTestes-Tecnologia"
    owner     = "allan"
    lifecycle = "short"
    workspace = local.ws                     # definido em locals.tf
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }

  lifecycle {
    precondition {
      condition     = local.image_found
      error_message = "Nenhuma imagem Windows Server 2022 compatível. Defina -var 'image_ocid_override=ocid1.image....' ou ajuste policies/filtros."
    }
  }
}
