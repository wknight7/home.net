# LXC Container Creation

This directory contains tools for automated LXC container creation on Proxmox.

## Files

- `create_lxc.yml` - Main Ansible playbook for creating LXC containers
- `create_lxc.sh` - Shell script wrapper for easy execution
- `requirements.yml` - Required Ansible collections

## Prerequisites

1. **Ansible Collections**: Install required collections
   ```bash
   ansible-galaxy collection install -r requirements.yml
   ```

2. **Python Dependencies**: Install required system packages
   ```bash
   sudo apt install python3-proxmoxer python3-requests
   ```
   
   Or the playbook will attempt to install them automatically.

3. **Proxmox Access**: Ensure your Proxmox host (pve) is accessible and you have proper credentials

## Usage

### Quick Start
```bash
./create_lxc.sh
```

### Manual Execution
```bash
ansible-playbook -i inventory create_lxc.yml
```

## What the Playbook Does

1. **Interactive Prompts**: Asks for container specifications:
   - Container ID
   - Container name
   - Disk size (GB)
   - CPU cores
   - Memory (MB)
   - Swap (MB)

2. **Container Creation**: 
   - Creates unprivileged LXC container
   - Uses Ubuntu 24.10 template
   - Configures DHCP networking
   - Sets root password from vault.yml

3. **Container Configuration**:
   - Updates package cache
   - Installs curl
   - Runs bootstrap script from http://192.168.86.83/bootstrap.sh

4. **Inventory Management**:
   - Automatically adds container to `[lxc]` group
   - Automatically adds container to `[updates]` group
   - Records container ID and IP address

## Common Settings

These settings are automatically applied to all containers:

- **Template**: ubuntu-24.10-standard_24.10-1_amd64.tar.zst
- **Privileged**: No (unprivileged container)
- **Network**: DHCP on vmbr0 bridge
- **Storage**: local-lvm
- **Root Password**: From vault.yml (root_passwd variable)
- **Auto-start**: Yes

## Troubleshooting

1. **Collection Missing**: Run `ansible-galaxy collection install community.general`
2. **Python Modules Missing**: Run `sudo apt install python3-proxmoxer python3-requests`
3. **SSH Connection**: The playbook waits up to 5 minutes for SSH to become available
4. **IP Detection**: Uses `pct exec` command to get container IP address

## Example

```bash
$ ./create_lxc.sh

======================================
    LXC Container Creation Tool
======================================

This script will:
1. Prompt you for container specifications
2. Create a new LXC container on Proxmox
3. Configure the container with your bootstrap script
4. Add the container to your Ansible inventory

Do you want to continue? (y/N): y

Starting LXC container creation...

Enter container ID (e.g., 140): 140

Enter container name (e.g., myapp): testapp

Enter disk size (e.g., 8, 16 for GB) [8]: 16

Enter number of CPU cores [1]: 2

Enter memory in MB [1024]: 2048

Enter swap in MB [512]: 1024

[Creating container...]
[Configuring container...]
[Updating inventory...]

✅ LXC container creation completed successfully!

Container Details:
- ID: 140
- Name: testapp
- IP: 192.168.86.145
```
