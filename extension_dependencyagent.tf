resource "azurerm_virtual_machine_extension" "DependencyAgentLinux" {
  name                       = "DependencyAgentLinux"
  virtual_machine_id         =  azurerm_linux_virtual_machine.this.id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentLinux"
  type_handler_version       = "9.5"
  auto_upgrade_minor_version = true
}
