output "instance_id" {
  description = "OCID da instância criada."
  value       = oci_core_instance.win.id
}

output "display_name" {
  description = "Nome de exibição da instância."
  value       = oci_core_instance.win.display_name
}

output "private_ip" {
  description = "IP privado da instância."
  value       = oci_core_instance.win.private_ip
}

output "public_ip" {
  description = "IP público da instância (se houver)."
  value       = oci_core_instance.win.public_ip
}

output "workspace" {
  description = "Workspace utilizado para a criação."
  value       = local.ws
}