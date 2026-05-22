# How to use this example:
# 1. Create a Windows VM in Azure with the Basic example.
# 2. Fill in the subscription_id in the provider block of this example and adjust the import blocks to match the existing Resources.
# 3. Run this example and try to import the existing VM into the state file of this example.
# 4. If all resources get imported successfully, the Module works as intended.
# (There are one error build in to test the correction of the name_overrides. The RG name)
provider "azurerm" {
  subscription_id = "<Subscription ID>" # <-- Fill in Subscription ID
  features {}
}

module "virtual_machine" {
  source      = "../.."
  is_imported = true
  virtual_machine_config = {
    hostname       = "CUSTAPP001"
    location       = azurerm_resource_group.this.location
    size           = "Standard_D2as_v6"
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

  resource_group_name = azurerm_resource_group.this.name
  subnet              = azurerm_subnet.this

  name_overrides = {
    hostname                = "CUSTAPP001"
    virtual_machine         = "vm-CUSTAPP001"
    os_disk                 = "disk-CUSTAPP001-Os"
    nic                     = "nic-CUSTAPP001-10-0-0-0-24"
    resource_group_name_vm  = "rg-TestLinuxBasic-tst-01"
    resource_group_name_nic = "rg-TestLinuxBasic-tst-01"
    data_disks              = { "Data00" = "disk-CUSTAPP001-Data00" }
  }
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = local.location
}

resource "azurerm_virtual_network" "this" {
  name                = local.virtual_network_name
  address_space       = ["10.0.0.0/24"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = local.subnet_name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.0.0/24"]
}

import {
  to = module.virtual_machine.azurerm_linux_virtual_machine.imported[0]
  id = "/subscriptions/<Subscription ID>/resourceGroups/rg-TestLinuxBasic-tst-01/providers/Microsoft.Compute/virtualMachines/vm-CUSTAPP001" # <-- Fill in Resource ID of the existing VM
}

import {
  to = module.virtual_machine.azurerm_network_interface.this
  id = "/subscriptions/<Subscription ID>/resourceGroups/rg-TestLinuxBasic-tst-01/providers/Microsoft.Network/networkInterfaces/nic-CUSTAPP001-10-0-0-0-24" # <-- Fill in Resource ID of the existing NIC
}

import {
  to = azurerm_virtual_network.this
  id = "/subscriptions/<Subscription ID>/resourceGroups/rg-TestLinuxBasic-tst-01/providers/Microsoft.Network/virtualNetworks/vnet-10-0-0-0-24-westeurope" # <-- Fill in Resource ID of the existing VNet
}

import {
  to = azurerm_subnet.this
  id = "/subscriptions/<Subscription ID>/resourceGroups/rg-TestLinuxBasic-tst-01/providers/Microsoft.Network/virtualNetworks/vnet-10-0-0-0-24-westeurope/subnets/snet-10-0-0-0-24-Test" # <-- Fill in Resource ID of the existing Subnet
}

import {
  to = azurerm_resource_group.this
  id = "/subscriptions/<Subscription ID>/resourceGroups/rg-TestLinuxBasic-tst-01" # <-- Fill in Resource ID of the existing Resource Group
}
