resource "azurerm_public_ip" "this" {
  count               = var.public_ip_config != null ? 1 : 0
  name                = local.public_ip.name
  resource_group_name = var.resource_group_name
  location            = var.virtual_machine_config.location
  allocation_method   = var.public_ip_config.allocation_method
  zones               = [var.virtual_machine_config.zone]
  sku                 = var.public_ip_config.sku

  tags = var.tags
}

resource "azurerm_network_interface" "this" {
  name                           = local.nic.name
  location                       = var.virtual_machine_config.location
  resource_group_name            = var.resource_group_name
  dns_servers                    = var.nic_config.dns_servers
  accelerated_networking_enabled = var.nic_config.enable_accelerated_networking
  tags                           = var.tags

  # first IP configuration
  ip_configuration {
    name                          = local.nic.ip_config_name
    subnet_id                     = var.subnet.id
    private_ip_address_allocation = var.nic_config.private_ip == null ? "Dynamic" : "Static"
    private_ip_address            = var.nic_config.private_ip
    primary                       = true
    public_ip_address_id          = var.public_ip_config != null ? azurerm_public_ip.this[0].id : null
  }

  # additional IP configurations
  dynamic "ip_configuration" {
    for_each = var.additional_ip_configurations
    content {
      name                          = ip_configuration.key
      subnet_id                     = var.subnet.id
      private_ip_address_allocation = ip_configuration.value["private_ip"] == null ? "Dynamic" : "Static"
      private_ip_address            = ip_configuration.value["private_ip"]
      primary                       = false
      public_ip_address_id          = ip_configuration.value["public_ip_address_id"] != null ? ip_configuration.value["public_ip_address_id"] : null
    }
  }
}

resource "azurerm_network_interface_security_group_association" "this" {
  count                     = var.nic_config.nsg != null ? 1 : 0
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = var.nic_config.nsg.id
}

check "no_nsg_on_nic" {
  assert {
    condition     = length(azurerm_network_interface_security_group_association.this) == 0
    error_message = "Direct NSG associations to the NIC should be avoided. Assign to subnet instead."
  }
}

resource "azurerm_marketplace_agreement" "default" {
  count = var.virtual_machine_config.enable_plan == true ? 1 : 0

  publisher = var.virtual_machine_config.os_publisher
  offer     = var.virtual_machine_config.os_offer
  plan      = var.virtual_machine_config.os_sku
}

resource "azurerm_linux_virtual_machine" "this" {
  name                                                   = local.virtual_machine.name
  computer_name                                          = var.virtual_machine_config.hostname
  location                                               = var.virtual_machine_config.location
  resource_group_name                                    = var.resource_group_name
  size                                                   = var.virtual_machine_config.size
  admin_username                                         = var.admin_username
  admin_password                                         = var.admin_credential.admin_password
  disable_password_authentication                        = var.admin_credential.admin_password == null
  patch_mode                                             = var.update_settings.patch_mode
  bypass_platform_safety_checks_on_user_schedule_enabled = var.update_settings.patch_mode == "ImageDefault" ? false : var.update_settings.bypass_platform_safety_checks_on_user_schedule_enabled
  patch_assessment_mode                                  = var.update_settings.patch_assessment_mode
  reboot_setting                                         = var.update_settings.patch_mode == "AutomaticByPlatform" ? var.update_settings.reboot_setting : null

  dynamic "admin_ssh_key" {
    for_each = var.admin_credential.public_key != null ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.admin_credential.public_key
    }
  }

  os_disk {
    name                      = local.os_disk_name
    caching                   = var.virtual_machine_config.os_disk_caching
    disk_size_gb              = var.virtual_machine_config.os_disk_size_gb
    storage_account_type      = var.virtual_machine_config.os_disk_storage_type
    write_accelerator_enabled = var.virtual_machine_config.os_disk_write_accelerator_enabled
  }

  source_image_reference {
    publisher = var.virtual_machine_config.os_publisher
    offer     = var.virtual_machine_config.os_offer
    sku       = var.virtual_machine_config.os_sku
    version   = var.virtual_machine_config.os_version
  }

  dynamic "plan" {
    for_each = var.virtual_machine_config.enable_plan ? ["one"] : []
    content {
      name      = var.virtual_machine_config.os_sku
      product   = var.virtual_machine_config.os_offer
      publisher = var.virtual_machine_config.os_publisher
    }
  }

  proximity_placement_group_id = var.virtual_machine_config.proximity_placement_group_id
  network_interface_ids        = concat([azurerm_network_interface.this.id], var.additional_network_interface_ids)
  availability_set_id          = var.virtual_machine_config.availability_set_id
  zone                         = var.virtual_machine_config.zone
  tags                         = local.virtual_machine.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      # Ignore policy assigned managed identities
      identity,
      admin_password
    ]
  }

  depends_on = [
    azurerm_marketplace_agreement.default
  ]
}


resource "azurerm_virtual_machine_extension" "python_setup" {
  count                = var.disk_encryption != null ? 1 : 0
  name                 = "${var.virtual_machine_config.hostname}-pythonSetup"
  virtual_machine_id   = azurerm_linux_virtual_machine.this.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
{
  "commandToExecute": "bash -c 'if command -v apt-get >/dev/null 2>&1; then apt-get update -y && apt-get install -y python2 || apt-get install -y python-is-python2; elif command -v yum >/dev/null 2>&1; then yum install -y python2 || yum install -y python; elif command -v dnf >/dev/null 2>&1; then dnf install -y python2 || dnf install -y python; elif command -v zypper >/dev/null 2>&1; then zypper refresh && (zypper install -y python2 || zypper install -y python); fi; if [ -x /usr/bin/python2 ]; then ln -sf /usr/bin/python2 /usr/bin/python; fi'"
}
SETTINGS
}


resource "azurerm_virtual_machine_extension" "disk_encryption" {
  count = var.disk_encryption != null ? 1 : 0

  name                 = "${var.virtual_machine_config.hostname}-diskEncryption"
  virtual_machine_id   = azurerm_linux_virtual_machine.this.id
  publisher            = var.disk_encryption.publisher
  type                 = var.disk_encryption.type
  type_handler_version = var.disk_encryption.type_handler_version

  settings = jsonencode(var.disk_encryption.settings)

  depends_on = [
    azurerm_virtual_machine_extension.python_setup
  ]
}
