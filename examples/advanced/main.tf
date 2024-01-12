provider "azurerm" {
  features {}
}

module "virtual_machine" {
  source = "../.."
  public_ip_config = {
  enabled           = true
  allocation_method = "Static"
  }
  public_key          = file("id_rsa.pub")
  nic_config = {
    nic1 = {
      private_ip  = "10.0.0.16"
      dns_servers = [ "10.0.0.10", "10.0.0.11" ]
      nsg         = azurerm_network_security_group.this
    }
  }
  virtual_machine_config = {
    hostname             = "CUSTAPP007"
    location             = azurerm_resource_group.this.location
    zone                 = null # Could be the default value "1", or "2" or "3". Not compatible with availability_set_id enabled.
    admin_username       = "qbinstall"
    size                 = "Standard_DS1_v2"
    os_sku               = "22_04-lts-gen2"
    os_offer             = "0001-com-ubuntu-server-jammy"
    os_version           = "latest"
    os_publisher         = "Canonical"
    os_disk_caching      = "ReadWrite"
    os_disk_storage_type = "StandardSSD_LRS"
    os_disk_size_gb      = 64
    tags = {
      "Environment" = "prd" 
    }
    availability_set_id          = azurerm_availability_set.this.id # Not compatible with zone.
    write_accelerator_enabled    = false
    proximity_placement_group_id = azurerm_proximity_placement_group.this.id
  }
  resource_group_name              = azurerm_resource_group.this.name
  subnet                           = azurerm_subnet.this
  additional_network_interface_ids = [azurerm_network_interface.additional_nic_01.id]
  enable_accelerated_networking    = true
  data_disks = {
    shared-01 = {  # Examp. With disk prefix: vm-CUSTAPP007-datadisk-shared-01., Without: vm-CUSTAPP007-shared-01
      lun                       = 1     
      tier                      = "P4"
      caching                   = "ReadWrite"
      disk_size_gb              = 32
      create_option             = "Empty"
      storage_account_type      = "StandardSSD_LRS"
      write_accelerator_enabled = false
    }
  }

  log_analytics_agent = azurerm_log_analytics_workspace.this

  name_overrides = {
    nic             = local.nic
    nic_ip_config   = local.nic_ip_config
    public_ip       = local.public_ip
    virtual_machine = local.virtual_machine
  }
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
  name                         = local.availability_set_name
  location                     = local.location
  resource_group_name          = azurerm_resource_group.this.name
  proximity_placement_group_id = azurerm_proximity_placement_group.this.id
}

resource "azurerm_proximity_placement_group" "this" {
  name                = local.proximity_placement_group_name
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  
  lifecycle {
      ignore_changes = [tags]
  }
}

resource "azurerm_network_interface" "additional_nic_01" {
  name                          = "nic-vm-${replace(element(azurerm_virtual_network.this.address_space,0), "/[./]/", "-")}-01"
  location                      = local.location
  resource_group_name           = azurerm_resource_group.this.name
  dns_servers                   = []

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

resource "azurerm_network_security_group" "this" {
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
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = local.law_name
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days    = 30
}