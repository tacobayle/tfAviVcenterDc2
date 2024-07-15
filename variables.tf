#
# Environment Variables
#
variable "vsphere_username" {}
variable "vsphere_password" {}
variable "vsphere_server" {}
variable "avi_password" {}
variable "avi_old_password" {}
variable "avi_username" {}
variable "docker_registry_username" {}
variable "docker_registry_password" {}
variable "docker_registry_email" {}
variable "ubuntu_password" {}

#
# Other Variables
#

variable "avi" {}

variable "vcenter" {
  type = map
  default = {
    dc = "wdc-06-vc12"
    cluster = "wdc-06-vc12c01"
    datastore = "wdc-06-vc12c01-vsan"
    resource_pool = "wdc-06-vc12c01/Resources"
    folder = "nic-Avi-vCenter-dc2"
    networkMgmt = "vxw-dvs-34-virtualwire-3-sid-6120002-wdc-06-vc12-avi-mgmt"
    prefix = "Avi-vCenter-dc2"
  }
}

variable "controller" {
  default = {
    cpu = 16
    memory = 32768
    disk = 256
    cluster = false
    version = "22.1.6-9191"
    wait_for_guest_net_timeout = 4
    private_key_path = "/home/ubuntu/.ssh/cloudKey"
    dns =  ["10.206.8.130", "10.206.8.131"]
    ntp = ["95.81.173.155", "188.165.236.162"]
    from_email = "avicontroller@avidemo.fr"
    se_in_provider_context = "true" # true is required for LSC Cloud
    tenant_access_to_provider_se = "true"
    tenant_vrf = "false"
    aviCredsJsonFile = "~/.avicreds.json"
    public_key_path = "/home/ubuntu/.ssh/cloudKey.pub"
  }
}

variable "jump" {
  type = map
  default = {
    name = "jump"
    cpu = 2
    memory = 4096
    disk = 20
    public_key_path = "/home/ubuntu/.ssh/cloudKey.pub"
    private_key_path = "/home/ubuntu/.ssh/cloudKey"
    wait_for_guest_net_timeout = 2
    template_name = "ubuntu-focal-20.04-cloudimg-template"
    avisdkVersion = "22.1.6"
    username = "ubuntu"
  }
}

variable "ansible" {
  default = {
    aviPbAbsentUrl = "https://github.com/tacobayle/ansibleAviClear"
    aviPbAbsentTag = "v1.04"
    aviConfigureUrl = "https://github.com/tacobayle/ansibleAviConfig"
    aviConfigureTag = "v2.12"
    version = {
      ansible = "5.7.1"
      ansible-core = "2.12.5"
    }
  }
}

variable "backend_vmw" {
  default = {
    cpu = 2
    memory = 4096
    disk = 20
    username = "ubuntu"
    network = "vxw-dvs-34-virtualwire-116-sid-6120115-wdc-06-vc12-avi-dev112"
    wait_for_guest_net_timeout = 2
    template_name = "ubuntu-bionic-18.04-cloudimg-template"
    ipsData = ["100.64.129.211", "100.64.129.212"]
    netplanFile = "/etc/netplan/50-cloud-init.yaml"
    maskData = "/24"
    url_demovip_server = "https://github.com/tacobayle/demovip_server"
  }
}

variable "client" {
  default = {
    cpu = 2
    count = 3
    memory = 4096
    disk = 20
    username = "ubuntu"
    network = "vxw-dvs-34-virtualwire-120-sid-6120119-wdc-06-vc12-avi-dev116"
    wait_for_guest_net_timeout = 2
    template_name = "ubuntu-bionic-18.04-cloudimg-template"
    netplanFile = "/etc/netplan/50-cloud-init.yaml"
    ipsData = ["100.64.133.17", "100.64.133.18", "100.64.133.19"]
    maskData = "/24"
  }
}