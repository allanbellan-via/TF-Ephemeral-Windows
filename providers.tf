terraform {
  required_version = ">= 1.6.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }
}

provider "oci" {
  auth  = "InstancePrincipal"
  # escolha 1: declare a região aqui
  region = var.region
  # OU escolha 2: use a env var OCI_REGION (ver Passo 4)
}
