provider "oci" {
  region              = var.region
  # Se for usar API key via ~/.oci/config:
  config_file_profile = var.oci_config_file_profile  # ex.: "DEFAULT"
  # (não use config_file aqui)
}
