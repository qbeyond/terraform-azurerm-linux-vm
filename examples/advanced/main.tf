provider "azurerm" {
  features {}
}

locals {
  hostname = "CUSTAPP007"
}

module "virtual_machine" {
  source = "../.."
  public_ip_config = {
    enabled           = true
    allocation_method = "Static"
  }
  stage = "tst"
  nic_config = {
    private_ip                    = "10.0.0.16"
    enable_accelerated_networking = true
    dns_servers                   = ["10.0.0.10", "10.0.0.11"]
    nsg                           = azurerm_network_security_group.this
  }
  virtual_machine_config = {
    hostname                          = local.hostname
    location                          = azurerm_resource_group.this.location
    size                              = "Standard_B2s_v2"
    zone                              = null # Could be the default value "1", or "2" or "3". Not compatible with availability_set_id enabled.
    os_sku                            = "22_04-lts-gen2"
    os_offer                          = "0001-com-ubuntu-server-jammy"
    os_version                        = "latest"
    os_publisher                      = "Canonical"
    os_disk_caching                   = "ReadWrite"
    os_disk_storage_type              = "StandardSSD_LRS"
    os_disk_size_gb                   = 64
    availability_set_id               = azurerm_availability_set.this.id # Not compatible with zone.
    os_disk_write_accelerator_enabled = false
    proximity_placement_group_id      = azurerm_proximity_placement_group.this.id
    severity_group                    = "01-second-monday-0300-XCSUFEDTG-reboot"
    tags = {
      "Environment" = "prd"
    }
  }
  admin_username = "local_admin"
  admin_credential = {
    public_key = file("${path.root}/id_rsa.pub")
  }

  resource_group_name              = azurerm_resource_group.this.name
  subnet                           = azurerm_subnet.this
  additional_network_interface_ids = [azurerm_network_interface.additional_nic_01.id]

  data_disks = {
    shared01 = {
      lun                        = 1
      tier                       = "P4"
      caching                    = "None"
      disk_size_gb               = 513
      create_option              = "Empty"
      storage_account_type       = "Premium_LRS"
      write_accelerator_enabled  = false
      on_demand_bursting_enabled = true
    }
  }

  name_overrides = {
    nic             = "nic-name-override"
    nic_ip_config   = "nic-ip-config-override"
    public_ip       = "pip-name-override"
    virtual_machine = "vm-name-override"
    os_disk         = "vm-os-disk-override"
    data_disks = {
      shared-01 = "vm-datadisk-override"
    }
  }
}

resource "azurerm_resource_group" "this" {
  name     = "rg-TestLinuxAdvanced-tst-01"
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

resource "azurerm_availability_set" "this" {
  name                         = "avs-example-01"
  location                     = azurerm_resource_group.this.location
  resource_group_name          = azurerm_resource_group.this.name
  proximity_placement_group_id = azurerm_proximity_placement_group.this.id
}

resource "azurerm_proximity_placement_group" "this" {
  name                = "ppg-Example-test-${azurerm_resource_group.this.location}-01"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_network_interface" "additional_nic_01" {
  name                = "nic-${local.hostname}-${replace(element(azurerm_virtual_network.this.address_space, 0), "/[./]/", "-")}-02"
  location            = azurerm_resource_group.this.location
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

resource "azurerm_network_security_group" "this" {
  name                = "nsg-${trimprefix(azurerm_network_interface.additional_nic_01.name, "nic-")}-Example-Test"
  location            = azurerm_resource_group.this.location
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
