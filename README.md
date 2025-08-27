# Linux VM
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
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.5.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_credential"></a> [admin\_credential](#input\_admin\_credential) | <pre>Specify either admin_password or public_key:<br/>  admin_password: Password of the local administrator.<br/>  public_key: SSH public key file (e.g. file(id_rsa.pub))</pre> | <pre>object({<br/>    admin_password = optional(string)<br/>    public_key     = optional(string)<br/>  })</pre> | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where the resources will be created. | `string` | n/a | yes |
| <a name="input_subnet"></a> [subnet](#input\_subnet) | <pre>The variable takes the subnet as input and takes the id and the address prefix for further configuration.<br/>  Note: If no address prefix is provided, the information is being extracted from the id.</pre> | <pre>object({<br/>    id               = string<br/>    address_prefixes = optional(list(string), null)<br/>  })</pre> | n/a | yes |
| <a name="input_virtual_machine_config"></a> [virtual\_machine\_config](#input\_virtual\_machine\_config) | <pre>hostname: Name of system hostname.<br/>  size: The size of the vm. Possible values can be seen here: https://learn.microsoft.com/en-us/azure/virtual-machines/sizes<br/>  location: The location of the virtual machine.<br/>  os_sku: (Required) The os that will be running on the vm.<br/>  os_offer: (Required) Specifies the offer of the image used to create the virtual machines. Changing this forces a new resource to be created.<br/>  os_version: (Required) Optionally specify an os version for the chosen sku.<br/>  os_publisher: (Required) Specifies the Publisher of the Marketplace Image this Virtual Machine should be created from. Changing this forces a new resource to be created.<br/>  os_disk_caching: Optionally change the caching option of the os disk. Defaults to ReadWrite.<br/>  os_disk_size_gb: Optionally change the size of the os disk. Defaults to be specified by image.<br/>  os_disk_storage_type: Optionally change the os_disk_storage_type. Defaults to StandardSSD_LRS.<br/>  zone: Optionally specify an availibility zone for the vm. Values 1, 2 or 3.<br/>  availability_set_id: Optionally specify an availibility set for the vm. Not compatible with zone.<br/>  os_disk_write_accelerator_enabled: Optionally activate write accelaration for the os disk. Can only<br/>    be activated on Premium disks and caching deactivated. Defaults to false.<br/>  proximity_placement_group_id: (Optional) The ID of the Proximity Placement Group which the Virtual Machine should be assigned to.<br/>  severity_group: (Required) Sets tag 'Severity Group Monthly' to a specific time and date when an update will be done automatically.<br/>  update_allowed: Sets tag 'Update allowed' to yes or no to specify if this VM should currently receive updates.<br/>  enable_plan: When using marketplace images, sending plan information might be required. Also accepts the terms of the marketplace product.</pre> | <pre>object({<br/>    hostname                          = string<br/>    size                              = string<br/>    location                          = string<br/>    os_sku                            = string<br/>    os_offer                          = string<br/>    os_version                        = string<br/>    os_publisher                      = string<br/>    os_disk_caching                   = optional(string, "ReadWrite")<br/>    os_disk_size_gb                   = optional(number)<br/>    os_disk_storage_type              = optional(string, "Premium_LRS")<br/>    os_disk_write_accelerator_enabled = optional(bool, false)<br/>    zone                              = optional(string)<br/>    availability_set_id               = optional(string)<br/>    proximity_placement_group_id      = optional(string)<br/>    severity_group                    = string<br/>    update_allowed                    = optional(bool, true)<br/>    enable_plan                       = optional(bool, false)<br/>  })</pre> | n/a | yes |
| <a name="input_additional_ip_configurations"></a> [additional\_ip\_configurations](#input\_additional\_ip\_configurations) | List of additional ip configurations for a nic. | <pre>map(object({<br/>    private_ip           = optional(string)<br/>    public_ip_address_id = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_additional_network_interface_ids"></a> [additional\_network\_interface\_ids](#input\_additional\_network\_interface\_ids) | List of ids for additional azurerm\_network\_interface. | `list(string)` | `[]` | no |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | Optionally choose the admin\_username of the vm. Defaults to loc\_sysadmin. | `string` | `"loc_sysadmin"` | no |
| <a name="input_data_disks"></a> [data\_disks](#input\_data\_disks) | <pre>`<logical name of the data disk>` = {<br/>  lun: Number of the lun.<br/>  disk_size_gb: The size of the data disk.<br/>  storage_account_type: Optionally change the storage_account_type. Defaults to StandardSSD_LRS.<br/>  caching: Optionally activate disk caching. Defaults to None.<br/>  create_option: Optionally change the create option. Defaults to Empty disk.<br/>  source_resource_id: (Optional) The ID of an existing Managed Disk or Snapshot to copy when create_option is Copy or<br/>    the recovery point to restore when create_option is Restore. Changing this forces a new resource to be created.<br/>  write_accelerator_enabled: Optionally activate write accelaration for the data disk. Can only<br/>    be activated on Premium disks and caching deactivated. Defaults to false.<br/>  on_demand_bursting_enabled: Optionally activate disk bursting. Only for Premium disk with size to 512 Gb up. Default false.<br/>  disk_iops_read_write: (Optional) The maximum number of IOPS allowed for the disk in read/write operations.<br/>  disk_mbps_read_write: (Optional) The maximum number of MBps allowed for the disk in read/write operations.<br/>  disk_iops_read_only: (Optional) The maximum number of IOPS allowed for the disk in read-only operations.<br/>  disk_mbps_read_only: (Optional) The maximum number of MBps allowed for the disk in read-only operations.<br/>  max_shares: (Optional) The maximum number of VMs that can share this disk. Only for UltraSSD_LRS and PremiumV2_LRS disks.<br/> }</pre> | <pre>map(object({<br/>    lun                        = number<br/>    disk_size_gb               = number<br/>    caching                    = optional(string, "ReadWrite")<br/>    create_option              = optional(string, "Empty")<br/>    source_resource_id         = optional(string)<br/>    storage_account_type       = optional(string, "Premium_LRS")<br/>    write_accelerator_enabled  = optional(bool, false)<br/>    on_demand_bursting_enabled = optional(bool, false)<br/>    disk_iops_read_write       = optional(number)<br/>    disk_mbps_read_write       = optional(number)<br/>    disk_iops_read_only        = optional(number)<br/>    disk_mbps_read_only        = optional(number)<br/>    max_shares                 = optional(number)<br/>  }))</pre> | `{}` | no |
| <a name="input_disk_encryption"></a> [disk\_encryption](#input\_disk\_encryption) | Configuration for Azure Disk Encryption extension. When null, no ADE extension is created.<br/>publisher: (Optional) The publisher of the Azure Disk Encryption extension. Defaults to "Microsoft.Azure.Security".<br/>type: (Optional) The type of the Azure Disk Encryption extension. Defaults to "AzureDiskEncryptionForLinux".<br/>type\_handler\_version: (Optional) The version of the Azure Disk Encryption extension handler. Defaults to "1.1".<br/>auto\_upgrade\_minor\_version: (Optional) Indicates whether the extension should be automatically upgraded to the latest minor version when it's available. Defaults to true.<br/>settings: Configuration object for disk encryption settings.<br/>  EncryptionOperation: (Optional) The operation to perform. Defaults to "EnableEncryption".<br/>  KeyEncryptionAlgorithm: (Optional) The algorithm used for key encryption. Defaults to "RSA-OAEP".<br/>  KeyVaultURL: The URL of the Key Vault to use for encryption.<br/>  KeyVaultResourceId: The resource ID of the Key Vault to use for encryption.<br/>  KeyEncryptionKeyURL: The URL of the Key Encryption Key in the Key Vault.<br/>  KekVaultResourceId: The resource ID of the Key Encryption Key Vault.<br/>  VolumeType: (Optional) The type of volume to encrypt. Possible values are "All", "OS", or "Data". Defaults to "All". | <pre>object({<br/>    publisher                  = optional(string, "Microsoft.Azure.Security")<br/>    type                       = optional(string, "AzureDiskEncryptionForLinux")<br/>    type_handler_version       = optional(string, "1.1")<br/>    auto_upgrade_minor_version = optional(bool, true)<br/>    settings = object({<br/>      EncryptionOperation    = optional(string, "EnableEncryption")<br/>      KeyEncryptionAlgorithm = optional(string, "RSA-OAEP")<br/>      KeyVaultURL            = string<br/>      KeyVaultResourceId     = string<br/>      KeyEncryptionKeyURL    = string<br/>      KekVaultResourceId     = string<br/>      VolumeType             = optional(string, "All")<br/>    })<br/>  })</pre> | `null` | no |
| <a name="input_name_overrides"></a> [name\_overrides](#input\_name\_overrides) | Possibility to override names that will be generated according to q.beyond naming convention. | <pre>object({<br/>    nic             = optional(string)<br/>    nic_ip_config   = optional(string)<br/>    public_ip       = optional(string)<br/>    virtual_machine = optional(string)<br/>    os_disk         = optional(string)<br/>    data_disks      = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_nic_config"></a> [nic\_config](#input\_nic\_config) | <pre>private_ip: Optionally specify a private ip to use. Otherwise it will  be allocated dynamically.<br/>  dns_servers: Optionally specify a list of dns servers for the nic.<br/>  enable_accelerated_networking: Enabled Accelerated networking (SR-IOV) on the NIC. The machine SKU must support this feature.<br/>  nsg: Although it is discouraged you can optionally assign an NSG to the NIC. Optionally specify a NSG object.<br/>  asg: Optionally specify an application security group for the nic.</pre> | <pre>object({<br/>    private_ip                    = optional(string)<br/>    dns_servers                   = optional(list(string))<br/>    enable_accelerated_networking = optional(bool, false)<br/>    asg = optional(object({<br/>      id = string<br/>    }))<br/>    nsg = optional(object({<br/>      id = string<br/>    }))<br/>  })</pre> | `{}` | no |
| <a name="input_public_ip_config"></a> [public\_ip\_config](#input\_public\_ip\_config) | <pre>allocation_method: The allocation method of the public ip that will be created. Defaults to static.<br/>  stage: The stage of this PIP. Ex: prd, dev, tst, ...<br/>  sku: Optionally specify the sku of the public ip. Defaults to Standard.</pre> | <pre>object({<br/>    allocation_method = optional(string, "Static")<br/>    stage             = string<br/>    sku               = optional(string, "Standard")<br/>  })</pre> | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags that will be set on every resource this module creates. | `map(string)` | `{}` | no |
| <a name="input_update_settings"></a> [update\_settings](#input\_update\_settings) | <pre>Provides options on update management:<br/>  For automated update management by Azure you'd want to set patch_mode to AutomaticByPlatform and keep the defaults.</pre> | <pre>object({<br/>    bypass_platform_safety_checks_on_user_schedule_enabled = optional(bool, true)                    # will be set to false in den vm code when patch_mode is set to ImageDefault<br/>    patch_mode                                             = string                                  # can also be AutomaticByPlatform<br/>    patch_assessment_mode                                  = optional(string, "AutomaticByPlatform") # provision_vm_agent is set to true in code by default<br/>    reboot_setting                                         = optional(string, "Never")               # reboot setting is declared in the maintenance configuration<br/>  })</pre> | <pre>{<br/>  "patch_mode": "ImageDefault"<br/>}</pre> | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data_disks"></a> [data\_disks](#output\_data\_disks) | n/a |
| <a name="output_network_interface"></a> [network\_interface](#output\_network\_interface) | n/a |
| <a name="output_virtual_machine"></a> [virtual\_machine](#output\_virtual\_machine) | n/a |

      ## Resource types

      | Type | Used |
      |------|-------|
        | [azurerm_linux_virtual_machine](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | 1 |
        | [azurerm_managed_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | 1 |
        | [azurerm_marketplace_agreement](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/marketplace_agreement) | 1 |
        | [azurerm_network_interface](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | 1 |
        | [azurerm_network_interface_application_security_group_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_application_security_group_association) | 1 |
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

            ### main.tf

            | Name | Type |
            |------|------|
                  | [azurerm_linux_virtual_machine.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
                  | [azurerm_marketplace_agreement.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/marketplace_agreement) | resource |
                  | [azurerm_network_interface.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
                  | [azurerm_network_interface_application_security_group_association.additional_nics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_application_security_group_association) | resource |
                  | [azurerm_network_interface_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
                  | [azurerm_public_ip.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
                  | [azurerm_virtual_machine_extension.disk_encryption](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
                  | [azurerm_virtual_machine_extension.python_setup](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
    
<!-- END_TF_DOCS -->

## Contribute

Please use Pull requests to contribute.

When a new Feature or Fix is ready to be released, create a new Github release and adhere to [Semantic Versioning 2.0.0](https://semver.org/lang/de/spec/v2.0.0.html).