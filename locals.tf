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
  # Workspace atual (defina apenas uma vez)
  ws = terraform.workspace

  # ---- Nome base da VM (ajuste se quiser) ----
  base_stub = "appgru-aut"

  # Concatena o workspace se não for vazio
  base_name_raw = length(trimspace(local.ws)) > 0 ? "${local.base_stub}-${local.ws}" : local.base_stub

  # ---- Saneamento p/ DNS label (lowercase, sem chars inválidos) ----
  _hn1 = lower(replace(local.base_name_raw, " ", "-"))
  _hn2 = regexreplace(local._hn1, "[^a-z0-9-]", "")
  _hn3 = regexreplace(local._hn2, "-+", "-")
  # remove hífens no início e fim
  _hn4     = regexreplace(regexreplace(local._hn3, "^-+", ""), "-+$", "")
  _hn_base = length(local._hn4) == 0 ? "vm" : local._hn4

  # Sufixo numérico só quando ws estiver em branco
  add_numeric_suffix = length(trimspace(local.ws)) == 0

  # Se tiver sufixo, reservamos 12 + 3 = 15 chars totais
  _hn_trunc_for_suffix = substr(local._hn_base, 0, 12)
  _hn_trunc_no_suffix  = substr(local._hn_base, 0, 15)

  # Hostname final (para create_vnic_details.hostname_label)
  hostname_sanitized = local.add_numeric_suffix ? format("%s%03d", local._hn_trunc_for_suffix, random_integer.dns.result) : local._hn_trunc_no_suffix

  # Display name da instância (informativo; pode conter hífen no fim sem problema)
  display_name = "ephem-aut-${local.ws}"
}