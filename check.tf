data "azurerm_client_config" "current" {}

check "vm_hw_profile_restart_risk" {
  data "azapi_resource" "vm_current" {
    type      = "Microsoft.Compute/virtualMachines@2024-07-01" # API-Version prüfen
    name      = local.virtual_machine.name
    parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.name_overrides.resource_group_name_vm != null ? var.name_overrides.resource_group_name_vm : var.resource_group_name}"
    ignore_not_found = true

    response_export_values = [
      "properties.additionalCapabilities",
    ]
  }

  assert {
    condition = (
      !try(data.azapi_resource.vm_current.exists, true)
      || (try(data.azapi_resource.vm_current.output.properties.additionalCapabilities, null) != null)
      || (var.virtual_machine_config.additional_capabilities == null)
    )

    error_message = <<-EOT

      ################################################################
      #  !!!  WARNING: VM RESTART POSSIBLE  !!!
      ################################################################
      # additional_capabilities is being ADDED to an existing VM.
      # This restarted the VM in our tests (azurerm 4.0.0).
      # Only apply in a maintenance window!
      ################################################################
    EOT
  }

  # Fall 2: Block fehlt in der Config, existiert aber in Azure
  assert {
    condition = (
      !try(data.azapi_resource.vm_current.exists, true)
      || (try(data.azapi_resource.vm_current.output.properties.additionalCapabilities, null) == null)
      || (var.virtual_machine_config.additional_capabilities != null)
    )

    error_message = <<-EOT

      ################################################################
      #  NOTE: additional_capabilities missing in configuration
      ################################################################
      # additional_capabilities is set on the VM in Azure but is not
      # defined in the configuration. Please ADD the block to the
      # configuration with the values currently set in Azure to avoid a
      # permanent diff in the plan.
      #
      # The behavior of removing this block is not fully verified.
      # The outcome of a removal is therefore uncertain and a restart
      # cannot be ruled out. Do not remove the block on production VMs
      # without a maintenance window.
      ################################################################
        EOT
  }
}