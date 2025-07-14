# Proxmox Installation Quick Reference

## Pre-Installation Checklist
- [x] ✅ Run backup script and verify backups
- [x] ✅ Manually backup TrueNAS VM (ID: 201) 
- [ ] Copy backups to external storage
- [ ] Download latest Proxmox VE ISO
- [ ] Create installation media
- [ ] Document current network settings

## Installation Commands Quick Reference

### 1. Disk Preparation (during installation debug mode)
```bash
# Clear existing partitions
sgdisk -Z /dev/nvme0n1
sgdisk -Z /dev/sde
sgdisk -Z /dev/sda
sgdisk -Z /dev/sdb
sgdisk -Z /dev/sdc
sgdisk -Z /dev/sdd
# Note: /dev/sdf (USB SSD) excluded - unreliable connection

# Partition NVMe (system drive)
sgdisk -n 1:0:+1M -t 1:ef02 -c 1:"BIOS Boot" /dev/nvme0n1
sgdisk -n 2:0:+1G -t 2:ef00 -c 2:"EFI System" /dev/nvme0n1
sgdisk -n 3:0:0 -t 3:8e00 -c 3:"Linux LVM" /dev/nvme0n1

# Partition SATA SSD (standard storage)
sgdisk -n 1:0:+1M -t 1:ef02 -c 1:"BIOS Boot" /dev/sde
sgdisk -n 2:0:+1G -t 2:8300 -c 2:"Reserved" /dev/sde
sgdisk -n 3:0:0 -t 3:8e00 -c 3:"Linux LVM" /dev/sde

# Create initial LVM
pvcreate /dev/nvme0n1p3 /dev/sde3
vgcreate pve-fast /dev/nvme0n1p3
vgcreate pve-standard /dev/sde3

# Create system volumes
lvcreate -L 30G -n root pve-fast
lvcreate -L 16G -n swap pve-fast
lvcreate -L 50G -n local-fast pve-fast
lvcreate -l 100%FREE -n vm-fast pve-fast

# Format system
mkfs.ext4 /dev/pve-fast/root
mkswap /dev/pve-fast/swap
mkfs.ext4 /dev/pve-fast/local-fast
```

### 2. Post-Installation Storage Setup
```bash
# Create thin pools
lvcreate --type thin-pool -L 800G --poolmetadatasize 8G -n fast-pool pve-fast/vm-fast
lvcreate --type thin-pool -L 400G --poolmetadatasize 4G -n standard-pool pve-standard

# Create RAID10 for HDDs (recommended)
mdadm --create /dev/md0 --level=10 --raid-devices=4 /dev/sda /dev/sdb /dev/sdc /dev/sdd

# Wait for RAID to initialize
watch cat /proc/mdstat

# Create bulk storage
pvcreate /dev/md0
vgcreate pve-bulk /dev/md0
lvcreate -L 2T -n backup-local pve-bulk
lvcreate -L 10T -n media-storage pve-bulk
lvcreate -l 100%FREE -n vm-bulk pve-bulk

# Format and mount
mkfs.ext4 /dev/pve-bulk/backup-local
mkfs.ext4 /dev/pve-bulk/media-storage

mkdir -p /mnt/{local-fast,backup-local,media-storage,bulk-utility}
```

### 3. Update /etc/fstab
```bash
cat >> /etc/fstab << 'EOF'
/dev/pve-fast/local-fast    /mnt/local-fast     ext4    defaults        0       2
/dev/pve-bulk/backup-local  /mnt/backup-local   ext4    defaults        0       2
/dev/pve-bulk/media-storage /mnt/media-storage  ext4    defaults        0       2
/dev/pve-bulk/utility       /mnt/bulk-utility   ext4    defaults        0       2
EOF

mount -a
```

### 4. Configure Storage Pools
```bash
# Edit /etc/pve/storage.cfg
# Add storage definitions from main plan
```

### 5. Network Configuration
```bash
# Copy network config from backup
# Update /etc/network/interfaces
# Update /etc/hosts
# Update /etc/hostname
```

### 6. Restore VMs and Containers
```bash
# Restore configuration files
# Restore VM backups to appropriate storage pools
# Start containers from existing backup server
```

## Storage Pool Usage Guide

### fast-lvm (NVMe - High Performance)
- TrueNAS VM (VM-201)
- Windows VMs (VM-202, VM-203)
- Database containers
- High I/O applications

### standard-lvm (SATA SSD - Standard Performance)  
- Most LXC containers (VM-100-117)
- Development environments
- Web applications
- Low to medium I/O workloads

### bulk-lvm (HDD RAID - High Capacity)
- Large VMs
- Storage-intensive applications
- Archive containers
- Media storage containers

### Directory Storage
- `/mnt/local-fast`: Fast ISOs, templates, small backups
- `/mnt/backup-local`: Local backup storage
- `/mnt/media-storage`: Media files, large archives
- `/mnt/bulk-utility`: Temporary files, logs, scratch space (on RAID)

## Expected Results

### Storage Capacity
- **fast-lvm**: ~800G for critical VMs
- **standard-lvm**: ~400G for containers
- **bulk-lvm**: ~2.6T for large VMs
- **backup-local**: 2T for local backups
- **media-storage**: 10T for media files

### Performance Tiers
- **Tier 1 (NVMe)**: 3,000+ IOPS, <1ms latency
- **Tier 2 (SATA SSD)**: 500+ IOPS, <5ms latency  
- **Tier 3 (HDD RAID10)**: 200+ IOPS, <20ms latency

### Redundancy
- **System**: Single drive (NVMe) - backed up to PBS
- **Standard**: Single drive (SATA SSD) - backed up to PBS
- **Bulk**: RAID10 - can lose 2 drives + PBS backup

This configuration will provide a much more robust and scalable foundation for your home lab!
