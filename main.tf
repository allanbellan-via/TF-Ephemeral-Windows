# Lookup automático da imagem Windows Server 2022 Standard
data "oci_core_images" "win2022" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Windows"
  operating_system_version = "Server 2022"
  shape                    = var.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

locals {
  selected_image_ocid = var.image_ocid_override != "" ? var.image_ocid_override : (
    length(data.oci_core_images.win2022.images) > 0 ? data.oci_core_images.win2022.images[0].id : ""
  )
}

resource "oci_core_instance" "win" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = local.display_name

  shape = var.shape
  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = var.subnet_ocid
    assign_public_ip = var.assign_public_ip
    hostname_label   = local.hostname
    nsg_ids          = var.nsg_ids   # <- opcional, usa seus NSGs existentes
  }

  source_details {
    source_type             = "image"
    source_id               = local.selected_image_ocid   # <- CORRETO no provider OCI
    boot_volume_size_in_gbs = var.boot_volume_size_gbs
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
    workspace = local.ws
  }

timeouts {
  create = "10m"
  delete = "10m"
}

  # Pré-condição para erro mais claro se imagem não for encontrada
  lifecycle {
    precondition {
      condition     = local.selected_image_ocid != ""
      error_message = "Nenhuma imagem Windows Server 2022 compatível encontrada. Defina image_ocid_override ou revise filtros de data."
    }
  }
}