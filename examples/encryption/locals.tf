locals {
  location             = "West Europe"
  resource_group_name  = "rg-example-linux-vm-encryption"
  virtual_network_name = "vnet-example-linux-vm-encryption"
  subnet_name          = "snet-example-linux-vm-encryption"

  key_vault_name = "kv-exp-linux-vm-encr"
  key_name       = "key-exp-linux-vm-encr"
}
