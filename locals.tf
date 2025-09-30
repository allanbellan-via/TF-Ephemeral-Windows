locals {
  # Lógica de nomes e workspace
  ws           = lower(coalesce(try(terraform.workspace, ""), "default"))
  name_sufix   = local.ws == "default" ? "" : "-${local.ws}"
  hostname     = "appgruaut${local.name_sufix}"
  display_name = "appgruaut${local.name_sufix}"
}

locals {
  userdata_template_effective = (
    var.userdata_template_path != "" ?
    var.userdata_template_path :
    "${path.module}/userdata_win.ps1"
  )
  # Caminho absoluto para validação
  userdata_template_abs = abspath(local.userdata_template_effective)
}