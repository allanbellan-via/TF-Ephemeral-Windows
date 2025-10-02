# Lista de ADs do tenancy (Identity é global, mas o provider ainda precisa estar configurado)
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

locals {
  # Tolerante: se o data source vier null, caímos para lista vazia
  ads       = try(data.oci_identity_availability_domains.ads.availability_domains, [])
  ad_index  = var.ad_number - 1

  # Se o usuário informar o AD explicitamente, usamos ele.
  # Caso contrário, tentamos pegar pelo número (1..N) se existir.
  ad_by_number = (
    local.ad_index >= 0 && length(local.ads) > local.ad_index
  ) ? local.ads[local.ad_index].name : ""

  ad_final = var.availability_domain != "" ? var.availability_domain : local.ad_by_number
}
