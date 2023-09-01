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
    private_ip  = "10.0.0.16"
    dns_servers = [ "10.0.0.10", "10.0.0.11" ]
    nsg_name    = local.nsg_name
    nsg_rg_name = azurerm_network_security_group.this.resource_group_name
  }
    virtual_machine_config = {
    hostname             = "CUSTAPP007"
    size                 = "Standard_D2_v5"
    location             = azurerm_resource_group.this.location
    admin_username       = "local_admin"
    size                 = "Standard_D2_v5"
    os_sku               = "gen2"
    os_offer             = "sles-15-sp4"
    os_version           = "2023.02.05"
    os_publisher         = "SUSE"
    availability_set_id  = azurerm_availability_set.this.id
    os_disk_name         = "OsDisk_01"
    os_disk_caching      = "ReadWrite"
    os_disk_storage_type = "StandardSSD_LRS"
    os_disk_size_gb      = 128
    tags = {
      "Environment" = "prd" 
    }
    write_accelerator_enabled = false
  }
  resource_group_name = azurerm_resource_group.this.name
  subnet              = azurerm_subnet.this
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
  name                = local.availability_set_name
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
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