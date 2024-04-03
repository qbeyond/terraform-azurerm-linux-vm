provider "azurerm" {
  features {}
}

module "virtual_machine" {
  source = "../.."

  virtual_machine_config = {
    hostname       = "CUSTAPP001"
    location       = azurerm_resource_group.this.location
    size           = "Standard_M8ms"
    os_sku         = "22_04-lts-gen2"
    os_offer       = "0001-com-ubuntu-server-jammy"
    os_version     = "latest"
    os_publisher   = "Canonical"
    severity_group = "01-second-monday-0300-XCSUFEDTG-reboot"
  }
  admin_credential = {
    admin_password = "H3ll0W0rld!"
  }
  stage = "tst"

  data_disks = {
    shared-01 = {
      lun                        = 1
      tier                       = "P4"
      caching                    = "ReadOnly"
      disk_size_gb               = 513
      create_option              = "Empty"
      storage_account_type       = "Premium_LRS"
      write_accelerator_enabled  = true
      on_demand_bursting_enabled = true
    }
    shared-02 = {
      lun                        = 2
      tier                       = "P4"
      caching                    = "None"
      disk_size_gb               = 513
      create_option              = "Empty"
      storage_account_type       = "Premium_LRS"
      write_accelerator_enabled  = true
      on_demand_bursting_enabled = true
    }
    shared-03 = {
      lun                        = 3
      tier                       = "P4"
      caching                    = "ReadWrite"
      disk_size_gb               = 513
      create_option              = "Empty"
      storage_account_type       = "Premium_LRS"
      write_accelerator_enabled  = false
      on_demand_bursting_enabled = false
    }
  }
  resource_group_name = azurerm_resource_group.this.name
  subnet              = azurerm_subnet.this
}

resource "azurerm_resource_group" "this" {
  name     = "rg-TestLinuxWriteAccelerator-tst-01"
  location = "westeurope"
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-10-0-0-0-24-${azurerm_resource_group.this.location}"
  address_space       = ["10.0.0.0/24"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = "snet-10-0-0-0-24-Test"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.0.0/24"]
}
