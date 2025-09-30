# Lista os Availability Domains do tenancy
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

locals {
  ads           = try(data.oci_identity_availability_domains.ads.availability_domains, [])
  ad_index      = var.ad_number - 1
  ad_by_number  = (length(local.ads) > local.ad_index && local.ad_index >= 0) ? local.ads[local.ad_index].name : ""
  ad_final      = var.availability_domain != "" ? var.availability_domain : local.ad_by_number
}