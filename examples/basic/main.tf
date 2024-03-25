provider "azurerm" {
  features {}
}

module "virtual_machine" {
    source = "../.."

    virtual_machine_config = {
        hostname     = "CUSTAPP001"
        location     = local.location
        size         = "Standard_B1ms"
        os_sku       = "22_04-lts-gen2"
        os_offer     = "0001-com-ubuntu-server-jammy"
        os_version   = "latest"
        os_publisher = "Canonical"
    }
    admin_credential = {
      admin_username                  = "local_admin"
      admin_password                  = "H3ll0W0rld!"
      disable_password_authentication = false
    }

    resource_group_name = azurerm_resource_group.this.name
    subnet              = azurerm_subnet.this
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