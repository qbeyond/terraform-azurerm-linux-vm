provider "azurerm" {
  features {}
}

module "linux_vm_qby" {
  source                           = "../.."
  for_each                         = local.vm_ux_qby
  resource_group_name              = each.value.resource_group_name
  public_ip_config                 = each.value.public_ip_config
  nic_config                       = each.value.nic_config
  subnet                           = each.value.subnet
  additional_network_interface_ids = each.value.additional_network_interface_ids
  virtual_machine_config = {
    hostname                     = each.key
    size                         = each.value.size
    location                     = local.location
    zone                         = each.value.zone
    admin_username               = each.value.admin_username
    os_sku                       = each.value.os_sku
    os_offer                     = each.value.os_offer
    os_version                   = each.value.os_version
    os_publisher                 = each.value.os_publisher
    os_disk_name                 = each.value.os_disk_name
    os_disk_caching              = each.value.os_disk_caching
    os_disk_size_gb              = each.value.os_disk_size_gb
    os_disk_storage_type         = each.value.os_disk_storage_type
    availability_set_id          = each.value.availability_set_id
    write_accelerator_enabled    = each.value.write_accelerator_enabled
    proximity_placement_group_id = each.value.proximity_placement_group_id
    tags                         = each.value.tags
  }
  admin_password         = each.value.admin_password
  public_key             = each.value.public_key
  vm_name_as_disk_prefix = each.value.vm_name_as_disk_prefix
  disk_prefix            = each.value.disk_prefix
  data_disks             = each.value.data_disks
  name_overrides         = each.value.name_overrides
  severity_group         = each.value.severity_group
  update_allowed         = each.value.update_allowed
  log_analytics_agent    = each.value.log_analytics_agent
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = local.location
}

resource "azurerm_virtual_network" "this" {
  name                = local.virtual_network_name
  address_space       = [ "10.0.0.0/24" ]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = local.subnet_name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [ "10.0.0.0/24" ]
}

resource "azurerm_availability_set" "this" {
  name                = local.availability_set_name
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_proximity_placement_group" "this" {
  name                = local.proximity_placement_group_name
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = local.law_name
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days    = 30
}

resource "azurerm_network_interface" "additional_nic_01" {
  name                = "nic-vm-${replace(element(azurerm_virtual_network.this.address_space,0), "/[./]/", "-")}-01"
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  dns_servers         = []

  ip_configuration {
    name                          = "ip-nic-01"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    private_ip_address            = null
    public_ip_address_id          = null
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_network_interface" "additional_nic_02" {
  name                = "nic-vm-${replace(element(azurerm_virtual_network.this.address_space,0), "/[./]/", "-")}-02"
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  dns_servers         = []

  ip_configuration {
    name                          = "ip-nic-02"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    private_ip_address            = null
    public_ip_address_id          = null
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

/* resource "azurerm_network_security_group" "this" {
  name                = local.nsg_name
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    name                       = "example"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
} */