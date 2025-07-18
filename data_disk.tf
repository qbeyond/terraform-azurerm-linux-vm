resource "azurerm_managed_disk" "data_disk" {
  for_each                   = var.data_disks
  name                       = lookup(var.name_overrides.data_disks, each.key, "disk-${var.virtual_machine_config.hostname}-${each.key}")
  location                   = var.virtual_machine_config.location
  resource_group_name        = var.resource_group_name
  storage_account_type       = each.value["storage_account_type"]
  create_option              = each.value["create_option"]
  source_resource_id         = each.value["source_resource_id"]
  disk_size_gb               = each.value["disk_size_gb"]
  on_demand_bursting_enabled = each.value["on_demand_bursting_enabled"]
  zone                       = var.virtual_machine_config.zone
  disk_iops_read_write       = each.value["disk_iops_read_write"]
  disk_mbps_read_write       = each.value["disk_mbps_read_write"]
  disk_iops_read_only        = each.value["disk_iops_read_only"]
  disk_mbps_read_only        = each.value["disk_mbps_read_only"]
  max_shares                 = each.value["max_shares"] 

  tags                 = var.tags
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disk" {
  for_each                  = var.data_disks
  managed_disk_id           = azurerm_managed_disk.data_disk[each.key].id
  virtual_machine_id        = azurerm_linux_virtual_machine.this.id
  lun                       = each.value["lun"]
  caching                   = each.value["caching"]
  write_accelerator_enabled = each.value["write_accelerator_enabled"]

  lifecycle {
    prevent_destroy = true
  }
}