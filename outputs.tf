output "virtual_machine" {
  value = length(azurerm_windows_virtual_machine.this) > 0 ? azurerm_windows_virtual_machine.this[0] : azurerm_windows_virtual_machine.imported[0]
}

output "data_disks" {
  value = azurerm_managed_disk.data_disk
}

output "network_interface" {
  value = azurerm_network_interface.this
}