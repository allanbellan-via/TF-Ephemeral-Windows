locals {
  userdata_template_effective = (
    var.userdata_template_path != "" ?
    var.userdata_template_path :
    "${path.module}/userdata_win.ps1"
  )
  # Caminho absoluto para validação
  userdata_template_abs = abspath(local.userdata_template_effective)
}

locals {
  # Workspace atual
  ws = terraform.workspace

  # ----- Nome base -----
  base_stub     = "appgru-aut"
  base_name_raw = length(trimspace(local.ws)) > 0 ? "${local.base_stub}-${local.ws}" : local.base_stub

  # ----- Normaliza: espaços -> '-', minúsculas -----
  _hn1 = lower(replace(local.base_name_raw, " ", "-"))

  # ----- Mantém apenas [a-z0-9-] sem usar regexreplace -----
  # Pega cada caractere válido com regexall e junta tudo
  _allowed_list = regexall("[a-z0-9-]", local._hn1)
  _hn2          = join("", local._allowed_list)

  # ----- (Opcional) comprimir múltiplos '-' sem regexreplace -----
  # Como não temos regexreplace, vamos deixar hífens duplos se aparecerem; a OCI permite '-' no meio.
  # (Se fizer questão de comprimir, dá pra fazer com uma pequena expressão dinâmica de replace em camadas)
  _hn3 = local._hn2

  # ----- Remove '-' no início e no fim (usando trim) -----
  _hn4     = trim(local._hn3, "-")
  _hn_base = length(local._hn4) == 0 ? "vm" : local._hn4

  # Sufixo numérico só quando ws estiver em branco
  add_numeric_suffix = length(trimspace(local.ws)) == 0

  # Se tiver sufixo, reservamos 12 + 3 = 15 chars
  _hn_trunc_for_suffix = substr(local._hn_base, 0, 12)
  _hn_trunc_no_suffix  = substr(local._hn_base, 0, 15)

  # Hostname final (para create_vnic_details.hostname_label)
  hostname_sanitized = local.add_numeric_suffix ? format("%s%03d", local._hn_trunc_for_suffix, random_integer.dns.result) : local._hn_trunc_no_suffix

  # Display name (informativo)
  display_name = "ephem-aut-${local.ws}"
}