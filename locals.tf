locals {
  # Lógica de nomes e workspace
  ws           = lower(coalesce(try(terraform.workspace, ""), "default"))
  name_sufix   = local.ws == "default" ? "" : "-${local.ws}"
  hostname     = "ephem-aut${local.name_sufix}"
  display_name = "ephem-aut${local.name_sufix}"
}