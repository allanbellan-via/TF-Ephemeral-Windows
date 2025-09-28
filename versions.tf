# BOA PRÁTICA: Fixa a versão do provedor para evitar que novas versões quebrem o código.
terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.30" # Aceitará qualquer versão 5.30.x, mas não a 5.31.0
    }
  }
}