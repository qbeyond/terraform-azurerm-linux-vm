output "virtual_machine" {
  value = azurerm_linux_virtual_machine.this
}

/* output "nic_id" {
  value       = azurerm_network_interface.interface.id
  description = "VM nic id."
} */