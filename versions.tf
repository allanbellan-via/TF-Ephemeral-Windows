# versions.tf

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      # ATUALIZAÇÃO: Exigindo a versão principal mais recente para garantir compatibilidade
      version = "~> 6.0"
    }
  }
}