# LXC Migration Guide: Ubuntu to Alpine Linux

This guide covers migrating LXC containers from Ubuntu Desktop to Alpine Linux for better resource efficiency.

## Prerequisites
- Proxmox host access
- Backup of important data/configurations
- List of services running on each LXC

## Alpine Template Setup
1. Download Alpine 3.22 template on Proxmox:
   ```bash
   pveam update
   pveam available --section system | grep alpine
   pveam download local alpine-3.22-default_20240911_amd64.tar.xz
   ```

## Migration Process (Per Container)

### Phase 1: Preparation
1. **Document current configuration**:
   ```bash
   # On the current container
   systemctl list-units --type=service --state=running
   dpkg -l | grep -E "^ii" > /tmp/installed-packages.txt
   crontab -l > /tmp/current-crontab.txt
   ```

2. **Backup configuration files**:
   ```bash
   tar -czf /tmp/config-backup.tar.gz /etc /home /var/spool/cron
   ```

### Phase 2: Create New Alpine Container
1. **Create new container with Alpine template**:
   ```bash
   pct create NEW_ID local:vztmpl/alpine-3.22-default_20240911_amd64.tar.xz \
     --hostname NEW_HOSTNAME \
     --memory 512 \
     --net0 name=eth0,bridge=vmbr0,ip=dhcp \
     --rootfs local-lvm:8
   ```

2. **Start and configure basic Alpine**:
   ```bash
   pct start NEW_ID
   pct enter NEW_ID
   
   # Basic Alpine setup
   apk update
   apk add openssh sudo python3 py3-pip
   
   # Enable services
   rc-update add sshd default
   rc-update add dcron default
   service sshd start
   service dcron start
   ```

### Phase 3: User Setup
1. **Create users**:
   ```bash
   adduser -D bill
   adduser -D hal
   addgroup bill wheel
   addgroup hal wheel
   
   # Set passwords
   passwd bill
   passwd hal
   ```

2. **SSH key setup**:
   ```bash
   mkdir -p /home/bill/.ssh /home/hal/.ssh
   # Copy SSH keys from old container or workstation
   ```

### Phase 4: Service Migration
1. **Install equivalent Alpine packages**:
   ```bash
   # Ubuntu → Alpine package mapping examples:
   # curl → curl
   # git → git  
   # docker.io → docker
   # python3-pip → py3-pip
   # systemd services → OpenRC services
   ```

2. **Recreate service configurations**:
   - Copy config files from backup
   - Convert systemd units to OpenRC scripts if needed
   - Update paths and package names

### Phase 5: Ansible Integration
1. **Update host_vars/HOSTNAME.yml**:
   ```yaml
   unattended_upgrades: false  # Alpine doesn't use this
   # Add any Alpine-specific configurations
   ```

2. **Test Ansible deployment**:
   ```bash
   ansible-playbook -i inventory local.yml --limit NEW_HOSTNAME
   ```

### Phase 6: Verification & Cutover
1. **Verify services are running**:
   ```bash
   rc-status -a
   ```

2. **Update Proxmox network/IP assignments**
3. **Update DNS entries if needed**
4. **Update Ansible inventory if container ID changed**
5. **Stop old container and cleanup**

## Service-Specific Notes

### WireGuard
- Alpine package: `wireguard-tools`
- Config location: `/etc/wireguard/`
- Service: `wg-quick@wg0`

### Common Services
- **Cron**: Uses `dcron` instead of `cron`
- **SSH**: Uses `openssh` (same config mostly)
- **Docker**: Available as `docker` package
- **Python**: Use `py3-*` packages instead of `python3-*`

## Alpine-Specific Considerations

### Package Management
```bash
# Update package index
apk update

# Install packages
apk add package-name

# List installed packages
apk info

# List available updates
apk list -u
```

### Service Management (OpenRC)
```bash
# Enable service at boot
rc-update add service-name default

# Start/stop services
service service-name start
service service-name stop

# Check service status
rc-status -a
```

### System Configuration
- Uses OpenRC instead of systemd
- Configuration in `/etc/conf.d/` and `/etc/init.d/`
- Smaller base system (~5MB vs ~1GB+)

## Rollback Plan
If issues arise:
1. Keep old container stopped but available
2. Can quickly switch back by starting old container
3. Update DNS/network back to old container
4. Investigate and retry migration

## Post-Migration Cleanup
1. **Remove old container**:
   ```bash
   pct destroy OLD_ID
   ```

2. **Update documentation**
3. **Verify monitoring/notifications work**
4. **Update any hardcoded references to old container**

## Benefits of Alpine Migration
- **Resource Efficiency**: ~90% reduction in memory usage
- **Security**: Smaller attack surface
- **Performance**: Faster boot times and lower resource usage
- **Maintenance**: Simpler system, fewer packages to update
