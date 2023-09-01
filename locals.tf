locals {
  public_ip = {
      name = coalesce(var.name_overrides.public_ip, "pip-vm-${var.virtual_machine_config.hostname}") # change to naming convention= 
  }

  nic = {
      name = coalesce(var.name_overrides.nic, "nic-${var.virtual_machine_config.hostname}-${replace(var.subnet.address_prefixes[0], "/[./]/", "-")}")
      ip_config_name = coalesce(var.name_overrides.nic_ip_config, "internal")
  }

  virtual_machine = {
      name = coalesce(var.name_overrides.virtual_machine, "vm-${var.virtual_machine_config.hostname}")
  }
}

