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
          lun                       = 1     
          tier                      = "P4"
          caching                   = "ReadWrite"
          disk_size_gb              = 32
          create_option             = "Empty"
          storage_account_type      = "StandardSSD_LRS"
          write_accelerator_enabled = false
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