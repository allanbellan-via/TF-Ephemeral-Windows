output "workspace"   { value = terraform.workspace }
output "instance_id" { value = oci_core_instance.win.id }
output "private_ip"  { value = oci_core_instance.win.private_ip }
output "name"        { value = oci_core_instance.win.display_name }