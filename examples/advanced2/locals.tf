locals {
  location                       = "West Europe"
  resource_group_name            = "rg-examples_vm_deploy-02"
  virtual_network_name           = "vnet-examples_vm_deploy-02"
  subnet_name                    = "snet-examples_vm_deploy-02"
  availability_set_name          = "as-examples_vm_deploy-02"
  proximity_placement_group_name = "ppg-examples_vm_deploy-02"
  nsg_name                       = "nsg-examples_vm_deploy-02"
  law_name                       = "law-examplesvmdeploy-02"

  ## VM DECLARATION.

  vm_ux_qby = {
    CUSTAPP001 = {
      resource_group_name              = azurerm_resource_group.this.name
      subnet                           = azurerm_subnet.this
      additional_network_interface_ids = [azurerm_network_interface.additional_nic_01.id]
      public_ip_config = {
        enabled           = false
        allocation_method = "Dynamic"
      }
      nic_config = {
        private_ip  = "10.0.0.16"
        dns_servers = ["10.0.0.10", "10.0.0.11"]
#        nsg         = azurerm_network_security_group.this
      }
      size                         = "Standard_B1ms"
      location                     = local.location
      zone                         = null # Could be the default value "1", or "2" or "3". Not compatible with availability_set_id enabled.
      admin_username               = "qbinstall"
      admin_password               = ""                 # Write a password if you need.
      public_key                   = file("id_rsa.pub") # If don't need rsa, leave empty with this "".
      os_sku                       = "gen2"
      os_offer                     = "sles-15-sp5"
      os_version                   = "2023.09.21"
      os_publisher                 = "SUSE"
      os_disk_name                 = "OsDisk_01"
      os_disk_caching              = "ReadWrite"
      os_disk_size_gb              = 64
      os_disk_storage_type         = "Premium_LRS"
      availability_set_id          = azurerm_availability_set.this.id # Not compatible with zone.
      proximity_placement_group_id = azurerm_proximity_placement_group.this.id
      write_accelerator_enabled    = false
      severity_group               = "01-third-tuesday-0200-XCSUFEDTG-reboot"
      update_allowed               = true
      log_analytics_agent          = azurerm_log_analytics_workspace.this

      # Tags
      tags = {}

      # Name override
      name_overrides = {
        nic             = "nic-examples_vm_CUSTAPP001"
        nic_ip_config   = "nic-ip-examples_vm_CUSTAPP001"
        public_ip       = "pip-examples_vm_CUSTAPP001"
        virtual_machine = "vm-CUSTAPP001"
      }

      ## DISK DECLARATION
      vm_name_as_disk_prefix    = true        # Insert vm-<hostname>- as prefix disk name
      disk_prefix               = "datadisk" # Is part of the prefix of the disk name. 'vm-<hostname>-<disk_prefix>-<data_disk_key>
      data_disks = {                         # 'vm-<hostname>' is added by the VM module.
        shared-01 = {                        # Examp. With disk prefix: vm-CUSTAPP001-datadisk-shared-01., Without: vm-CUSTAPP001-shared-01
          lun                        = 1     
          tier                       = "P4"
          caching                    = "ReadWrite"
          disk_size_gb               = 32
          create_option              = "Empty"
          storage_account_type       = "StandardSSD_LRS"
          write_accelerator_enabled  = false
          on_demand_bursting_enabled = false
        }
        sap-01 = {
          lun                        = 2
          tier                       = "P4"
          caching                    = "ReadWrite"
          disk_size_gb               = 32
          create_option              = "Empty"
          storage_account_type       = "Premium_LRS"
          write_accelerator_enabled  = false
          on_demand_bursting_enabled = false
        }
      }
    }
    CUSTAPP002 = {
      resource_group_name              = azurerm_resource_group.this.name
      subnet                           = azurerm_subnet.this
      additional_network_interface_ids = [azurerm_network_interface.additional_nic_02.id]
      public_ip_config = {
        enabled           = false
        allocation_method = "Dynamic"
      }
      nic_config = {
        private_ip  = "10.0.0.17"
        dns_servers = ["10.0.0.10", "10.0.0.11"]
#        nsg         = azurerm_network_security_group.this
      }
      size                         = "Standard_B1ms"
      location                     = local.location
      zone                         = null # Could be the default value "1", or "2" or "3". Not compatible with availability_set_id enabled.
      admin_username               = "qbinstall"
      admin_password               = ""                 # Write a password if you need.
      public_key                   = file("id_rsa.pub") # If don't need rsa, leave empty with this "".
      os_sku                       = "gen2"
      os_offer                     = "sles-15-sp5"
      os_version                   = "2023.09.21"
      os_publisher                 = "SUSE"
      os_disk_name                 = "OsDisk_01"
      os_disk_caching              = "ReadWrite"
      os_disk_size_gb              = 64
      os_disk_storage_type         = "Premium_LRS"
      availability_set_id          = azurerm_availability_set.this.id # Not compatible with zone.
      proximity_placement_group_id = azurerm_proximity_placement_group.this.id
      write_accelerator_enabled    = false
      severity_group               = ""
      update_allowed               = false
      log_analytics_agent          = azurerm_log_analytics_workspace.this
      
      # Tags
      tags = {}

      # Name overrides
      name_overrides = {}
      
      ## DISK DECLARATION
      vm_name_as_disk_prefix       = true        # Insert vm-<hostname>- as prefix disk name
      disk_prefix                  = "datadisk" # Is part of the prefix of the disk name. 'vm-<hostname>-<disk_prefix>-<data_disk_key>
      data_disks = {                         # 'vm-<hostname>' is added by the VM module.
        shared-01 = {                        # Examp. With disk prefix: vm-CUSTAPP001-datadisk-shared-01., Without: vm-CUSTAPP001-shared-01
          lun                        = 1     
          tier                       = "P4"
          caching                    = "ReadWrite"
          disk_size_gb               = 32
          create_option              = "Empty"
          storage_account_type       = "StandardSSD_LRS"
          write_accelerator_enabled  = false
          on_demand_bursting_enabled = false
        }
      }
    }
  }
}