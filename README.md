# Module
[![GitHub tag](https://img.shields.io/github/tag/qbeyond/terraform-module-template.svg)](https://registry.terraform.io/modules/qbeyond/terraform-module-template/provider/latest)
[![License](https://img.shields.io/github/license/qbeyond/terraform-module-template.svg)](https://github.com/qbeyond/terraform-module-template/blob/main/LICENSE)

----

This module will create a linux virtual machine, a network interface and associates the network interface to the target subnet. Optionally one or more data disks and a public ip can be created. 

<!-- BEGIN_TF_DOCS -->
## Usage

This module provisions a linux virtual machine. Refer to the examples on how this could be done. It is a fast and easy to use deployment of a virtual machine!
#### Examples
###### Basic
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
        size           = "Standard_D2_v5"
    }

    admin_password = "H3ll0W0rld!"
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
provider "azurerm" {
  features {}
}

module "virtual_machine" {
  source = "../.."
  resource_group_name = azurerm_resource_group.this.name
  subnet              = azurerm_subnet.this
  public_ip_config = {
    enabled           = true
    allocation_method = "Static"
  }
  nic_config = {
    private_ip  = "10.0.0.16"
    dns_servers = [ "10.0.0.10", "10.0.0.11" ]
    
    # 1.- create a NSG with: https://github.com/qbeyond/terraform-azurerm-nsg or create with resource azurerm_network_security_group.
    # 2.- Insert the name of NSG and the NSG RG
    nsg_name    = local.nsg_name  # Examp. nsg_name    = "nsg-prd-example-01"
    nsg_rg_name = azurerm_network_security_group.this.resource_group_name
  }
  virtual_machine_config = {
    hostname             = "CUSTAPP001"
    location             = azurerm_resource_group.rg.location
    admin_username       = "local_admin"
    size                 = "Standard_D2_v5"
    os_sku               = "gen2"
    os_offer             = "sles-15-sp4"
    os_version           = "2023.02.05"
    os_publisher         = "SUSE"
    zone                 = "" # Could be the default value "", or "1", or "2" or "3"
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
  admin_password         = ""                 # If empty, not use admin password.
  public_key             = file("id_rsa.pub") # If empty, not use rsa.
  vm_name_as_disk_prefix = true               # true or false. Insert vm-<hostname>- as prefix disk name.
  disk_prefix            = "datadisk"         # Is part of the prefix of the disk name. 'vm-<hostname>-<disk_prefix>-<data_disk_key>
  data_disks = {                         
    shared-01 = {  # Examp. Name result, could be: vm-CUSTAPP001-datadisk-shared-01., or vm-CUSTAPP001-shared-01, or datadisk-shared-01, or shared-01
    lun                        = 1     
    tier                       = "P4"
    caching                    = "ReadWrite"
    disk_size_gb               = 32
    create_option              = "Empty"
    storage_account_type       = "StandardSSD_LRS"
    write_accelerator_enabled  = false
    on_demand_bursting_enabled = true
    }
    sap-01 = {
      lun                       = 2
      tier                      = "P4"
      caching                   = "ReadWrite"
      disk_size_gb              = 32
      create_option             = "Empty"
      storage_account_type      = "Premium_LRS"
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
  retention_in_days   = 30
}
```

###### Adavanced two

```hcl
locals {

  location              = "West Europe"
  resource_group_name   = "rg-examples_vm_deploy-02"
  virtual_network_name  = "vnet-examples_vm_deploy-02"
  subnet_name           = "snet-examples_vm_deploy-02"
  availability_set_name = "as-examples_vm_deploy-02"
  nsg_name              = "nsg-examples_vm_deploy-02"
  law_name              = "law-examplesvmdeploy-02"

  ## VM DECLARATION.

  vm_ux_qby = {
    PEACFASE033 = {
      resource_group_name = azurerm_resource_group.this.name
      subnet              = azurerm_subnet.this
      public_ip_config = {
        enabled           = true
        allocation_method = "Dynamic"
      }
      nic_config = {
        private_ip  = "10.0.0.16"
        dns_servers = ["10.0.0.10", "10.0.0.11"]

        # 1.- create a NSG with: https://github.com/qbeyond/terraform-azurerm-nsg
        # 2.- Insert the name of NSG and the NSG RG
        nsg_name    = "nsg-examples_vm_deploy-02"  # nsg_name    = "nsg-multiiacvm-dev-demo21-01"
        nsg_rg_name = azurerm_network_security_group.this.resource_group_name  # nsg_rg_name = azurerm_resource_group.rg.name
      }
      size                      = "Standard_E4as_v5"
      location                  = local.location
      zone                      = ""
      admin_username            = "qbinstall"
      admin_password            = ""                 # Write a password if you need.
      public_key                = file("id_rsa.pub") # If don't need rsa, leave empty with this "".
      os_sku                    = "gen2"
      os_offer                  = "sles-15-sp4"
      os_version                = "2023.02.05"
      os_publisher              = "SUSE"
      os_disk_name              = "OsDisk_01"
      os_disk_caching           = "ReadWrite"
      os_disk_size_gb           = 64
      os_disk_storage_type      = "Premium_LRS"
      availability_set_id       = azurerm_availability_set.this.id
      write_accelerator_enabled = false
      severity_group            = ""
      name_overrides = {
        nic             = "nic-examples_vm_PEACFASE033"
        nic_ip_config   = "nic-ip-examples_vm_PEACFASE033"
        public_ip       = "pip-examples_vm_PEACFASE033"
        virtual_machine = "vm-PEACFASE033"
      }
      log_analytics_agent       = azurerm_log_analytics_workspace.this
      
      ## DISK DECLARATION
      
      vm_name_as_disk_prefix    = true        # Insert vm-<hostname>- as prefix disk name
      disk_prefix               = "datadisk" # Is part of the prefix of the disk name. 'vm-<hostname>-<disk_prefix>-<data_disk_key>
      data_disks = {                         # 'vm-<hostname>' is added by the VM module.
        shared-01 = {                        # Examp. With disk prefix: vm-PEACFASE033-datadisk-shared-01., Without: vm-PEACFASE033-shared-01
          lun                        = 1     
          tier                       = "P4"
          caching                    = "ReadWrite"
          disk_size_gb               = 32
          create_option              = "Empty"
          storage_account_type       = "StandardSSD_LRS"
          write_accelerator_enabled  = false
          on_demand_bursting_enabled = true
        }
        sap-01 = {
          lun                       = 2
          tier                      = "P4"
          caching                   = "ReadWrite"
          disk_size_gb              = 32
          create_option             = "Empty"
          storage_account_type      = "Premium_LRS"
          write_accelerator_enabled = false
        }
      }
    }
    PEACFASE034 = {
      resource_group_name = azurerm_resource_group.this.name
      subnet              = azurerm_subnet.this
      public_ip_config = {
        enabled           = false
        allocation_method = "Dynamic"
      }
      nic_config = {
        private_ip  = "10.0.0.17"
        dns_servers = ["10.0.0.10", "10.0.0.11"]

        # 1.- create a NSG with: https://github.com/qbeyond/terraform-azurerm-nsg
        # 2.- Insert the name of NSG and the NSG RG
        nsg_name    = "nsg-examples_vm_deploy-02"  # nsg_name    = "nsg-multiiacvm-dev-demo21-01"
        nsg_rg_name = azurerm_network_security_group.this.resource_group_name  # nsg_rg_name = azurerm_resource_group.rg.name
      }
      size                      = "Standard_E4as_v5"
      location                  = local.location
      zone                      = ""
      admin_username            = "qbinstall"
      admin_password            = ""                 # Write a password if you need.
      public_key                = file("id_rsa.pub") # If don't need rsa, leave empty with this "".
      os_sku                    = "gen2"
      os_offer                  = "sles-15-sp4"
      os_version                = "2023.02.05"
      os_publisher              = "SUSE"
      os_disk_name              = "OsDisk_01"
      os_disk_caching           = "ReadWrite"
      os_disk_size_gb           = 64
      os_disk_storage_type      = "Premium_LRS"
      availability_set_id       = azurerm_availability_set.this.id
      write_accelerator_enabled = false
      severity_group            = ""
      name_overrides = {}
      log_analytics_agent       = azurerm_log_analytics_workspace.this
      
      ## DISK DECLARATION
      
      vm_name_as_disk_prefix    = true        # Insert vm-<hostname>- as prefix disk name
      disk_prefix               = "datadisk" # Is part of the prefix of the disk name. 'vm-<hostname>-<disk_prefix>-<data_disk_key>
      data_disks = {                         # 'vm-<hostname>' is added by the VM module.
      }
    }
  }
}

### RESOURCES DECLARATION

provider "azurerm" {
  features {}
}

module "linux_vm_qby" {
  source                 = "../.."
  for_each               = local.vm_ux_qby
  resource_group_name    = each.value.resource_group_name
  public_ip_config       = each.value.public_ip_config
  nic_config             = each.value.nic_config
  subnet                 = each.value.subnet
  virtual_machine_config = {
    hostname                   = each.key
    size                       = each.value.size
    location                   = local.location
    zone                       = each.value.zone
    admin_username             = each.value.admin_username
    os_sku                     = each.value.os_sku
    os_offer                   = each.value.os_offer
    os_version                 = each.value.os_version
    os_publisher               = each.value.os_publisher
    os_disk_name               = each.value.os_disk_name
    os_disk_caching            = each.value.os_disk_caching
    os_disk_size_gb            = each.value.os_disk_size_gb
    os_disk_storage_type       = each.value.os_disk_storage_type
    availability_set_id        = each.value.availability_set_id
    write_accelerator_enabled  = each.value.write_accelerator_enabled
    on_demand_bursting_enabled = length(each.value.on_demand_bursting_enabled) > 0 ? true : false
  }
  admin_password         = each.value.admin_password
  public_key             = each.value.public_key
  vm_name_as_disk_prefix = each.value.vm_name_as_disk_prefix
  disk_prefix            = each.value.disk_prefix
  data_disks             = each.value.data_disks
  name_overrides         = each.value.name_overrides
  severity_group         = each.value.severity_group
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
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.7.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | Password of the local administrator. | `string` | n/a | yes / or public_key |
| <a name="input_public_key"></a> [public\_key](#input\_public\_key) | Public SSH key of the local administrator. | `string` | n/a | yes / or admin_password |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where the resources will be created. | `string` | n/a | yes |
| <a name="input_subnet"></a> [subnet](#input\_subnet) | The variable takes the subnet as input and takes the id and the address prefix for further configuration. | <pre>object ({<br>    id = string<br>    address_prefixes = list(string)<br>  })</pre> | n/a | yes |
| <a name="input_virtual_machine_config"></a> [virtual\_machine\_config](#input\_virtual\_machine\_config) | <pre>size: The size of the vm. Possible values can be seen here: https://learn.microsoft.com/en-us/azure/virtual-machines/sizes<br>  os_sku: (Required) The os that will be running on the vm. Default: gen2. <br>      os_offer: (Required) Specifies the offer of the image used to create the virtual machines. Changing this forces a new resource to be created. Default: sles-15-sp4. <br>  os_publisher: (Required) Specifies the publisher of the image used to create the virtual machines. Changing this forces a new resource to be created. Default: SUSE.<br>  os_version: Optionally specify an os version for the chosen sku. Defaults: 2023.02.05.<br>  location: The location of the virtual machine.<br>  availability_set_id: Optionally specify an availibilty set for the vm.<br>  zone: Optionally specify an availibility zone for the vm.<br>  admin_username: Optionally choose the admin_username of the vm. Defaults to loc_sysadmin. <br>admin_ssh_key: <br>    The local admin name could be changed by the gpo in the target ad.<br>  os_disk_name: (Optional) The name which should be used for the Internal OS Disk. Changing this forces a new resource to be created. Default: OsDisk_01.<br>  os_disk_caching: Optionally change the caching option of the os disk. Defaults to ReadWrite.<br>  os_disk_storage_type: Optionally change the os_disk_storage_type. Defaults to StandardSSD_LRS.<br>  os_disk_size_gb: Optionally change the size of the os disk. Defaults to be specified by image.<br>  tags: Optionally specify tags in as a map.<br>  write_accelerator_enabled: Optionally activate write accelaration for the os disk. Can only<br>    be activated on Premium_LRS disks and caching deactivated. Defaults to false.</pre> | <pre>object({<br>      hostname = string<br>      size = string <br>      location = string<br>      os_sku = optional(string, "gen2")<br>      os_version                = optional(string, "2023.02.05") <br>      os_offer                  = optional(string, "sles-15-sp4") <br>      os_publisher              = optional(string, "SUSE") <br>      availability_set_id = optional(string)<br>      zone = optional(string)<br>      admin_username = optional(string, "loc_sysadmin") <br>      os_disk_name              = optional(string, "OsDisk_01") <br>      os_disk_caching = optional(string, "ReadWrite")<br>      os_disk_storage_type = optional(string, "StandardSSD_LRS")<br>      os_disk_size_gb = optional(number)<br>      tags = optional(map(string)) <br>      write_accelerator_enabled = optional(bool, false) <br>  })</pre> | n/a | yes |
| <a name="input_vm_name_as_disk_prefix"></a> [vm\_name\_as\_disk\_prefix](#input\_vm\_name\_as\_disk\_prefix) | Optional. Prefix name of VM for additional disks. Insert vm-<hostname>- as prefix disk name | `bool` | false | no |
| <a name="input_disk_prefix"></a> [disk\_prefix](#input\_disk\_prefix) | Optional. Prefix name for additional disks. | `string` | n/a | no |
| <a name="input_data_disks"></a> [data\_disks](#input\_data\_disks) | <pre><name of the data disk> = {<br>  lun: Number of the lun.<br>  disk_size_gb: The size of the data disk.<br>  tier: (Optional) The disk performance tier to use. Possible values are documented here. This feature is currently supported only for premium SSDs. <br>  storage_account_type: Optionally change the storage_account_type. Defaults to StandardSSD_LRS.<br>  caching: Optionally activate disk caching. Defaults to ReadWrite.<br>  create_option: Optionally change the create option. Defaults to Empty disk.<br>  write_accelerator_enabled: Optionally activate write accelaration for the data disk. Can only<br>    be activated on Premium_LRS disks and caching deactivated. Defaults to false.<br> }</pre> | <pre>map(object({<br>    lun                        = number<br>    disk_size_gb               = number<br>    tier                       = optional(string)<br>    storage_account_type       = optional(string, "StandardSSD_LRS")<br>    caching                    = optional(string, "ReadWrite")<br>    create_option              = optional(string, "Empty")<br>    write_accelerator_enabled  = optional(bool, false)<br>    on_demand_bursting_enabled = optional(bool, false)<br> }))</pre> | `{}` | no |
| <a name="input_log_analytics_agent"></a> [log\_analytics\_agent](#input\_log\_analytics\_agent) | <pre>Installs the log analytics agent(MicrosoftMonitoringAgent).<br>  workspace_id: Specify id of the log analytics workspace to which monitoring data will be sent.<br>  shared_key: The Primary shared key for the Log Analytics Workspace..</pre> | <pre>object({<br>    workspace_id = string<br>    primary_shared_key = string <br>  })</pre> | `null` | no |
| <a name="input_name_overrides"></a> [name\_overrides](#input\_name\_overrides) | Possibility to override names that will be generated according to q.beyond naming convention. | <pre>object({<br>      nic = optional(string)<br>      nic_ip_config = optional(string)<br>      public_ip = optional(string)<br>      virtual_machine = optional(string)<br>  })</pre> | `{}` | no |
| <a name="input_nic_config"></a> [nic\_config](#input\_nic\_config) | <pre>  private_ip: Optioanlly specify a private ip to use. Otherwise it will  be allocated dynamically.<br>  dns_servers: Optionally specify a list of dns servers for the nic.<br>  nsg_name: Optinally specify the name of a network security group that will be assigned to the nic.<br>  nsg_rg_name: Optinally specify the resource group name of a network security group that will be assigned to the nic.</pre> | <pre>object({<br>      private_ip = optional(string)<br>      dns_servers = optional(list(string))<br>      nsg_name    = optional(string)<br>      nsg_rg_name = optional(string)<br>      })</pre> | `{}` | no |
| <a name="input_public_ip_config"></a> [public\_ip\_config](#input\_public\_ip\_config) | <pre>enabled: Optionally select true if a public ip should be created. Defaults to false.<br>  allocation_method: The allocation method of the public ip that will be created. Defaults to static.</pre> | <pre>object({<br>      enabled = bool<br>      allocation_method = optional(string, "Static")<br>  })</pre> | <pre>{<br>  "enabled": false<br>}</pre> | no |
| <a name="input_severity_group"></a> [severity\_group](#input\_severity\_group) | The severity group of the virtual machine. | `string` | `""` | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_virtual_machine"></a> [virtual\_machine](#output\_virtual\_machine) | n/a |

## Resource types

| Type | Used |
|------|-------|
| [azurerm_managed_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | 1 |
| [azurerm_network_interface](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | 1 |
| [azurerm_network_interface_security_group_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | 1 |
| [azurerm_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | 1 |
| [azurerm_virtual_machine_data_disk_attachment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | 1 |
| [azurerm_virtual_machine_extension](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | 2 |
| [azurerm_linux_virtual_machine](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | 1 |

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
| [azurerm_virtual_machine_extension.dependencyagentlinux](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |

### main.tf

| Name | Type |
|------|------|
| [azurerm_network_interface.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_public_ip.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_linux_virtual_machine.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
<!-- END_TF_DOCS -->

## Contribute

Please use Pull requests to contribute.

When a new Feature or Fix is ready to be released, create a new Github release and adhere to [Semantic Versioning 2.0.0](https://semver.org/lang/de/spec/v2.0.0.html).