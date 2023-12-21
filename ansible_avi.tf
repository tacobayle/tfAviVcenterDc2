resource "null_resource" "ansible_hosts_avi_header_1" {
  provisioner "local-exec" {
    command = "echo '---' | tee hosts_avi; echo 'all:' | tee -a hosts_avi ; echo '  children:' | tee -a hosts_avi; echo '    controller:' | tee -a hosts_avi; echo '      hosts:' | tee -a hosts_avi"
  }
}

resource "null_resource" "ansible_hosts_avi_controllers" {
  depends_on = [null_resource.ansible_hosts_avi_header_1]
  count            = (var.controller.cluster == true ? 3 : 1)
  provisioner "local-exec" {
    command = "echo '        ${vsphere_virtual_machine.controller[count.index].default_ip_address}:' | tee -a hosts_avi "
  }
}

resource "null_resource" "ansible_hosts_avi_header_3" {
  depends_on = [null_resource.ansible_hosts_avi_controllers]
  provisioner "local-exec" {
    command = "echo '  vars:' | tee -a hosts_avi ; echo '    ansible_user: ubuntu' | tee -a hosts_avi"
  }
}

data "template_file" "avi_vcenter_yaml_values" {
  template = file("templates/avi_vcenter_yaml_values.yml.template")
  vars = {
    controller_ips = jsonencode(vsphere_virtual_machine.controller[*].default_ip_address)
    controller_cluster = var.controller.cluster
    controller_ntp = jsonencode(var.controller.ntp)
    controller_dns = jsonencode(var.controller.dns)
    avi_password = var.avi_password
    aviCredsJsonFile = var.controller.aviCredsJsonFile
    avi_old_password = var.avi_old_password
    avi_version = split("-", var.controller.version)[0]
    avi_username = var.avi_username
    vsphere_username = var.vsphere_username
    vsphere_password = var.vsphere_password
    vsphere_server = var.vsphere_server
    tenants = jsonencode(var.avi.config.tenants)
    users = jsonencode(var.avi.config.users)
    domain = jsonencode(var.avi.config.domain)
    ipam = jsonencode(var.avi.config.cloud.ipam)
    cloud_name = jsonencode(var.avi.config.cloud.name)
    dc = var.vcenter.dc
    content_library_id = vsphere_content_library.library[0].id
    content_library_name = "${var.vcenter.prefix}-Avi-Se-cl"
    dhcp_enabled = jsonencode(var.avi.config.cloud.dhcp_enabled)
    networks = jsonencode(var.avi.config.cloud.networks)
    contexts = "[]"
    additional_subnets = "[]"
    service_engine_groups = jsonencode(var.avi.config.cloud.serviceEngineGroup)
    pools = jsonencode(var.avi.config.cloud.pools)
    virtual_services = jsonencode(var.avi.config.cloud.virtual_services)
    httppolicyset = jsonencode(var.avi.config.cloud.httppolicyset)
    applicationprofile = jsonencode(var.avi.config.cloud.applicationprofile)
  }
}

resource "null_resource" "ansible_avi" {
  depends_on = [null_resource.wait_https_controllers, vsphere_virtual_machine.jump, null_resource.ansible_hosts_avi_header_3, data.template_file.avi_vcenter_yaml_values]
  connection {
    host = vsphere_virtual_machine.jump.default_ip_address
    type = "ssh"
    agent = false
    user = var.jump.username
    private_key = file(var.jump.private_key_path)
  }

  provisioner "file" {
    source = "hosts_avi"
    destination = "hosts_avi"
  }

  provisioner "file" {
    content = data.template_file.avi_vcenter_yaml_values.rendered
    destination = "avi_vcenter_yaml_values.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "git clone ${var.ansible.aviConfigureUrl} --branch ${var.ansible.aviConfigureTag} ; cd ${split("/", var.ansible.aviConfigureUrl)[4]} ; ansible-playbook -i ../hosts_avi vcenter.yml --extra-vars @../avi_vcenter_yaml_values.yml"
    ]
  }
}