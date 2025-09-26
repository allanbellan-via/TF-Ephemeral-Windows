variable "tenancy_ocid"      { 
  type = string
  sensitive = true
}

variable "user_ocid"         { 
  type = string
  sensitive = true
}

variable "fingerprint"       {
  type = string
  sensitive = true
}

variable "private_key_path"  {
  type = string
  sensitive = true
}

variable "region"            {
  type = string
}


variable "compartment_ocid" {
  type        = string
  default     = "ocid1.compartment.oc1..aaaaaaaahfh5abt4ceouxph7t563axukcx2u2sqp4jpsx7tis25jssuf2fhq"
  description = "OCID do compartment onde criar a instância"
}

variable "subnet_ocid" {
  type        = string

  description = "OCID da subnet (VCN) para a instância"
}

variable "availability_domain" {
  type        = string
  description = "AD (ex.: 'kIdk:SA-SAOPAULO-1-AD-1')"
}

variable "shape" {
  type        = string
  default     = "VM.Standard3.Flex"
  description = "Shape da instância"
}

variable "ocpus" {
  type        = number
  default     = 1
}

variable "memory_in_gbs" {
  type        = number
  default     = 16
}

variable "boot_volume_size_gbs" {
  type        = number
  default     = 256
}

variable "assign_public_ip" {
  type        = bool
  default     = false
}

variable "display_name_prefix" {
  type        = string
  default     = "ephem-aut"
}

variable "image_ocid_override" {
  type        = string
  default     = ""
  description = "Se vazio, faz lookup da imagem mais recente do Windows 2022"
}

variable "viaadmin_username" {
  type        = string
  default     = "viaadmin"
  description = "Usuário administrativo criado no primeiro boot"
}

variable "viaadmin_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Senha do viaadmin (passar via segredo/TF_VAR no n8n)"
}

variable "test_username" {
  type        = string
  default     = "viatest"
  description = "Usuário adicional para testes (também Administrators)"
}

variable "test_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Senha do usuário de testes (passar via segredo/TF_VAR no n8n)"
}

variable "nsg_ids" {
  type        = list(string)
  default     = []
  description = "Lista de NSGs para anexar na VNIC da VM"
}
