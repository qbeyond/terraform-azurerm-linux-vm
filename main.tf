# To have a NSG
data "azurerm_network_security_group" "this" {
  count               = length(var.nic_config.nsg_name) > 0 && length(var.nic_config.nsg_rg_name) > 0 ? 1 : 0
  name                = var.nic_config.nsg_name
  resource_group_name = var.nic_config.nsg_rg_name
}
 
resource "azurerm_public_ip" "this" {
  count               = var.public_ip_config.enabled ? 1 : 0
  name                = local.public_ip.name
  resource_group_name = var.resource_group_name
  location            = var.virtual_machine_config.location
  allocation_method   = var.public_ip_config.allocation_method

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_network_interface" "this" {
  name                = local.nic.name
  location            = var.virtual_machine_config.location
  resource_group_name = var.resource_group_name
  dns_servers         = var.nic_config.dns_servers

  ip_configuration {
    name                          = local.nic.ip_config_name
    subnet_id                     = var.subnet.id
    private_ip_address_allocation = var.nic_config.private_ip == null ? "Dynamic" : "Static"
    private_ip_address            = var.nic_config.private_ip
    public_ip_address_id          = var.public_ip_config.enabled ? azurerm_public_ip.this[0].id : null
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_network_interface_security_group_association" "this" {
  count                     = length(var.nic_config.nsg_name) > 0 ? 1 : 0
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = data.azurerm_network_security_group.this[0].id
}

resource "azurerm_linux_virtual_machine" "this" {
  name                            = local.virtual_machine.name
  computer_name                   = var.virtual_machine_config.hostname
  location                        = var.virtual_machine_config.location
  resource_group_name             = var.resource_group_name
  size                            = var.virtual_machine_config.size
  provision_vm_agent              = true
  admin_username                  = var.virtual_machine_config.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = length(var.admin_password) > 0 && length(var.public_key) == 0 ? false : true

  dynamic "admin_ssh_key" {
    for_each = length(var.public_key) > 0 ? [1] : []
    content {
      username   = var.virtual_machine_config.admin_username
      public_key = var.public_key
    }
  }

  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  os_disk {
    name                      = var.virtual_machine_config.os_disk_name
    caching                   = var.virtual_machine_config.os_disk_caching
    disk_size_gb              = var.virtual_machine_config.os_disk_size_gb
    storage_account_type      = var.virtual_machine_config.os_disk_storage_type    
    write_accelerator_enabled = var.virtual_machine_config.write_accelerator_enabled
  }

  source_image_reference {
    publisher = var.virtual_machine_config.os_publisher
    offer     = var.virtual_machine_config.os_offer
    sku       = var.virtual_machine_config.os_sku
    version   = var.virtual_machine_config.os_version
  }

  availability_set_id = var.virtual_machine_config.availability_set_id
  zone                = length(var.virtual_machine_config.zone) > 0 && var.virtual_machine_config.availability_set_id == null ? var.virtual_machine_config.zone : null
  tags                = merge(var.virtual_machine_config.tags, {"Severity Group Monthly" = var.severity_group})

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      identity,
      tags
    ]
  }
}