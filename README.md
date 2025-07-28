# home.net

Ansible-based infrastructure automation for managing a home lab environment consisting of LXC containers, VMs, workstations, and network appliances.

## Infrastructure Overview

This repository manages a complex home lab infrastructure with multiple host types, each requiring different configuration management approaches.

## Inventory Groups

### Primary Host Groups

#### `[lxc]` - LXC Containers
- **Purpose**: Lightweight containerized services running on Proxmox
- **Count**: 18 containers
- **Services**: Media management (Plex ecosystem), monitoring, documentation, networking
- **OS**: Ubuntu LXC containers
- **Management**: Automated provisioning, updates, and configuration via `lxc` role
- **Key Features**: 
  - Container ID tracking for Proxmox management
  - Shared storage mounts for media and documents
  - Automatic unattended upgrades

#### `[workstation]` - Desktop/Laptop Systems  
- **Purpose**: User workstations and laptops
- **Count**: 4 systems (desktop, samsung, dell, lily_laptop)
- **OS**: Ubuntu desktop variants
- **Management**: Full desktop environment setup via `workstation` role
- **Key Features**:
  - Desktop applications (LibreOffice, Chrome, VS Code)
  - Development tools and media software
  - Network drive mounting to TrueNAS
  - System notifications integration

#### `[vm]` - Virtual Machines
- **Purpose**: Full VMs for services requiring more isolation than containers
- **Count**: 2 VMs (plex, ha)
- **Services**: Plex media server, Home Assistant
- **OS**: Ubuntu Server VMs on Proxmox
- **Management**: VM-specific configuration via `vm` role
- **Key Features**:
  - GPU passthrough support (Plex)
  - NFS mount management
  - Specialized service configurations

#### `[proxmox_hosts]` - Hypervisor Hosts
- **Purpose**: Proxmox VE hypervisors managing VMs and containers
- **Count**: 2 hosts (pve=main hypervisor, pbs=backup server)
- **OS**: Proxmox VE (Debian-based)
- **Management**: Limited configuration via `proxmox_hosts` role
- **Key Features**:
  - Dark theme installation
  - Enterprise repository management
  - Automatic provisioning setup
  - **Note**: Uses `is_proxmox: true` flag to limit `common` role tasks

#### `[local]` - Ansible Control Node
- **Purpose**: Local system running Ansible (localhost)
- **Count**: 1 system
- **Management**: SSH configuration and local tooling via `local` role
- **Key Features**:
  - SSH key and config management for all hosts
  - Local development environment setup

#### `[truenas]` - Network Storage
- **Purpose**: TrueNAS SCALE network storage appliance  
- **Count**: 1 system
- **OS**: TrueNAS SCALE (specialized FreeBSD derivative)
- **Management**: Minimal configuration via `truenas` role
- **Key Features**:
  - **Isolated**: Not in `updates` group - no `common` role
  - Custom user management for network storage
  - **Note**: Uses `is_truenas: true` flag for conditional logic

#### `[windows]` - Windows Systems
- **Purpose**: Windows workstations requiring network drive mapping
- **Count**: 1 system (windows11)
- **OS**: Windows 11
- **Management**: Windows-specific tasks via `windows` role
- **Connection**: WinRM (not SSH)
- **Key Features**:
  - **Isolated**: Not in `updates` group - no `common` role
  - Network drive mapping to TrueNAS shares
  - PowerShell-based automation

### Meta Groups

#### `[updates]` - Common Configuration Target
- **Purpose**: Meta-group for systems that receive standard Linux configuration
- **Contains**: All Linux-based systems (LXCs, VMs, workstations, localhost, proxmox_hosts)
- **Excludes**: TrueNAS and Windows (incompatible with standard Linux roles)
- **Roles Applied**: `common` + `system_notifications`
- **Key Logic**: 
  - Provides base user management, SSH setup, package management
  - Enables system notification integration
  - Proxmox hosts get limited `common` tasks due to `is_proxmox: true` flag

#### `[ssh:children]` - SSH Connectivity Group
- **Purpose**: All hosts accessible via SSH (used for SSH key distribution)
- **Contains**: All groups except internal meta-groups
- **Usage**: SSH configuration and key management

## Playbook Execution Logic (`local.yml`)

### Role Application Strategy

1. **Base Configuration** (`updates` group):
   - Applies `common` and `system_notifications` roles to all compatible Linux systems
   - Skips TrueNAS and Windows (incompatible)
   - Proxmox hosts get limited tasks due to conditional flags

2. **Specialized Configuration** (individual groups):
   - Each group gets its specific role WITHOUT re-running `common`
   - Prevents redundant task execution
   - Maintains clean separation of concerns

### Host-Specific Considerations

- **TrueNAS**: Requires special authentication, custom user model
- **Windows**: Uses WinRM, PowerShell-based automation, different file paths
- **Proxmox**: Production hypervisors require minimal changes, special update handling
- **LXCs**: Lightweight, shared storage, rapid provisioning/reprovisioning
- **Workstations**: Full desktop environment, user-focused applications

## Network Architecture

- **Management Network**: 192.168.86.0/24
- **Primary Storage**: TrueNAS at 192.168.86.109
- **Hypervisor**: Proxmox VE at 192.168.86.143
- **Backup Server**: Proxmox Backup Server at 192.168.86.33
- **Container Range**: 192.168.86.27-104 (LXC containers)
- **VM Range**: 192.168.86.110+ (Virtual machines)
- **Workstation Range**: 192.168.86.40-94 (User systems)

## Notification System

- **Server**: ntfy at 192.168.86.97 (LXC container)
- **Integration**: All Linux systems report status via `system_notifications` role
- **Topics**: Per-host topics (system-{hostname}) for organized monitoring
- **Authentication**: HTTP Basic auth for security