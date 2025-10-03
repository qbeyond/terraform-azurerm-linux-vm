variable "public_ip_config" {
  type = object({
    allocation_method = optional(string, "Static")
    stage             = string
    sku               = optional(string, "Standard")
  })
  default = null
  validation {
    condition     = var.public_ip_config != null ? contains(["Static", "Dynamic"], var.public_ip_config.allocation_method) : true
    error_message = "Allocation method must be Static or Dynamic"
  }

  validation {
    condition = (
      var.public_ip_config == null || 
      var.virtual_machine_config.zone == null || 
      var.public_ip_config.sku == "Standard"
    )
    error_message = "If a zone is specified, the Public IP SKU must be set to 'Standard'."
  }
  description = <<-DOC
  ```
    allocation_method: The allocation method of the public ip that will be created. Defaults to static.
    stage: The stage of this PIP. Ex: prd, dev, tst, ...
    sku: Optionally specify the sku of the public ip. Defaults to Standard.
  ```
  DOC
}

variable "additional_ip_configurations" {
  type = map(object({
    private_ip           = optional(string)
    public_ip_address_id = optional(string)
  }))
  default     = {}
  nullable    = false
  description = "List of additional ip configurations for a nic."

}

# nsg needs to be an object to use the count object in main.tf. 
variable "nic_config" {
  type = object({
    private_ip                    = optional(string)
    dns_servers                   = optional(list(string))
    enable_accelerated_networking = optional(bool, false)
    asg = optional(object({
      id = string
    }))
    nsg = optional(object({
      id = string
    }))
  })
  default     = {}
  nullable    = false
  description = <<-DOC
  ```
    private_ip: Optionally specify a private ip to use. Otherwise it will  be allocated dynamically.
    dns_servers: Optionally specify a list of dns servers for the nic.
    enable_accelerated_networking: Enabled Accelerated networking (SR-IOV) on the NIC. The machine SKU must support this feature.
    nsg: Although it is discouraged you can optionally assign an NSG to the NIC. Optionally specify a NSG object.
    asg: Optionally specify an application security group for the nic.
  ```
  DOC
}

variable "additional_network_interface_ids" {
  type        = list(string)
  default     = []
  nullable    = false
  description = "List of ids for additional azurerm_network_interface."
}

variable "subnet" {
  type = object({
    id               = string
    address_prefixes = optional(list(string), null)
  })
  nullable    = false
  description = <<-DOC
  ```
    The variable takes the subnet as input and takes the id and the address prefix for further configuration.
    Note: If no address prefix is provided, the information is being extracted from the id.
  ```
  DOC
  validation {
    condition     = var.subnet.address_prefixes == null ? can(regex(".*subnets/snet-[0-9-]+-.*$", var.subnet.id)) : true
    error_message = "If no address prefix is specified, the name of the subnet must match the naming convention."
  }
}

variable "admin_username" {
  type        = string
  default     = "loc_sysadmin"
  nullable    = false
  description = "Optionally choose the admin_username of the vm. Defaults to loc_sysadmin."
}

variable "admin_credential" {
  type = object({
    admin_password = optional(string)
    public_key     = optional(string)
  })

  validation {
    condition     = (var.admin_credential.admin_password != null && var.admin_credential.public_key == null) || (var.admin_credential.admin_password == null && var.admin_credential.public_key != null)
    error_message = "Use admin password or public ssh key."
  }
  sensitive   = true
  description = <<-DOC
  ```
    Specify either admin_password or public_key:
    admin_password: Password of the local administrator.
    public_key: SSH public key file (e.g. file(id_rsa.pub))
  ```
  DOC
}

variable "update_settings" {
  type = object({
    bypass_platform_safety_checks_on_user_schedule_enabled = optional(bool, true)                    # will be set to false in den vm code when patch_mode is set to ImageDefault
    patch_mode                                             = string                                  # can also be AutomaticByPlatform
    patch_assessment_mode                                  = optional(string, "AutomaticByPlatform") # provision_vm_agent is set to true in code by default
    reboot_setting                                         = optional(string, "Never")               # reboot setting is declared in the maintenance configuration
  })
  default = {
    patch_mode = "ImageDefault"
  }
  description = <<-DOC
  ```
    Provides options on update management:
    For automated update management by Azure you'd want to set patch_mode to AutomaticByPlatform and keep the defaults.
  ```
  DOC
}


variable "virtual_machine_config" {
  type = object({
    hostname                          = string
    size                              = string
    location                          = string
    os_sku                            = string
    os_offer                          = string
    os_version                        = string
    os_publisher                      = string
    os_disk_caching                   = optional(string, "ReadWrite")
    os_disk_size_gb                   = optional(number)
    os_disk_storage_type              = optional(string, "Premium_LRS")
    os_disk_write_accelerator_enabled = optional(bool, false)
    zone                              = optional(string)
    availability_set_id               = optional(string)
    proximity_placement_group_id      = optional(string)
    severity_group                    = string
    update_allowed                    = optional(bool, true)
    enable_plan                       = optional(bool, false)
  })
  validation {
    condition     = contains(["None", "ReadOnly", "ReadWrite"], var.virtual_machine_config.os_disk_caching)
    error_message = "Possible values are None, ReadOnly and ReadWrite for os_disk_caching."
  }
  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"], var.virtual_machine_config.os_disk_storage_type)
    error_message = "Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS for os_disk_storage_type."
  }
  validation {
    condition = (
      var.virtual_machine_config.os_disk_write_accelerator_enabled == true &&
      contains(["Premium_LRS", "Premium_ZRS"], var.virtual_machine_config.os_disk_storage_type) &&
      contains(["None", "ReadOnly"], var.virtual_machine_config.os_disk_caching)
      ) || (
      var.virtual_machine_config.os_disk_write_accelerator_enabled == false
    )
    error_message = "os_disk_write_accelerator_enabled can only be activated on Premium disks and caching deactivated."
  }
  validation {
    condition     = var.virtual_machine_config.zone == null || var.virtual_machine_config.zone == "1" || var.virtual_machine_config.zone == "2" || var.virtual_machine_config.zone == "3"
    error_message = "Zone, can only be empty, 1, 2 or 3."
  }
  validation {
    condition     = var.virtual_machine_config.zone != null ? var.virtual_machine_config.availability_set_id == null : true
    error_message = "Either 'zone' or 'availability_set_id' can be set, but not both."
  }

  nullable    = false
  description = <<-DOC
  ```
    hostname: Name of system hostname.
    size: The size of the vm. Possible values can be seen here: https://learn.microsoft.com/en-us/azure/virtual-machines/sizes
    location: The location of the virtual machine.
    os_sku: (Required) The os that will be running on the vm.
    os_offer: (Required) Specifies the offer of the image used to create the virtual machines. Changing this forces a new resource to be created.
    os_version: (Required) Optionally specify an os version for the chosen sku.
    os_publisher: (Required) Specifies the Publisher of the Marketplace Image this Virtual Machine should be created from. Changing this forces a new resource to be created.
    os_disk_caching: Optionally change the caching option of the os disk. Defaults to ReadWrite.
    os_disk_size_gb: Optionally change the size of the os disk. Defaults to be specified by image.
    os_disk_storage_type: Optionally change the os_disk_storage_type. Defaults to StandardSSD_LRS.
    zone: Optionally specify an availibility zone for the vm. Values 1, 2 or 3.
    availability_set_id: Optionally specify an availibility set for the vm. Not compatible with zone.
    os_disk_write_accelerator_enabled: Optionally activate write accelaration for the os disk. Can only
      be activated on Premium disks and caching deactivated. Defaults to false.
    proximity_placement_group_id: (Optional) The ID of the Proximity Placement Group which the Virtual Machine should be assigned to.
    severity_group: (Required) Sets tag 'Severity Group Monthly' to a specific time and date when an update will be done automatically.
    update_allowed: Sets tag 'Update allowed' to yes or no to specify if this VM should currently receive updates.
    enable_plan: When using marketplace images, sending plan information might be required. Also accepts the terms of the marketplace product.
  ```
  DOC
}

variable "data_disks" {
  type = map(object({
    lun                        = number
    disk_size_gb               = number
    caching                    = optional(string, "ReadWrite")
    create_option              = optional(string, "Empty")
    source_resource_id         = optional(string)
    storage_account_type       = optional(string, "Premium_LRS")
    write_accelerator_enabled  = optional(bool, false)
    on_demand_bursting_enabled = optional(bool, false)
    disk_iops_read_write       = optional(number)
    disk_mbps_read_write       = optional(number)
    disk_iops_read_only        = optional(number)
    disk_mbps_read_only        = optional(number)
    max_shares                 = optional(number)
    tags                       = optional(map(string), null)
  }))
  validation {
    condition     = length([for v in var.data_disks : v.lun]) == length(distinct([for v in var.data_disks : v.lun]))
    error_message = "One or more of the lun parameters in the map are duplicates."
  }
  validation {
    condition     = alltrue([for o in var.data_disks : contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS", "PremiumV2_LRS", "UltraSSD_LRS"], o.storage_account_type)])
    error_message = "Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS, Premium_ZRS, PremiumV2_LRS and UltraSSD_LRS for storage_account_type"
  }
  validation {
    condition = alltrue([
      for disk in var.data_disks : (
        disk.on_demand_bursting_enabled == false ||
        disk.disk_size_gb > 512
      )
    ])
    error_message = "on_demand_bursting_enabled` can only be set to true when `disk_size_gb` is larger than 512GB."
  }
  validation {
    condition = alltrue([for o in var.data_disks : (
      (o.write_accelerator_enabled == true && contains(["Premium_LRS", "Premium_ZRS"], o.storage_account_type) && contains(["None"], o.caching)) ||
      (o.write_accelerator_enabled == false)
    )])
    error_message = "write_accelerator_enabled, can only be activated on Premium disks and caching deactivated."
  }
  validation {
    condition = alltrue([for o in var.data_disks : (
      (o.on_demand_bursting_enabled == true && contains(["Premium_LRS", "Premium_ZRS"], o.storage_account_type)) ||
      (o.on_demand_bursting_enabled == false)
    )])
    error_message = "If enable on demand bursting, possible storage_account_type values are Premium_LRS, Premium_ZRS"
  }
  validation {
    condition = alltrue([
      for v in var.data_disks :
      (
        (v.storage_account_type != "PremiumV2_LRS") ||
        (var.virtual_machine_config.zone != null)
      )
    ])
    error_message = "PremiumV2_LRS storage_account_type requires zone to be set. Please set zone to 1, 2 or 3."
  }
  validation {
    condition = (
      length(distinct([
        for v in var.data_disks : var.virtual_machine_config.zone
      ])) <= 1
    )
    error_message = "All disks must be in the same zone or zone must be empty."
  }
  validation {
    condition = alltrue([
      for v in var.data_disks :
      (
        !(v.storage_account_type == "PremiumV2_LRS" || v.storage_account_type == "UltraSSD_LRS") ||
        (v.caching == "None")
      )
    ])
    error_message = "When storage_account_type is 'PremiumV2_LRS' or 'UltraSSD_LRS', caching must be set to 'None'."
  }
  validation {
    condition     = alltrue([for k, v in var.data_disks : !strcontains(k, "-")])
    error_message = "Logical Name can't contain a '-'"
  }
  validation {
    condition = alltrue([for o in var.data_disks : (
      (o.source_resource_id != null && contains(["Copy", "Restore"], o.create_option) || (o.create_option == "Empty" && o.source_resource_id == null))
    )])
    error_message = "When a data disk source resource ID is specified then create option must be either 'Copy' or 'Restore'."
  }
  validation {
    condition = alltrue([
      for o in var.data_disks : (
        (
          o.disk_iops_read_write == null &&
          o.disk_mbps_read_write == null &&
          o.disk_iops_read_only == null &&
          o.disk_mbps_read_only == null
          ) || (
          contains(["UltraSSD_LRS", "PremiumV2_LRS"], o.storage_account_type)
        )
      )
    ])
    error_message = "disk_iops_read_write, disk_mbps_read_write, disk_iops_read_only and disk_mbps_read_only can only be set for UltraSSD_LRS or PremiumV2_LRS storage account types."
  }
  validation {
    condition = alltrue([
      for o in var.data_disks : (
        (
          o.disk_iops_read_only == null && o.disk_mbps_read_only == null
          ) || (
          contains(["UltraSSD_LRS", "PremiumV2_LRS"], o.storage_account_type) &&
          o.max_shares != null &&
          o.max_shares > 1 &&
          o.max_shares <= 10
        )
      )
    ])
    error_message = "disk_iops_read_only and disk_mbps_read_only can only be set for UltraSSD_LRS or PremiumV2_LRS disks with shared disk enabled (max_shares between 2 and 10)."
  }
  validation {
    condition = alltrue([
      for o in var.data_disks :
      o.storage_account_type == "UltraSSD_LRS" ? var.virtual_machine_config.availability_set_id == null : true
    ])
    error_message = "UltraSSD_LRS is not supported when 'availability_set_id' is set."
  }
  validation {
    condition = alltrue([
      for o in var.data_disks : (
        (o.disk_iops_read_write == null ? true : (o.disk_iops_read_write >= 3000 && o.disk_iops_read_write <= 64000)) &&
        (o.disk_iops_read_only == null ? true : (o.disk_iops_read_only >= 3000 && o.disk_iops_read_only <= 64000))
      )
    ])
    error_message = "disk_iops_read_write and disk_iops_read_only must be between 3000 and 64000 if set."
  }
  validation {
    condition = alltrue([
      for o in var.data_disks : (
        (o.disk_mbps_read_write == null ? true : (o.disk_mbps_read_write >= 125 && o.disk_mbps_read_write <= 750)) &&
        (o.disk_mbps_read_only == null ? true : (o.disk_mbps_read_only >= 125 && o.disk_mbps_read_only <= 750))
      )
    ])
    error_message = "disk_mbps_read_write and disk_mbps_read_only must be between 125 and 750 if set."
  }
  validation {
    condition = alltrue([
      for v in var.data_disks :
      (
        v.storage_account_type != "UltraSSD_LRS" ? true :
        try(var.virtual_machine_config.additional_capabilities.ultra_ssd_enabled, false)
      )
    ])
    error_message = "If UltraSSD_LRS is used in data_disks, ultra_ssd_enabled must be set to true in additional_capabilities."
  }

  default     = {}
  nullable    = false
  description = <<-DOC
  ```
   `<logical name of the data disk>` = {
    lun: Number of the lun.
    disk_size_gb: The size of the data disk.
    storage_account_type: Optionally change the storage_account_type. Defaults to StandardSSD_LRS.
    caching: Optionally activate disk caching. Defaults to None.
    create_option: Optionally change the create option. Defaults to Empty disk.
    source_resource_id: (Optional) The ID of an existing Managed Disk or Snapshot to copy when create_option is Copy or
      the recovery point to restore when create_option is Restore. Changing this forces a new resource to be created.
    write_accelerator_enabled: Optionally activate write accelaration for the data disk. Can only
      be activated on Premium disks and caching deactivated. Defaults to false.
    on_demand_bursting_enabled: Optionally activate disk bursting. Only for Premium disk with size to 512 Gb up. Default false.
    disk_iops_read_write: (Optional) The maximum number of IOPS allowed for the disk in read/write operations.
    disk_mbps_read_write: (Optional) The maximum number of MBps allowed for the disk in read/write operations.
    disk_iops_read_only: (Optional) The maximum number of IOPS allowed for the disk in read-only operations.
    disk_mbps_read_only: (Optional) The maximum number of MBps allowed for the disk in read-only operations.
    max_shares: (Optional) The maximum number of VMs that can share this disk. Only for UltraSSD_LRS and PremiumV2_LRS disks.
   }
  ```
  DOC
}

variable "resource_group_name" {
  type        = string
  nullable    = false
  description = "Name of the resource group where the resources will be created."
}

variable "name_overrides" {
  type = object({
    nic             = optional(string)
    nic_ip_config   = optional(string)
    public_ip       = optional(string)
    virtual_machine = optional(string)
    os_disk         = optional(string)
    data_disks      = optional(map(string), {})
  })
  default     = {}
  nullable    = false
  description = "Possibility to override names that will be generated according to q.beyond naming convention."
}

variable "tags" {
  type        = map(string)
  default     = {}
  nullable    = false
  description = "A map of tags that will be set on every resource this module creates."
}

variable "disk_encryption" {
  description = <<-DOC
  Configuration for Azure Disk Encryption extension. When null, no ADE extension is created.
  publisher: (Optional) The publisher of the Azure Disk Encryption extension. Defaults to "Microsoft.Azure.Security".
  type: (Optional) The type of the Azure Disk Encryption extension. Defaults to "AzureDiskEncryptionForLinux".
  type_handler_version: (Optional) The version of the Azure Disk Encryption extension handler. Defaults to "1.1".
  auto_upgrade_minor_version: (Optional) Indicates whether the extension should be automatically upgraded to the latest minor version when it's available. Defaults to true.
  settings: Configuration object for disk encryption settings.
    EncryptionOperation: (Optional) The operation to perform. Defaults to "EnableEncryption".
    KeyEncryptionAlgorithm: (Optional) The algorithm used for key encryption. Defaults to "RSA-OAEP".
    KeyVaultURL: The URL of the Key Vault to use for encryption.
    KeyVaultResourceId: The resource ID of the Key Vault to use for encryption.
    KeyEncryptionKeyURL: The URL of the Key Encryption Key in the Key Vault.
    KekVaultResourceId: The resource ID of the Key Encryption Key Vault.
    VolumeType: (Optional) The type of volume to encrypt. Possible values are "All", "OS", or "Data". Defaults to "All".
  DOC

  type = object({
    publisher                  = optional(string, "Microsoft.Azure.Security")
    type                       = optional(string, "AzureDiskEncryptionForLinux")
    type_handler_version       = optional(string, "1.1")
    auto_upgrade_minor_version = optional(bool, true)
    settings = object({
      EncryptionOperation    = optional(string, "EnableEncryption")
      KeyEncryptionAlgorithm = optional(string, "RSA-OAEP")
      KeyVaultURL            = string
      KeyVaultResourceId     = string
      KeyEncryptionKeyURL    = string
      KekVaultResourceId     = string
      VolumeType             = optional(string, "All")
    })
  })

  validation {
    condition     = contains(["All", "OS", "Data"], try(var.disk_encryption.settings.VolumeType, "All"))
    error_message = "VolumeType must be one of 'All', 'OS', or 'Data'."
  }

  validation {
    condition     = var.disk_encryption == null || var.disk_encryption.settings.KeyVaultURL != ""
    error_message = "KeyVaultURL must be specified when disk_encryption is not null."
  }

  default = null
}
