locals {
  ws          = terraform.workspace
  name_prefix = var.display_name_prefix != "" ? var.display_name_prefix : "ephem-aut"
  display_name = "${local.name_prefix}-${local.ws}"
  hostname     = replace(local.display_name, "/[^a-zA-Z0-9]/", "")
}