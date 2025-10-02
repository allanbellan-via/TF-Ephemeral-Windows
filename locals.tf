locals {
  userdata_template_effective = (
    var.userdata_template_path != "" ?
    var.userdata_template_path :
    "${path.module}/userdata_win.ps1"
  )
  # Caminho absoluto para validação
  userdata_template_abs = abspath(local.userdata_template_effective)
}


############################################
# Nomes a partir de var.ws (ex.: "AUTST-01")
# Display Name: MAIÚSCULO  -> APPGRU-AUTST-01
# Hostname    : minúsculo  -> appgru-autst-01 (DNS-safe)
############################################
locals {
  # Prefixos fixos
  prefix_display = "APPGRU"  # para Display Name
  prefix_dns     = "appgru"  # para hostname

  # Normaliza entrada
  ws_trim = trimspace(var.ws)
  parts   = split("-", local.ws_trim)

  # Extrai parte de texto (primeiro segmento), só letras (fallback "WS" se vazio)
  _text_raw = length(local.parts) >= 1 ? local.parts[0] : ""
  _text_letters = join("", regexall("[A-Za-z]", local._text_raw))
  suffix_text_up = upper(local._text_letters != "" ? local._text_letters : "WS")

  # Extrai parte numérica (último segmento se for 1–2 dígitos), default 01
  _num_candidate = length(local.parts) >= 2 ? local.parts[length(local.parts)-1] : ""
  _num_is_digit  = can(regex("^[0-9]{1,2}$", local._num_candidate))
  suffix_num_fmt = local._num_is_digit ? format("%02d", tonumber(local._num_candidate)) : "01"

  # ---------- DISPLAY NAME (sempre MAIÚSCULO) ----------
  display_name = "${local.prefix_display}-${local.suffix_text_up}-${local.suffix_num_fmt}"

  # ---------- HOSTNAME (sempre minúsculo, DNS-safe) ----------
  _hn_base_raw = lower("${local.prefix_dns}-${local.suffix_text_up}-${local.suffix_num_fmt}")  # ex.: appgru-autst-01
  # mantém só [a-z0-9-]
  _hn_keep = join("", regexall("[a-z0-9-]", local._hn_base_raw))

  # colapsa hifens múltiplos e remove hifens nas pontas
  # (split gera strings vazias onde há hífens duplos; compact remove vazias; join recolhe com 1 hífen)
  _hn_collapse = join("-", compact(split("-", local._hn_keep)))

  _hn_trimmed  = trim(local._hn_collapse, "-")
  _hn_start    = length(regexall("^[a-z]", local._hn_trimmed)) > 0 ? local._hn_trimmed : "h${local._hn_trimmed}"
  hostname_label = substr(local._hn_start, 0, 63)
}
