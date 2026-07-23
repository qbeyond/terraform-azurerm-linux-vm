# Changelog

All notable changes to this module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this module adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [5.2.0] - 2026-07-15

### Added

- Added `additional_ip_configurations` variable to allow adding multiple IP configurations to the NIC.
- The default ip configuratin has been renamed from `internal` to `primary-ip-configuration`. To use this and all following versions with existing deployments the `name_overrides` variable needs to be used. Checkout the advanced example.

### Fixed

- Fixed a bug for custom_data, by adding a new variable named custom_data_path

## [5.1.1] - 2026-07-08

### Added

- Added new validation for stage variable in public ip

### Fixed

- Fixed a bug in the public ip

## [5.1.0] - 2026-07-03

### Added

- Added new validation and a new variable called "enabled" to the public IP. Now it is the same as in the windows module

### Fixed

- Fixed a bug in the advanced module

## [5.0.0] - 2026-06-09

### Removed

- Removed Azure Disk Encryption (ADE) support. ADE is scheduled for retirement on September 15, 2028 ([Microsoft retirement notice](https://learn.microsoft.com/en-us/azure/virtual-machines/disk-encryption-migrate)). Use encryption at host for new VMs instead.

## [4.0.0] - 2026-05-11

### Added

- Added is_imported variable to specify a existing VM, that needs to be imported with this module. With the value true the module will ignore the following changes: identity, admin_password, admin_ssh_key, disable_password_authentication
- Added new name overrides into the module
- Added additional_capabilities block
- Added identity block
- Added boot_diagnostic block
- Added new example to test the import of a VM
- Edited Documentation

## [3.3.0] - 2026-05-11

### Added

- Added new validation to the data disk variable "disk_mbps_read_write" and "disk_mbps_read_only" to support more Data Disk Types like "Premium", "PremiumV2" and "UltraSSD".

## [3.2.0] - 2026-03-05

### Added

- Added network_access_policy and public_network_access_enabled for datadisk configuration

## [3.1.0] - 2025-11-18

### Added

- Added documentation for the variables custom_data, vtpm_enabled and secure_boot_enabled

## [3.0.0] - 2025-11-18

### Added

- Capability to add custom data and scripts to the virtual machine
- Added vtpm and secure boot variables

## [2.1.1] - 2025-10-23

### Fixed

- Fixed validation of variables which permit compatibility with older module version.

## [2.1.0] - 2025-10-03

### Added

- Capability to set specific tags to datadisks

## [2.0.1] - 2025-09-02

### Fixed

- public_ip validation fixed

## [2.0.0] - 2025-08-27

### Changed

- azurerm version to ~> 4.0

## [1.8.0] - 2025-08-07

### Added

- Optional disk encryption support for Linux VM, allowing users to enable Key Vault–based encryption.
- Feature for additional nics
- Tags for the disk encryption

### Fixed

- Fixed example for pip zones

## [1.7.0] - 2025-07-18

### Added

- Assinging additional ip configurations is now possible

## [1.6.1] - 2025-07-18

### Added

- Zones support in Public IP
- New validations

### Changed

- Subnet address prefix input

## [1.5.0] - 2025-04-01

- Introducing support for Premium SSD v2 and Ultra SSD disks

## [1.4.1] - 2024-09-17

- VMs now depend on marketplace image agreement created by enable_plan=true

## [1.4.0] - 2024-09-16

- Added enable_plan option for marketplace images.

## [1.3.0] - 2024-08-20

### Added

- To support Copy/Restore disk on managed disk.

### Changed

- Upgrade accelerated networking variable in network interfaces.

## [1.2.0] - 2024-08-02

### Added

- Output the network interface

## [1.1.0] - 2024-08-01

### Added

- Output the network interface

## [1.0.0] - 2024-01-11

### Added

- Initial code that creates a VM

### Changed

### Removed

### Fixed
