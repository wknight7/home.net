# Proxmox Storage Configuration Plan

## Current System Analysis

### Hardware Overview
```
NVMe SSD: nvme0n1 (931.5G) - Primary system drive
SATA SSD: sde (447.1G) - Secondary system drive  
SATA SSD: sdf (119.2G) - USB-connected, excluded from setup (unreliable)
HDD Array: sda, sdb, sdc, sdd (4x 7.3T) - Large storage drives
```

### Current Problems
1. **LVM-Thin Pool Misconfiguration**: Single large thin pool spanning multiple drives
2. **Mixed Drive Types**: NVMe and SATA SSDs in same volume group
3. **No Storage Separation**: All VMs/containers on single thin pool
4. **Performance Issues**: HDDs not utilized properly
5. **No Redundancy**: Single points of failure

### Current Configuration
```
Volume Group: pve (1.34T total)
├── Physical Volumes:
│   ├── /dev/nvme0n1p3 (930.51G) - NVMe SSD
│   └── /dev/sde3 (446.13G) - SATA SSD
├── Logical Volumes:
│   ├── root (25.75G) - System root
│   ├── swap (8.00G) - Swap space
│   └── data (1.31T) - LVM-Thin pool with all VMs/containers

Storage Mounts:
├── local: /var/lib/vz (ISOs, templates, backups)
├── local-lvm: pve/data (VM/container storage)
└── backup: PBS at 192.168.86.33
```

## Recommended New Configuration

### Design Principles
1. **Separate System and Data Storage**: Keep OS and VMs separate
2. **Performance Tiers**: Fast SSD for critical VMs, HDD for bulk storage
3. **Proper Redundancy**: Use appropriate RAID levels
4. **Future Scalability**: Leave room for growth
5. **Clear Storage Roles**: Dedicated purposes for each storage pool

### New Storage Layout

#### Tier 1: High-Performance System Storage (NVMe SSD)
```
Device: /dev/nvme0n1 (931.5G)
Usage: System + Critical VMs + Fast Storage

Partitioning:
├── nvme0n1p1: BIOS Boot (1M)
├── nvme0n1p2: EFI System (1G)
└── nvme0n1p3: LVM PV (930G)

Volume Group: pve-fast
├── root (30G) - System root (increased from 25G)
├── swap (16G) - Swap space (increased from 8G)
├── local-fast (50G) - Fast local storage pool
└── vm-fast (834G) - Fast VM storage pool

Storage Pools:
├── local-fast: Directory storage for ISOs, templates, fast backups
└── fast-lvm: LVM-Thin pool for critical VMs (TrueNAS, Windows, etc.)
```

#### Tier 2: Standard Performance Storage (SATA SSD)
```
Device: /dev/sde (447.1G)
Usage: Standard VMs + Container Storage

Partitioning:
├── sde1: BIOS Boot (1M)
├── sde2: Reserved (1G)
└── sde3: LVM PV (445G)

Volume Group: pve-standard
└── vm-standard (445G) - Standard VM/container storage

Storage Pools:
└── standard-lvm: LVM-Thin pool for most LXC containers
```

#### Tier 3: Bulk Storage (SATA HDDs)
```
Devices: /dev/sda, /dev/sdb, /dev/sdc, /dev/sdd (4x 7.3T)
Usage: Bulk storage, backups, media

Configuration Options:

Option A - RAID10 (Recommended):
├── md0: RAID10 array (14.6T usable, 14.6T redundancy)
└── Volume Group: pve-bulk
    ├── backup-local (2T) - Local backup storage
    ├── media-storage (10T) - Media files, archives
    ├── vm-bulk (2T) - Bulk VM storage
    └── utility (600G) - Scratch space, logs, temporary files

Option B - RAID5:
├── md0: RAID5 array (21.9T usable, 7.3T redundancy)
└── Volume Group: pve-bulk
    ├── backup-local (4T) - Local backup storage
    ├── media-storage (15T) - Media files, archives
    ├── vm-bulk (2T) - Bulk VM storage
    └── utility (900G) - Scratch space, logs, temporary files

Option C - RAID6 (Maximum Safety):
├── md0: RAID6 array (14.6T usable, 14.6T redundancy)
└── Volume Group: pve-bulk
    ├── backup-local (2T) - Local backup storage
    ├── media-storage (10T) - Media files, archives
    ├── vm-bulk (2T) - Bulk VM storage
    └── utility (600G) - Scratch space, logs, temporary files
```

### Storage Pool Assignments

#### Fast Storage (NVMe - fast-lvm)
```
VM-201: TrueNAS (32G) - Primary NAS
VM-202: Windows 11 (32G) - Desktop VM
VM-203: Windows Server (32G) - Server workloads
Critical containers requiring fast I/O
```

#### Standard Storage (SATA SSD - standard-lvm)
```
Most LXC containers:
├── VM-100 through VM-117 (LXC containers 8-20G each)
├── Development VMs
└── Test environments
```

#### Bulk Storage (HDD Array - bulk-lvm)
```
VM-204: Media Server VM (if needed)
VM-205: Archive/Backup VM (if needed)
Large data storage containers
Media streaming containers
```

### Network Storage Integration
```
TrueNAS VM (VM-201):
├── Fast system disk: 32G on fast-lvm (NVMe)
├── Bulk data access: NFS/SMB mounts from HDD array
└── Network: Direct access to pve-bulk storage via bind mounts

Storage Hierarchy:
├── Fast: Critical VM disks, databases, active files
├── Standard: Container root filesystems, applications
├── Bulk: Media files, backups, archives, cold storage
└── Network: TrueNAS provides NFS/SMB to other systems
```

## Installation Steps

### 1. Pre-Installation Preparation
```bash
# Backup current system (already done)
# Download Proxmox ISO
# Prepare installation media
# Document current network configuration
```

### 2. Proxmox Installation
```bash
# Boot from Proxmox ISO
# Select "Advanced Options" -> "Debug Mode"
# Manual partitioning:

# NVMe SSD (/dev/nvme0n1):
sgdisk -Z /dev/nvme0n1
sgdisk -n 1:0:+1M -t 1:ef02 -c 1:"BIOS Boot" /dev/nvme0n1
sgdisk -n 2:0:+1G -t 2:ef00 -c 2:"EFI System" /dev/nvme0n1
sgdisk -n 3:0:0 -t 3:8e00 -c 3:"Linux LVM" /dev/nvme0n1

# SATA SSD (/dev/sde):
sgdisk -Z /dev/sde
sgdisk -n 1:0:+1M -t 1:ef02 -c 1:"BIOS Boot" /dev/sde
sgdisk -n 2:0:+1G -t 2:8300 -c 2:"Reserved" /dev/sde
sgdisk -n 3:0:0 -t 3:8e00 -c 3:"Linux LVM" /dev/sde

# Create Volume Groups:
pvcreate /dev/nvme0n1p3 /dev/sde3
vgcreate pve-fast /dev/nvme0n1p3
vgcreate pve-standard /dev/sde3

# Create System LVs on NVMe:
lvcreate -L 30G -n root pve-fast
lvcreate -L 16G -n swap pve-fast
lvcreate -L 50G -n local-fast pve-fast
lvcreate -l 100%FREE -n vm-fast pve-fast

# Format and mount system:
mkfs.ext4 /dev/pve-fast/root
mkswap /dev/pve-fast/swap
mkfs.ext4 /dev/pve-fast/local-fast
```

### 3. Post-Installation Storage Setup
```bash
# Create LVM-Thin pools:
lvcreate --type thin-pool -L 800G --poolmetadatasize 8G -n fast-pool pve-fast/vm-fast
lvcreate --type thin-pool -L 400G --poolmetadatasize 4G -n standard-pool pve-standard

# Setup HDD RAID (choose one option):
# Option A - RAID10:
mdadm --create /dev/md0 --level=10 --raid-devices=4 /dev/sda /dev/sdb /dev/sdc /dev/sdd

# Option B - RAID5:
mdadm --create /dev/md0 --level=5 --raid-devices=4 /dev/sda /dev/sdb /dev/sdc /dev/sdd

# Option C - RAID6:
mdadm --create /dev/md0 --level=6 --raid-devices=4 /dev/sda /dev/sdb /dev/sdc /dev/sdd

# Create bulk storage:
pvcreate /dev/md0
vgcreate pve-bulk /dev/md0
lvcreate -L 2T -n backup-local pve-bulk
lvcreate -L 10T -n media-storage pve-bulk  # Adjust based on RAID choice
lvcreate -l 100%FREE -n vm-bulk pve-bulk

# Format bulk storage:
mkfs.ext4 /dev/pve-bulk/backup-local
mkfs.ext4 /dev/pve-bulk/media-storage

# Setup utility storage:
mkfs.ext4 /dev/sdf1
```

### 4. Storage Configuration (/etc/pve/storage.cfg)
```
# Local directories
dir: local
    path /var/lib/vz
    content vztmpl,iso,backup

dir: local-fast
    path /mnt/local-fast
    content vztmpl,iso,backup,snippets
    
dir: backup-local
    path /mnt/backup-local
    content backup,dump
    
dir: media-storage
    path /mnt/media-storage
    content images,iso,backup          dir: utility
              path /mnt/bulk-utility
              content snippets,dump

# LVM-Thin pools
lvmthin: fast-lvm
    thinpool fast-pool
    vgname pve-fast
    content rootdir,images
    
lvmthin: standard-lvm
    thinpool standard-pool
    vgname pve-standard
    content rootdir,images
    
lvmthin: bulk-lvm
    thinpool vm-bulk
    vgname pve-bulk
    content rootdir,images

# External backup server
pbs: backup
    datastore backup
    server 192.168.86.33
    content backup
    fingerprint 05:a5:a7:89:a3:c2:56:5b:b0:af:30:80:fb:23:04:04:48:a9:78:69:35:85:89:e7:9d:83:ca:0a:6a:a7:43:b0
    prune-backups keep-all=1
    username root@pam
```

## VM/Container Migration Plan

### Critical VMs (Fast Storage)
```
VM-201 (TrueNAS): 
├── Restore to fast-lvm
├── Size: 32G
└── Priority: High

VM-202 (Windows 11):
├── Restore to fast-lvm  
├── Size: 32G
└── Priority: High

VM-203 (Windows Server):
├── Restore to fast-lvm
├── Size: 32G
└── Priority: Medium
```

### Standard Containers (Standard Storage)
```
All LXC containers (VM-100 through VM-117):
├── Restore to standard-lvm
├── Size: 8-20G each
└── Priority: Medium
```

### Bulk Storage VMs (if needed)
```
Large VMs or storage-intensive workloads:
├── Place on bulk-lvm
├── Lower performance but high capacity
└── Priority: Low
```

## Benefits of New Configuration

### Performance
- **Fast System**: NVMe for OS and critical VMs
- **Optimized I/O**: Separate storage tiers for different workloads
- **Reduced Contention**: No mixed SSD/HDD in same volume group

### Reliability
- **RAID Protection**: HDD array with redundancy
- **Separate Failure Domains**: System and data storage isolated
- **Multiple Backup Targets**: Local and network backup options

### Scalability
- **Modular Design**: Easy to add storage to appropriate tier
- **Clear Upgrade Path**: Replace/add drives to specific tiers
- **Flexible Allocation**: Move VMs between storage tiers as needed

### Management
- **Clear Storage Roles**: Each pool has specific purpose
- **Better Resource Allocation**: Match storage to workload needs
- **Simplified Troubleshooting**: Isolated storage systems

## Recommendations

### RAID Choice for HDDs
**Recommended: RAID10**
- Best balance of performance and redundancy
- Can lose up to 2 drives (in different mirrors)
- Better rebuild performance than RAID5/6
- 50% capacity efficiency (14.6T usable from 29.2T raw)

**Alternative: RAID6** (if maximum safety needed)
- Can lose up to 2 drives (any 2)
- Slower rebuild but maximum protection
- 50% capacity efficiency (14.6T usable from 29.2T raw)

### VM Placement Strategy
1. **TrueNAS**: Fast storage (NVMe) - needs high I/O for NAS operations
2. **Windows VMs**: Fast storage (NVMe) - better user experience
3. **LXC Containers**: Standard storage (SATA SSD) - good performance, lower cost
4. **Archive/Media**: Bulk storage (HDD RAID) - high capacity, adequate performance

### Future Considerations
- **NVMe Upgrade**: Replace SATA SSD with larger NVMe when available
- **Network Storage**: Consider 10GbE for TrueNAS if needed
- **Cache Tiers**: Could add cache drives to HDD array later
- **Backup Strategy**: Regular sync between local and PBS backup

This configuration provides a solid foundation for your home lab with proper performance tiers, redundancy, and room for future growth.
