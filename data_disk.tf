resource "azurerm_managed_disk" "data_disk" {
  for_each                   = var.data_disks
  name                       = lookup(var.name_overrides.data_disks, each.key, "disk-${var.virtual_machine_config.hostname}-${each.key}")
  location                   = var.virtual_machine_config.location
  resource_group_name        = var.resource_group_name
  tier                       = each.value["storage_account_type"] == "Premium_LRS" || each.value["storage_account_type"] == "Premium_ZRS" ? each.value["tier"] : null
  zone                       = each.value["zone"]
  storage_account_type       = each.value["storage_account_type"]
  create_option              = each.value["create_option"]
  disk_size_gb               = each.value["disk_size_gb"]
  on_demand_bursting_enabled = each.value["on_demand_bursting_enabled"]
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      tags
    ]
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