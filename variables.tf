variable "public_ip_config" {
  type = object({
      enabled           = bool
      allocation_method = optional(string, "Static")
  })
  default = {
    enabled = false
  }
  validation {
    condition     =  contains(["Static","Dynamic"], var.public_ip_config.allocation_method)
    error_message = "Allocation method must be Static or Dynamic"
  }
  description = <<-DOC
  ```
    enabled: Optionally select true if a public ip should be created. Defaults to false.
    allocation_method: The allocation method of the public ip that will be created. Defaults to static.      
  ```
  DOC
} 

# nsg needs to be an object to use the count object in main.tf. 
variable "nic_config" {
  type = object({
    private_ip  = optional(string)
    dns_servers = optional(list(string))
    nsg = optional(object({
      id = string
    }))
  })
  default     = {}
  description = <<-DOC
  ```
    private_ip: Optioanlly specify a private ip to use. Otherwise it will  be allocated dynamically.
    dns_servers: Optionally specify a list of dns servers for the nic.
    nsg_id: Optinally specify the id of a network security group that will be assigned to the nic.    
  ```
  DOC
}

variable "subnet" {
  type               = object ({
    id               = string
    address_prefixes = list(string)
  })
  description = "The variable takes the subnet as input and takes the id and the address prefix for further configuration."
}

variable "virtual_machine_config" {
  type = object({
      hostname                  = string
      size                      = string
      location                  = string
      admin_username            = optional(string, "loc_sysadmin")
      os_sku                    = optional(string, "gen2")
      os_offer                  = optional(string, "sles-15-sp4")
      os_version                = optional(string, "2023.02.05")
      os_publisher              = optional(string, "SUSE")
      os_disk_name              = optional(string, "OsDisk_01")
      os_disk_caching           = optional(string, "ReadWrite")
      os_disk_size_gb           = optional(number, 64)
      os_disk_storage_type      = optional(string, "StandardSSD_LRS")
      zone                      = optional(string, "")
      availability_set_id       = optional(string)
      write_accelerator_enabled = optional(bool, false)
      tags                      = optional(map(string))
  })
  validation {
    condition     = contains(["None", "ReadOnly", "ReadWrite"], var.virtual_machine_config.os_disk_caching)
    error_message = "Possible values are None, ReadOnly and ReadWrite" 
  }
  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"],var.virtual_machine_config.os_disk_storage_type)
    error_message = "Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS"
  }
  validation {
    condition     = contains(["", "1", "2", "3"], var.virtual_machine_config.zone)
    error_message = "Possible values are null, 1, 2, or 3 per zone"
  }
  description = <<-DOC
  ```
    size: The size of the vm. Possible values can be seen here: https://learn.microsoft.com/en-us/azure/virtual-machines/sizes
    location: The location of the virtual machine.
    admin_username: Optionally choose the admin_username of the vm. Defaults to loc_sysadmin. 
      The local admin name could be changed by the gpo in the target ad.
    os_sku: The os that will be running on the vm.
    os_offer: (Required) Specifies the offer of the image used to create the virtual machines. Changing this forces a new resource to be created.
    os_version: Optionally specify an os version for the chosen sku. Defaults to latest.
    os_publisher: (Required) Specifies the Publisher of the Marketplace Image this Virtual Machine should be created from. Changing this forces a new resource to be created.
    os_disk_name: The name which should be used for the Internal OS Disk. Changing this forces a new resource to be created
    os_disk_caching: Optionally change the caching option of the os disk. Defaults to ReadWrite.
    os_disk_size_gb: Optionally change the size of the os disk. Defaults to be specified by image.
    os_disk_storage_type: Optionally change the os_disk_storage_type. Defaults to StandardSSD_LRS.
    zone: Optionally specify an availibility zone for the vm.
    availability_set_id: Optionally specify an availibilty set for the vm.
    write_accelerator_enabled: Optionally activate write accelaration for the os disk. Can only
      be activated on Premium_LRS disks and caching deactivated. Defaults to false.
    tags: Optionally specify tags in as a map.
  ```
  DOC
}

variable "severity_group" {
  type        = string
  default     = ""
  description = "The severity group of the virtual machine."
}

variable "update_allowed" {
  type        = bool
  default     = true
  description = "Set the tag `Update allowed`. `True` will set `yes`, `false` to `no`."
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Password of the local administrator."
  default     = ""
}

variable "public_key" {
  type        = string
  default     = ""
  description = "SSH public key file (e.g. file(id_rsa.pub)"
}

variable "vm_name_as_disk_prefix" {
  type        = bool
  default     = false
  description = "Insert vm-<hostname>- as prefix disk name."
}

variable "disk_prefix" {
  type        = string
  default     = ""
  description = "Optional. Prefix name for additional disks."
}

variable "data_disks" { # change to map of objects
  type = map(object({
    lun                        = number
    disk_size_gb               = number
    tier                       = optional(string)
    caching                    = optional(string, "ReadWrite")
    create_option              = optional(string, "Empty")
    storage_account_type       = optional(string, "StandardSSD_LRS")
    write_accelerator_enabled  = optional(bool, false)
    on_demand_bursting_enabled = optional(bool, false)
 }))
 validation {
   condition     = length([for v in var.data_disks : v.lun]) == length(distinct([for v in var.data_disks : v.lun]))
   error_message = "One or more of the lun parameters in the map are duplicates."
 }
  default = {}
  description = <<-DOC
  ```
   <name of the data disk> = {
    lun: Number of the lun.
    disk_size_gb: The size of the data disk.
    storage_account_type: Optionally change the storage_account_type. Defaults to StandardSSD_LRS.
    caching: Optionally activate disk caching. Defaults to None.
    create_option: Optionally change the create option. Defaults to Empty disk.
    write_accelerator_enabled: Optionally activate write accelaration for the data disk. Can only
      be activated on Premium_LRS disks and caching deactivated. Defaults to false.
   }
  ```
  DOC
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where the resources will be created."
}

variable "name_overrides" {
  type = object({
      nic             = optional(string)
      nic_ip_config   = optional(string)
      public_ip       = optional(string)
      virtual_machine = optional(string)
  })
  description = "Possibility to override names that will be generated according to q.beyond naming convention."
  default = {}
}

variable "log_analytics_agent" {
  type = object({
    workspace_id       = string
    primary_shared_key = string 
  })
  sensitive = true 
  default = null
  description = <<-DOC
  ```
    Installs the log analytics agent(MicrosoftMonitoringAgent).
    workspace_id: Specify id of the log analytics workspace to which monitoring data will be sent.
    shared_key: The Primary shared key for the Log Analytics Workspace..
  ```
  DOC
}