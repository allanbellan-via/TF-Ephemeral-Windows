############################################
# main.tf — OCI Windows Ephemeral Instance
############################################

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.0"
    }
  }
}

# Provider usando Instance Principals (região pode vir por var.region ou env OCI_REGION)
provider "oci" {
  auth  = "InstancePrincipal"
  region = var.region
}

# ---------- LOOKUP DE IMAGEM ----------
# Preferência: "Server 2022 Standard"
data "oci_core_images" "win2022_standard" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Windows"
  operating_system_version = "Server 2022 Standard"
  shape                    = var.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Fallback: "Server 2022" (alguns tenancies usam rótulo genérico)
data "oci_core_images" "win2022_generic" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Windows"
  operating_system_version = "Server 2022"
  shape                    = var.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# ---------- LOCAIS ----------
locals {
  ws          = terraform.workspace
  base_name   = lower(replace("ephem-aut-${local.ws}", "[^0-9a-zA-Z-]", ""))
  hostname    = substr(local.base_name, 0, 15)
  display_name = "ephem-aut-${local.ws}"

  # Quebro em partes para evitar erro de parsing do operador ternário
  image_from_override = var.image_ocid_override
  image_from_std      = try(data.oci_core_images.win2022_standard.images[0].id, "")
  image_from_generic  = try(data.oci_core_images.win2022_generic.images[0].id, "")

  # Escolha: override > Standard > genérico
  selected_image_ocid = (
    local.image_from_override != "" ? local.image_from_override :
    (local.image_from_std != "" ? local.image_from_std : local.image_from_generic)
  )

  image_found = local.selected_image_ocid != ""
}

# ---------- RECURSO: INSTÂNCIA WINDOWS ----------
resource "oci_core_instance" "win" {
  availability_domain = var.availability_domain          # ex.: "aGcE:SA-SAOPAULO-1-AD-1"
  compartment_id      = var.compartment_ocid
  display_name        = local.display_name

  shape = var.shape
  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = var.subnet_ocid
    assign_public_ip = var.assign_public_ip              # bool!
    hostname_label   = local.hostname
    nsg_ids          = var.nsg_ids                       # opcional
  }

  source_details {
    source_type             = "image"
    source_id               = local.selected_image_ocid
    boot_volume_size_in_gbs = var.boot_volume_size_gbs   # number; remova se quiser default da imagem
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

  # Pré-condição com mensagem clara
  lifecycle {
    precondition {
      condition     = local.image_found
      error_message = "Nenhuma imagem Windows Server 2022 compatível encontrada. Defina -var 'image_ocid_override=ocid1.image....' ou ajuste policies no tenancy e/ou filtros."
    }
  }
}

# ---------- OUTPUTS ----------
output "name" {
  value = local.display_name
}

output "workspace" {
  value = local.ws
}

output "instance_id" {
  value = try(oci_core_instance.win.id, null)
}

output "private_ip" {
  value = try(oci_core_instance.win.create_vnic_details[0].private_ip, null)
}
