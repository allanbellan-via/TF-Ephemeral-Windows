# --- versions.tf ---

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      # ALTERAÇÃO: Fixando em uma versão estável anterior
      version = "5.30.0" 
    }
  }
}