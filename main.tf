resource "azurerm_public_ip" "this" {
  count               = var.public_ip_config != null ? 1 : 0
  name                = local.public_ip.name
  resource_group_name = var.resource_group_name
  location            = var.virtual_machine_config.location
  allocation_method   = var.public_ip_config.allocation_method
  tags                = var.tags
}

resource "azurerm_network_interface" "this" {
  name                           = local.nic.name
  location                       = var.virtual_machine_config.location
  resource_group_name            = var.resource_group_name
  dns_servers                    = var.nic_config.dns_servers
  accelerated_networking_enabled = var.nic_config.enable_accelerated_networking
  tags                           = var.tags

  ip_configuration {
    name                          = local.nic.ip_config_name
    subnet_id                     = var.subnet.id
    private_ip_address_allocation = var.nic_config.private_ip == null ? "Dynamic" : "Static"
    private_ip_address            = var.nic_config.private_ip
    public_ip_address_id          = var.public_ip_config != null ? azurerm_public_ip.this[0].id : null
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
  name                            = local.virtual_machine.name
  computer_name                   = var.virtual_machine_config.hostname
  location                        = var.virtual_machine_config.location
  resource_group_name             = var.resource_group_name
  size                            = var.virtual_machine_config.size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_credential.admin_password
  disable_password_authentication = var.admin_credential.admin_password == null


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
}
