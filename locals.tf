locals {
  public_ip = {
    name = coalesce(var.name_overrides.public_ip, "pip-${var.stage}-${var.virtual_machine_config.hostname}-01-${var.virtual_machine_config.location}")
  }

  nic = {
    name           = coalesce(var.name_overrides.nic, "nic-${var.virtual_machine_config.hostname}-${replace(var.subnet.address_prefixes[0], "/[./]/", "-")}")
    ip_config_name = coalesce(var.name_overrides.nic_ip_config, "internal")
  }

  virtual_machine = {
    name = coalesce(var.name_overrides.virtual_machine, "vm-${var.virtual_machine_config.hostname}")
    tags = merge(var.tags, { "Severity Group Monthly" = var.virtual_machine_config.severity_group,  "Update allowed" = local.update_allowed })
  }
  os_disk_name   = coalesce(var.name_overrides.os_disk, "disk-${var.virtual_machine_config.hostname}-Os")
  update_allowed = var.update_allowed ? "yes" : "no"
}