# Outputs for Terraform

output "ubuntu_password" {
  value = var.ubuntu_password
}

output "avi_password" {
  value = var.avi_password
}

output "jump" {
  value = vsphere_virtual_machine.jump.default_ip_address
}

output "self_service_portal" {
  value = "http://${vsphere_virtual_machine.jump.default_ip_address}/lbaas/lbaas.html"
}

output "controllers" {
  value = vsphere_virtual_machine.controller.*.default_ip_address
}

output "backend_vmw" {
  value = vsphere_virtual_machine.backend_vmw.*.default_ip_address
}

output "client" {
  value = vsphere_virtual_machine.client.*.default_ip_address
}

output "destroy" {
  value = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${basename(var.jump.private_key_path)} -t ubuntu@${vsphere_virtual_machine.jump.default_ip_address} 'git clone ${var.ansible.aviPbAbsentUrl} --branch ${var.ansible.aviPbAbsentTag} ; cd ${split("/", var.ansible.aviPbAbsentUrl)[4]} ; ansible-playbook local.yml --extra-vars @${var.controller.aviCredsJsonFile}' ; sleep 5 ; terraform destroy -auto-approve -var-file=avi.json\n"
  description = "command to destroy the infra"
}

output "destroy_avi" {
  value = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${basename(var.jump.private_key_path)} -t ubuntu@${vsphere_virtual_machine.jump.default_ip_address} 'git clone ${var.ansible.aviPbAbsentUrl} --branch ${var.ansible.aviPbAbsentTag} ; cd ${split("/", var.ansible.aviPbAbsentUrl)[4]} ; ansible-playbook local.yml --extra-vars @${var.controller.aviCredsJsonFile}'\n"
  description = "command to clear Avi only"
}
