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

# Gera número de 3 dígitos apenas quando name_suffix está vazio
resource "random_integer" "dns" {
  count = trimspace(var.name_suffix) == "" ? 1 : 0
  min   = 100
  max   = 999
}
