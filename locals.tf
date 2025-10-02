locals {
  # Lógica de nomes e workspace
  ws           = lower(coalesce(try(terraform.workspace, ""), "default"))
  name_sufix   = local.ws == "default" ? "" : "-${local.ws}"
  hostname     = "'appgru-aut-'${local.name_sufix}"
  display_name = "'appgru-aut-'${local.name_sufix}"
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

# ws já deve existir em seus locals (ex.: ws = terraform.workspace)
# Aqui consideramos "em branco" quando length(trim(local.ws)) == 0
locals {
  # workspace atual
  ws = terraform.workspace

  # base sem aspas estranhas
  base_stub = "appgru-aut"

  # se ws vier vazio (ou só espaços), não adiciona '-ws'
  base_name_raw = length(trimspace(local.ws)) > 0 ? "${local.base_stub}-${local.ws}" : local.base_stub

  # --- Saneamento pra DNS (sempre lowercase) ---
  _hn1 = lower(replace(local.base_name_raw, " ", "-"))
  _hn2 = regexreplace(local._hn1, "[^a-z0-9-]", "")
  _hn3 = regexreplace(local._hn2, "-+", "-")
  # remove hifens no início e no fim
  _hn4     = regexreplace(regexreplace(local._hn3, "^-+", ""), "-+$", "")
  _hn_base = length(local._hn4) == 0 ? "vm" : local._hn4

  # coloca sufixo numérico SÓ quando o ws estiver em branco
  add_numeric_suffix = length(trimspace(local.ws)) == 0

  # se tiver sufixo, reservamos 12 + 3 = 15 chars
  _hn_trunc_for_suffix = substr(local._hn_base, 0, 12)
  _hn_trunc_no_suffix  = substr(local._hn_base, 0, 15)

  hostname_sanitized = local.add_numeric_suffix ? format("%s%03d", local._hn_trunc_for_suffix, random_integer.dns.result) : local._hn_trunc_no_suffix

  # display_name pode manter o ws mesmo vazio (só informativo)
  display_name = "ephem-aut-${local.ws}"
}

