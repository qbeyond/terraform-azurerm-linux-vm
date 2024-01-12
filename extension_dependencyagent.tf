resource "azurerm_virtual_machine_extension" "DependencyAgentLinux" {
  count                      = var.log_analytics_agent != null ? 1 : 0
  name                       = "DependencyAgentLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.this.id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentLinux"
  type_handler_version       = "9.5"
  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = true
  settings                   = jsonencode({ "enableAMA" = true })
}