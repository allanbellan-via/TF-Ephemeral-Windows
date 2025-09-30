# --------------- Perfil do OCI-CLI ---------------

variable "oci_config_file_profile" {
  type    = string
  default = "DEFAULT"
}

# --------------- AD AUTO ---------------
variable "ad_number" {
  description = "AD desejado quando usando auto-AD: 1, 2 ou 3 (1 = AD-1)."
  type        = number
  default     = 1
}

# --------------- METADATA ---------------
# controla se vamos injetar user_data (pode desligar via N8N)
variable "inject_user_data" {
  type        = bool
  default     = true
  description = "Se true, envia metadata.user_data com o template."
}

# caminho (relativo ou absoluto) do arquivo de template (ps1)
# por padrão continua usando o template do módulo atual
variable "userdata_template_path" {
  type        = string
  default     = "" # deixe vazio; o fallback será resolvido no main.tf
  description = "Caminho do template de user_data (absoluto ou relativo ao diretório onde o Terraform é executado)."
}


# --------------- DADOS GERAIS ---------------
variable "tenancy_ocid" {
  type        = string
  description = "OCID da Tenancy (compartimento raiz) OBRIGATÓRIO para buscar as imagens de plataforma."
}

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
  description = "Shape da instância (ex: VM.Standard.E5.Flex)."
  default     = "VM.Standard.E5.Flex"
}

variable "ocpus" {
  type        = number
  description = "Número de OCPUs para a VM (somente para shapes Flex)."
  default     = 1
}

variable "memory_in_gbs" {
  type        = number
  description = "Memória em GBs para a VM (somente para shapes Flex)."
  default     = 16
}

# --------------- IMAGEM ---------------
variable "image_ocid_override" {
  type        = string
  description = "OPCIONAL: OCID de uma imagem específica para usar, ignorando a busca automática."
  default     = ""
}

# --------------- REDE E DISCO ---------------
variable "subnet_ocid" {
  type        = string
  description = "OCID da Subnet onde a VM será conectada."
}

variable "assign_public_ip" {
  type        = bool
  description = "Define se a VM deve receber um IP público."
  default     = false
}

# CORREÇÃO: Bloco da variável que está faltando
variable "boot_volume_size_in_gbs" {
  type        = number
  description = "Tamanho do boot volume em GBs. Deixe como null para usar o padrão da imagem."
  default     = 256
  nullable    = true
}

# --------------- CREDENCIAIS (USERDATA) ---------------
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
variable "owner_tag" {
  type        = string
  description = "Nome do responsável pela VM (para a tag 'owner')."
  default     = "allan"
}