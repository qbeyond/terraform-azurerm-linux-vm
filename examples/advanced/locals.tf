locals {
  location              = "West Europe"
  resource_group_name   = "rg-examples_vm_deploy-02"
  virtual_network_name  = "vnet-examples_vm_deploy-02"
  subnet_name           = "snet-examples_vm_deploy-02"
  availability_set_name = "as-examples_vm_deploy-02"
  nsg_name              = "nsg-examples_vm_deploy-02"
  law_name              = "law-examplesvmdeploy-02"

  nic                   = "nic-examples_vm_deploy-02"
  nic_ip_config         = "nic-ip-examples_vm_deploy-02"
  public_ip             = "pip-examples_vm_deploy-02"
  virtual_machine       = "vm-examples_vm_deploy-02"
}