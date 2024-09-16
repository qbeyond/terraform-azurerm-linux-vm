provider "azurerm" {
  subscription_id = "fadc80bd-751e-4fe8-b2da-9d6e16bc4b52"
  features {}
}

module "virtual_machine" {
  source = "../.."

  virtual_machine_config = {
    hostname       = "CUSTAPP001"
    location       = azurerm_resource_group.this.location
    size           = "Standard_B1ms"
    os_sku         = "smvm12"
    os_offer       = "seppmailvirtualmachine"
    os_version     = "12.0.5"
    os_publisher   = "seppmailag"
    severity_group = "01-second-monday-0300-XCSUFEDTG-reboot"
    enable_plan    = true
  }
  admin_username = "local_admin"
  admin_credential = {
    admin_password = "H3ll0W0rld!"
  }

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