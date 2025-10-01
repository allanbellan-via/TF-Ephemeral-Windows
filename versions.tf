# versions.tf

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      # ATUALIZAÇÃO: Exigindo a versão principal mais recente para garantir compatibilidade
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

resource "random_integer" "dns" {
  count = length(trim(local.ws)) == 0 ? 1 : 0
  min   = 100
  max   = 999
}