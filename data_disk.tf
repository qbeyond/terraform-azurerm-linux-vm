locals {
  disk_prefix = var.vm_name_as_disk_prefix ? (length(var.disk_prefix) > 0 ? "${local.virtual_machine.name}-${var.disk_prefix}" : local.virtual_machine.name) : (length(var.disk_prefix) > 0 ? "${var.disk_prefix}" : "")
}
resource "azurerm_managed_disk" "data_disk" {
  for_each                   = var.data_disks
  name                       = length(local.disk_prefix) > 0 ? "${local.disk_prefix}-${each.key}" : each.key
  location                   = var.virtual_machine_config.location
  resource_group_name        = var.resource_group_name
  tier                       = each.value["storage_account_type"] == "Premium_LRS" || each.value["storage_account_type"] == "Premium_ZRS" ? each.value["tier"] : ""
  storage_account_type       = each.value["storage_account_type"]
  create_option              = each.value["create_option"]
  disk_size_gb               = each.value["disk_size_gb"]
  zone                       = length(var.virtual_machine_config.zone) > 0 ? var.virtual_machine_config.zone : null
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