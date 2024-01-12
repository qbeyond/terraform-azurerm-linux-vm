# Module
[![GitHub tag](https://img.shields.io/github/tag/qbeyond/terraform-azurerm-linux-vm.svg)](https://registry.terraform.io/modules/qbeyond/linux-vm/azurerm/latest)
[![License](https://img.shields.io/github/license/qbeyond/terraform-azurerm-linux-vm.svg)](https://github.com/qbeyond/terraform-azurerm-linux-vm/blob/main/LICENSE)

----

This module will create a linux virtual machine, a network interface and associates the network interface to the target subnet. Optionally one or more data disks and a public ip can be created and additional network interfaces. 

<!-- BEGIN_TF_DOCS -->
## Usage

It's very easy to use!
```hcl
provider "azurerm" {
  features {}
}

module "virtual_machine" {
    source = "../.."
    virtual_machine_config = {
        hostname       = "CUSTAPP001"
        location       = local.location
        admin_username = "local_admin"
        size           = "Standard_B1ms"
    }

    admin_password      = "H3ll0W0rld!"
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
```
###### Advanced
```hcl
locals {
  location                       = "West Europe"
  resource_group_name            = "rg-examples_vm_deploy-02"
  virtual_network_name           = "vnet-examples_vm_deploy-02"
  subnet_name                    = "snet-examples_vm_deploy-02"
  availability_set_name          = "as-examples_vm_deploy-02"
  proximity_placement_group_name = "ppg-examples_vm_deploy-02"
  nsg_name                       = "nsg-examples_vm_deploy-02"
  law_name                       = "law-examplesvmdeploy-02"
  nic                            = "nic-examples_vm_deploy-02"
  nic_ip_config                  = "nic-ip-examples_vm_deploy-02"
  public_ip                      = "pip-examples_vm_deploy-02"
  virtual_machine                = "vm-examples_vm_deploy-02"
}

provider "azurerm" {
  features {}
}

module "virtual_machine" {
  source          = "../.."
  public_ip_config = {
    enabled           = true
    allocation_method = "Static"
  }
  nic_config = {
    nic1 = {
      private_ip  = "10.0.0.16"
  #    dns_servers = [ "10.0.0.10", "10.0.0.11" ]
  #    nsg         = azurerm_network_security_group.this
    }
  }
  virtual_machine_config = {
    hostname             = "CUSTAPP007"
    location             = azurerm_resource_group.this.location
    zone                 = null # Could be the default value "1", or "2" or "3". Not compatible with availability_set_id enabled.
    admin_username       = "qbinstall"
    size                 = "Standard_DS1_v2"
    os_sku               = "20_04-lts-gen2"
    os_offer             = "0001-com-ubuntu-server-focal"
    os_version           = "latest"
    os_publisher         = "Canonical"
    os_disk_caching      = "ReadWrite"
    os_disk_storage_type = "StandardSSD_LRS"
    os_disk_size_gb      = 64
    tags = {
      "Environment" = "prd" 
    }
    availability_set_id        = azurerm_availability_set.this.id # Not compatible with zone.
    write_accelerator_enabled  = false
  }
  admin_password                   = ""                 # Write a password if you need.
  public_key                       = file("id_rsa.pub") # If don't need rsa, leave empty with this "".
  resource_group_name              = azurerm_resource_group.this.name
  subnet                           = azurerm_subnet.this
  additional_network_interface_ids = [azurerm_network_interface.additional_nic_01.id]
  enable_accelerated_networking    = true
  severity_group                   = "01-third-tuesday-0200-XCSUFEDTG-reboot"
  update_allowed                   = true
  
  ## DISK DECLARATION
   data_disks = {                         
    shared-01 = {                        # Name should be: vm-CUSTAPP001-datadisk-shared-01, or use name_override
      lun                        = 1     
      caching                    = "ReadWrite"
      disk_size_gb               = 32
      create_option              = "Empty"
      storage_account_type       = "StandardSSD_LRS"
      write_accelerator_enabled  = false
      on_demand_bursting_enabled = false
    }
    sap-01 = {
      lun                        = 2
      caching                    = "ReadWrite"
      disk_size_gb               = 32
      create_option              = "Empty"
      storage_account_type       = "Premium_LRS"
      write_accelerator_enabled  = false
      on_demand_bursting_enabled = false
    }
  }

  name_overrides = {
    nic             = "nic-examples_vm_CUSTAPP001"
    nic_ip_config   = "nic-ip-examples_vm_CUSTAPP001"
    public_ip       = "pip-examples_vm_CUSTAPP001"
    data_disks = {
      shared-01 = "vm-CUSTAPP007-datadisk-shared-01"
    }    
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
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.7.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where the resources will be created. | `string` | n/a | yes |
| <a name="input_subnet"></a> [subnet](#input\_subnet) | The variable takes the subnet as input and takes the id and the address prefix for further configuration. | <pre>object ({<br>    id               = string<br>    address_prefixes = list(string)<br>  })</pre> | n/a | yes |
| <a name="input_virtual_machine_config"></a> [virtual\_machine\_config](#input\_virtual\_machine\_config) | <pre>  hostname: Name of system hostname.<br>  size: The size of the vm. Possible values can be seen here: https://learn.microsoft.com/en-us/azure/virtual-machines/sizes<br>  location: The location of the virtual machine.<br>  admin_username: Optionally choose the admin_username of the vm. Defaults to loc_sysadmin. <br>    The local admin name could be changed by the gpo in the target ad.<br>  os_sku: The os that will be running on the vm.<br>  os_offer: (Required) Specifies the offer of the image used to create the virtual machines. Changing this forces a new resource to be created.<br>  os_version: Optionally specify an os version for the chosen sku. Defaults to latest.<br>  os_publisher: (Required) Specifies the Publisher of the Marketplace Image this Virtual Machine should be created from. Changing this forces a new resource to be created.<br>  os_disk_caching: Optionally change the caching option of the os disk. Defaults to ReadWrite.<br>  os_disk_size_gb: Optionally change the size of the os disk. Defaults to be specified by image.<br>  os_disk_storage_type: Optionally change the os_disk_storage_type. Defaults to Premium_LRS.<br>  zone: Optionally specify an availibility zone for the vm. Values 1, 2 or 3.<br>  availability_set_id: Optionally specify an availibility set for the vm.<br>  write_accelerator_enabled: Optionally activate write accelaration for the os disk. Can only<br>    be activated on Premium_LRS disks and caching deactivated. Defaults to false.<br>  proximity_placement_group_id: (Optional) The ID of the Proximity Placement Group which the Virtual Machine should be assigned to.<br>  tags: Optionally specify tags in as a map.</pre> | <pre>object({<br>      hostname                     = string<br>      size                         = string<br>      location                     = string<br>      admin_username               = optional(string, "loc_sysadmin")<br>      os_sku                       = string<br>      os_offer                     = optional(string)<br>      os_version                   = optional(string, "latest")<br>      os_publisher                 = optional(string)<br>      os_disk_caching              = optional(string, "ReadWrite")<br>      os_disk_size_gb              = optional(number, 64)<br>      os_disk_storage_type         = optional(string, "Premium_LRS")<br>      zone                         = optional(string)<br>      availability_set_id          = optional(string)<br>      write_accelerator_enabled    = optional(bool, false)<br>      proximity_placement_group_id = optional(string)<br>      tags                         = optional(map(string))<br>  })</pre> | n/a | yes |
| <a name="input_additional_network_interface_ids"></a> [additional\_network\_interface\_ids](#input\_additional\_network\_interface\_ids) | List of ids for additional azurerm\_network\_interface. | `list(string)` | `[]` | no |
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | Password of the local administrator. | `string` | `""` | no |
| <a name="input_data_disks"></a> [data\_disks](#input\_data\_disks) | <pre><name of the data disk> = {<br>  lun: Number of the lun.<br>  disk_size_gb: The size of the data disk.<br>  zone: Optionally specify an availibility zone for the vm. Values 1, 2 or 3.<br>  storage_account_type: Optionally change the storage_account_type. Defaults to StandardSSD_LRS.<br>  caching: Optionally activate disk caching. Defaults to None.<br>  create_option: Optionally change the create option. Defaults to Empty disk.<br>  write_accelerator_enabled: Optionally activate write accelaration for the data disk. Can only<br>    be activated on Premium_LRS disks and caching deactivated. Defaults to false.<br>  on_demand_bursting_enabled: Optionally activate disk bursting. . Only for Premium disk. Default false.<br> }</pre> | <pre>map(object({<br>    lun                        = number<br>    disk_size_gb               = number<br>    zone                       = optional(string)<br>    caching                    = optional(string, "ReadWrite")<br>    create_option              = optional(string, "Empty")<br>    storage_account_type       = optional(string, "StandardSSD_LRS")<br>    write_accelerator_enabled  = optional(bool, false)<br>    on_demand_bursting_enabled = optional(bool, false)<br> }))</pre> | `{}` | no |
| <a name="input_enable_accelerated_networking"></a> [enable\_accelerated\_networking](#input\_enable\_accelerated\_networking) | Enabled Accelerated networking (SR-IOV) on the NIC. The machine SKU must support this feature. | `bool` | `"false"` | no |
| <a name="input_log_analytics_agent"></a> [log\_analytics\_agent](#input\_log\_analytics\_agent) | <pre>Installs the log analytics agent(MicrosoftMonitoringAgent).<br>  workspace_id: Specify id of the log analytics workspace to which monitoring data will be sent.<br>  shared_key: The Primary shared key for the Log Analytics Workspace..</pre> | <pre>object({<br>    workspace_id       = string<br>    primary_shared_key = string <br>  })</pre> | `null` | no |
| <a name="input_name_overrides"></a> [name\_overrides](#input\_name\_overrides) | Possibility to override names that will be generated according to q.beyond naming convention. | <pre>object({<br>      nic             = optional(string)<br>      nic_ip_config   = optional(string)<br>      public_ip       = optional(string)<br>      virtual_machine = optional(string)<br>      os_disk         = optional(string)<br>      data_disks      = optional(map(string), {})<br>  })</pre> | `{}` | no |
| <a name="input_nic_config"></a> [nic\_config](#input\_nic\_config) | <pre>private_ip: Optioanlly specify a private ip to use. Otherwise it will  be allocated dynamically.<br>  dns_servers: Optionally specify a list of dns servers for the nic.<br>  enable_accelerated_networking: Enabled Accelerated networking (SR-IOV) on the NIC. The machine SKU must support this feature.<br>  nsg_id: Optinally specify the id of a network security group that will be assigned to the nic.</pre> | <pre>object({<br>    private_ip  = optional(string)<br>    dns_servers = optional(list(string))<br>    nsg = optional(object({<br>      id = string<br>    }))<br>  })</pre> | `{}` | no |
| <a name="input_public_ip_config"></a> [public\_ip\_config](#input\_public\_ip\_config) | <pre>enabled: Optionally select true if a public ip should be created. Defaults to false.<br>  allocation_method: The allocation method of the public ip that will be created. Defaults to static.</pre> | <pre>object({<br>      enabled           = bool<br>      allocation_method = optional(string, "Static")<br>  })</pre> | <pre>{<br>  "enabled": false<br>}</pre> | no |
| <a name="input_public_key"></a> [public\_key](#input\_public\_key) | SSH public key file (e.g. file(id\_rsa.pub) | `string` | `""` | no |
| <a name="input_severity_group"></a> [severity\_group](#input\_severity\_group) | The severity group of the virtual machine. | `string` | `""` | no |
| <a name="input_update_allowed"></a> [update\_allowed](#input\_update\_allowed) | Set the tag `Update allowed`. `True` will set `yes`, `false` to `no`. | `bool` | `true` | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_virtual_machine"></a> [virtual\_machine](#output\_virtual\_machine) | n/a |

## Resource types

| Type | Used |
|------|-------|
| [azurerm_linux_virtual_machine](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | 1 |
| [azurerm_managed_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | 1 |
| [azurerm_network_interface](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | 1 |
| [azurerm_network_interface_security_group_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | 1 |
| [azurerm_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | 1 |
| [azurerm_virtual_machine_data_disk_attachment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | 1 |
| [azurerm_virtual_machine_extension](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | 2 |

**`Used` only includes resource blocks.** `for_each` and `count` meta arguments, as well as resource blocks of modules are not considered.

## Modules

No modules.

## Resources by Files

### data_disk.tf

| Name | Type |
|------|------|
| [azurerm_managed_disk.data_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | resource |
| [azurerm_virtual_machine_data_disk_attachment.data_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |

### extension_azuremonitor.tf

| Name | Type |
|------|------|
| [azurerm_virtual_machine_extension.microsoftmonitoringagent](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |

### extension_dependencyagent.tf

| Name | Type |
|------|------|
| [azurerm_virtual_machine_extension.DependencyAgentLinux](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |

### main.tf

| Name | Type |
|------|------|
| [azurerm_linux_virtual_machine.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_public_ip.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
<!-- END_TF_DOCS -->

## Contribute

Please use Pull requests to contribute.

When a new Feature or Fix is ready to be released, create a new Github release and adhere to [Semantic Versioning 2.0.0](https://semver.org/lang/de/spec/v2.0.0.html).