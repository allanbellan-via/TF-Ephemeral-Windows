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
  add_numeric_suffix = length(trim(local.ws)) == 0

  # --- origem do hostname (ajuste se preferir outra fonte)
  _hn_src = local.hostname

  # 1) normaliza
  _hn1 = uper(replace(local._hn_src, " ", "-"))

  # 2) remove tudo que não for [a-z0-9-]
  _hn2 = regexreplace(local._hn1, "[^a-z0-9-]", "")

  # 3) comprime múltiplos hífens
  _hn3 = regexreplace(local._hn2, "-+", "-")

  # 4) remove hífens no início e no fim
  #_hn4 = regexreplace(regexreplace(local._hn3, "^-+", ""), "-+$", "")

  # 5) fallback se esvaziou
  _hn_base = length(local._hn3) == 0 ? "vm" : local._hn3
  # _hn_base = length(local._hn4) == 0 ? "vm" : local._hn4

  # 6) truncagem variável: se vai ter sufixo (3 dígitos), reserva 12 chars; senão, 15
  _hn_trunc_for_suffix = substr(local._hn_base, 0, 12)
  _hn_trunc_no_suffix  = substr(local._hn_base, 0, 15)

  # 7) hostname final: só põe número no final se ws estiver em branco
  hostname_sanitized = local.add_numeric_suffix ? format("%s%03d", local._hn_trunc_for_suffix, random_integer.dns[0].result) : local._hn_trunc_no_suffix
}
