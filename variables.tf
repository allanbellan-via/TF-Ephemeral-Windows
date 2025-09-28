# --------------- DADOS GERAIS ---------------
variable "region" {
  type        = string
  description = "Região da OCI (ex.: sa-saopaulo-1)."
}

variable "compartment_ocid" {
  type        = string
  description = "OCID do Compartment onde a VM será criada."
}

variable "availability_domain" {
  type        = string
  description = "Availability Domain (ex.: kIdk:SA-SAOPAULO-1-AD-1)."
}

# --------------- CONFIGURAÇÃO DA VM ---------------
variable "shape" {
  type        = string
  description = "Shape da instância."
  # ALTERAÇÃO PARA TESTE: Trocado o padrão para um shape fixo
  default     = "VM.Standard2.1"
}

# ALTERAÇÃO PARA TESTE: Comentado pois não é usado por shapes fixos
# variable "ocpus" {
#   type        = number
#   description = "Número de OCPUs para a VM (somente para shapes Flex)."
#   default     = 1
# }

# ALTERAÇÃO PARA TESTE: Comentado pois não é usado por shapes fixos
# variable "memory_in_gbs" {
#   type        = number
#   description = "Memória em GBs para a VM (somente para shapes Flex)."
#   default     = 16
# }

variable "boot_volume_size_gbs" {
  type        = number
  description = "Tamanho do boot volume em GBs. Deixe como null para usar o padrão da imagem."
  default     = 256
  nullable    = true
}

# --------------- CONFIGURAÇÃO DE REDE ---------------
# (O restante do arquivo continua igual)

variable "subnet_ocid" {
  type        = string
  description = "OCID da Subnet onde a VM será conectada."
}

variable "assign_public_ip" {
  type        = bool
  description = "Define se a VM deve receber um IP público."
  default     = false
}

variable "nsg_ids" {
  type        = list(string)
  description = "Lista de OCIDs de Network Security Groups a serem associados à vNIC."
  default     = []
}

# --------------- IMAGEM E USERDATA ---------------
variable "image_ocid_override" {
  type        = string
  description = "OCID de uma imagem específica para usar, ignorando a busca automática."
  default     = ""
}

variable "viaadmin_username" {
  type    = string
  default = "viaadmin"
}

variable "viaadmin_password" {
  type      = string
  sensitive = true
}

variable "test_username" {
  type    = string
  default = "testuser"
}

variable "test_password" {
  type      = string
  sensitive = true
}

# --------------- TAGS E NOMES ---------------
variable "prefix" {
  type    = string
  default = "ephem"
}

variable "purpose" {
  type    = string
  default = "aut"
}

variable "owner_tag" {
  type        = string
  description = "Nome do responsável pela VM (para a tag 'owner')."
  default     = "allan"
}