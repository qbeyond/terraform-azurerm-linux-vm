resource "azurerm_virtual_machine_extension" "microsoftmonitoringagent" {
  count                      = var.log_analytics_agent != null ? 1 : 0
  name                       = "MicrosoftMonitoringAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.this.id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "OmsAgentForLinux"
  type_handler_version       = "1.17"
  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = true
  settings                   = jsonencode({ "workspaceId" = var.log_analytics_agent.workspace_id })
  protected_settings         = jsonencode({ "workspaceKey" = var.log_analytics_agent.primary_shared_key })
}