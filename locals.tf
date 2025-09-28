locals {
  # Lógica de nomes movida para cá
  ws         = lower(coalesce(try(terraform.workspace, ""), "default"))
  name_sufix = local.ws == "default" ? "" : "-${local.ws}"
  hostname   = "${var.prefix}${var.purpose}${local.name_sufix}"
  display_name = "${var.prefix}-${var.purpose}${local.name_sufix}"

  # Lógica da imagem continua em main.tf por depender de 'data' sources
}