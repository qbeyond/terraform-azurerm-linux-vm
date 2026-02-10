# Changelog

All notable changes to this module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this module adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
