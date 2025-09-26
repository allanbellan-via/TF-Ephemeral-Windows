# providers.tf — usa variáveis (definidas em provider_var.tf privado)
variable "tenancy_ocid"      { type = string }
variable "user_ocid"         { type = string }
variable "fingerprint"       { type = string }
variable "region"            { type = string }
variable "private_key_path"  { type = string }

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  region           = var.region
  private_key_path = var.private_key_path
}