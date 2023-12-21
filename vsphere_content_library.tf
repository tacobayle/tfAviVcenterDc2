resource "vsphere_content_library" "library" {
  count           = 1
  name            = "${var.vcenter.prefix}-Avi-Se-cl"
  storage_backing = [data.vsphere_datastore.datastore.id]
}
