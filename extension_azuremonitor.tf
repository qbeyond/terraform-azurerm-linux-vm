resource "azurerm_virtual_machine_extension" "microsoftmonitoringagent" {
  count                      = var.log_analytics_agent != null ? 1 : 0
  name                       = "MicrosoftMonitoringAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.this.id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "MicrosoftMonitoringAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
       "workspaceId" : "${var.log_analytics_agent.workspace_id}"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
       "workspaceKey" : "${var.log_analytics_agent.primary_shared_key}"
    }
PROTECTED_SETTINGS

}
