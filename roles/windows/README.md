# Windows Network Drive Management

This role manages Windows network drives (SMB/CIFS shares) similar to how we manage NFS mounts on Linux systems using fstab.

## Overview

When your TrueNAS server IP address changes, you can now update it in one place and have Ansible automatically reconfigure all your Windows network drives.

## Configuration Files

### Group Variables: `group_vars/windows.yml`
- Defines which network drives to map
- Contains the TrueNAS server IP address
- Specifies drive letters, paths, and credentials

### Host Variables: `host_vars/windows11.yml`
- Contains Windows-specific connection settings
- Uses WinRM for Windows management tasks

### Vault Variables: `vault.yml`
- Should contain `truenas_smb_password` variable
- Should contain `windows_password` variable

## Usage

### 1. Update TrueNAS Server IP
When your TrueNAS IP changes, edit `group_vars/windows.yml`:
```yaml
truenas_server_ip: "192.168.86.XXX"  # Update this line
```

### 2. Run Ansible Playbook
```bash
# Map network drives only
ansible-playbook -i inventory your_playbook.yml --limit windows --tags network_drives

# Deploy scripts only  
ansible-playbook -i inventory your_playbook.yml --limit windows --tags scripts

# Run everything for Windows hosts
ansible-playbook -i inventory your_playbook.yml --limit windows
```

### 3. Manual Management (Alternative)
A PowerShell script is deployed to `C:\Scripts\Map-NetworkDrives-Auto.ps1` with these options:

```powershell
# Map all drives
.\Map-NetworkDrives-Auto.ps1

# Disconnect all drives
.\Map-NetworkDrives-Auto.ps1 -Disconnect

# Test current connections
.\Map-NetworkDrives-Auto.ps1 -Test
```

## Default Drive Mappings

| Drive | Path | Purpose |
|-------|------|---------|
| H: | `\\TrueNAS\home\username\Documents` | User Documents |
| I: | `\\TrueNAS\home\username\Downloads` | User Downloads |
| M: | `\\TrueNAS\media` | Media Files |
| P: | `\\TrueNAS\paperless` | Paperless Documents |
| S: | `\\TrueNAS\shared_files` | Shared Files |
| W: | `\\TrueNAS\workouts` | Workout Data |

## Vault Setup

Add these variables to your `vault.yml`:

```yaml
# Windows login password
windows_password: "your_windows_password"

# TrueNAS SMB share password
truenas_smb_password: "your_truenas_smb_password"
```

## Troubleshooting

### Common Issues
1. **WinRM Connection Errors**: Ensure WinRM is enabled on Windows and firewall allows connections
2. **Authentication Failures**: Verify credentials in vault.yml
3. **Drive Mapping Failures**: Check SMB share names and permissions on TrueNAS

### Testing Connection
```bash
# Test WinRM connectivity
ansible windows -i inventory -m win_ping

# Test with verbose output
ansible-playbook -i inventory your_playbook.yml --limit windows -vv
```

### Manual Network Drive Commands
```cmd
# List current mappings
net use

# Disconnect specific drive
net use H: /delete

# Map drive manually
net use H: \\192.168.86.109\home\username\Documents /persistent:yes
```

## Comparison with Linux NFS Mounts

| Linux (NFS) | Windows (SMB/CIFS) |
|-------------|---------------------|
| `/etc/fstab` | Registry + `net use` |
| `mount -a` | Persistent drive mappings |
| `nfs_system_mounts` | `windows_network_drives` |
| IP in group_vars | IP in group_vars |

## Security Notes

- Credentials are stored in Ansible Vault (encrypted)
- Network drives use persistent mappings (survive reboots)
- Consider using service accounts for SMB authentication
- Regularly rotate passwords in vault.yml

## Customization

To add or modify drive mappings, edit the `windows_network_drives` list in `group_vars/windows.yml`:

```yaml
windows_network_drives:
  - name: "Custom Drive"
    drive_letter: "X:"
    remote_path: "\\\\{{ truenas_server_ip }}\\custom_share"
    username: "{{ ansible_user }}"
    password: "{{ truenas_smb_password }}"
    persistent: true
```
