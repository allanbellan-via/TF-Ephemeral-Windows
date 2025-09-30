locals {
  # Lógica de nomes e workspace
  ws           = lower(coalesce(try(terraform.workspace, ""), "default"))
  name_sufix   = local.ws == "default" ? "" : "-${local.ws}"
  hostname     = "APPGRU-AUT-${local.name_sufix}"
  display_name = "APPGRU-AUT-${local.name_sufix}"
}