provider "azurerm" {
  features {}
}

module "virtual_machine" {
  source = "../.."

  virtual_machine_config = {
    hostname       = "CUSTAPP001"
    location       = azurerm_resource_group.this.location
    size           = "Standard_B1ms"
    os_sku         = "22_04-lts-gen2"
    os_offer       = "0001-com-ubuntu-server-jammy"
    os_version     = "latest"
    os_publisher   = "Canonical"
    severity_group = "01-second-monday-0300-XCSUFEDTG-reboot"
  }
  admin_username = "local_admin"
  admin_credential = {
    admin_password = "H3ll0W0rld!"
  }
  stage = "tst"

  resource_group_name = azurerm_resource_group.this.name
  subnet              = azurerm_subnet.this
}

resource "azurerm_resource_group" "this" {
  name     = "rg-TestLinuxBasic-tst-01"
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
