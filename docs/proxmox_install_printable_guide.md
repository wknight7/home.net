# Proxmox Installation Guide (PRINTABLE)
**Print this guide - ansible-server will not be available during install**

## Pre-Installation Checklist
- [x] ✅ Configuration backup completed: `proxmox_backup_2025-07-13.tar.gz` (43KB)
- [x] ✅ TrueNAS VM backup completed: `vzdump-qemu-201-2025_07_13-19_03_52.vma.zst` (2.3GB)
- [ ] Copy both backups to external USB drive
- [ ] Download Proxmox VE 8.x ISO from https://www.proxmox.com/downloads
- [ ] Create bootable USB with Rufus/balenaEtcher
- [ ] Have this guide printed and ready

## Current Network Settings (for reference)
```
Hostname: pve
IP Address: 192.168.86.143
Subnet: 255.255.255.0 (/24)
Gateway: 192.168.86.1
DNS: 192.168.86.1, 8.8.8.8
Interface: vmbr0 (bridge)
```

## Storage Plan Summary
**CORRECTED - 2-Tier Storage Architecture:**
- **Tier 1 (NVMe)**: System + Critical VMs (931GB)
- **Tier 2 (SATA SSD)**: LXC Containers (447GB)  
- **TrueNAS Data**: Kingston SSD (480GB) + 3x HDDs (7.3TB each) - ZFS pools, passed through

---

## INSTALLATION STEPS

### 1. Boot from Proxmox USB
1. Insert Proxmox USB drive
2. Boot from USB (F12/F2 for boot menu)
3. Select "Install Proxmox VE"

### 2. Installation Options
1. **Accept License Agreement**
2. **Target Harddisk**: 
   - **CRITICAL**: Select NVMe drive (`/dev/nvme0n1`) ONLY
   - **DO NOT** select SATA SSD or HDDs yet
   - **Filesystem**: ext4 (default is fine)
   - **hdsize**: Leave default (will use full drive)

### 3. Location and Time Zone
1. **Country**: United States
2. **Time zone**: America/New_York (or your timezone)
3. **Keyboard Layout**: us

### 4. Administration Password
1. **Password**: (your root password)
2. **Confirm**: (same password)
3. **Email**: your email address

### 5. Network Configuration
```
Management Interface: (auto-detected, likely enp4s0)
Hostname (FQDN): pve.local
IP Address: 192.168.86.143
Netmask: 255.255.255.0
Gateway: 192.168.86.1
DNS Server: 192.168.86.1
```

### 6. Summary and Install
1. Review settings
2. Click "Install"
3. Wait for installation (5-10 minutes)
4. **Reboot when prompted**

---

## POST-INSTALLATION SETUP (via SSH or console)

### Step 1: Access System
```bash
# From another computer:
ssh root@192.168.86.143

# Or use local console
```

### Step 2: Update System
```bash
apt update && apt upgrade -y
```

### Step 3: Setup Additional Storage

#### A. Prepare SATA SSD for containers
```bash
# Partition SATA SSD
fdisk /dev/sde
# Press: n, p, 1, Enter, Enter, w

# Create physical volume and volume group
pvcreate /dev/sde1
vgcreate pve-standard /dev/sde1

# Create thin pool for containers
lvcreate --type thin-pool -l 100%FREE -n standard-pool pve-standard
```

#### B. TrueNAS Data Drives - DO NOT TOUCH!
**✅ IMPORTANT: The following drives contain ZFS data and must NOT be formatted!**

**Current TrueNAS Configuration:**
- **Kingston SSD (sda)**: 480GB - ZFS data ✅ KEEP AS-IS
- **ST8000 HDD (sdb)**: 7.3TB - ZFS data ✅ KEEP AS-IS  
- **ST8000 HDD (sdc)**: 7.3TB - ZFS data ✅ KEEP AS-IS
- **ST8000 HDD (sdd)**: 7.3TB - ZFS data ✅ KEEP AS-IS

**These drives will be passed through to TrueNAS VM unchanged.**
**All your data will remain intact on these drives.**

**SKIP any RAID/LVM creation on these drives!**

### Step 4: Configure Storage Pools in Proxmox
```bash
# Edit storage configuration
nano /etc/pve/storage.cfg
```

**Add these storage definitions:**
```
# Fast NVMe storage (default local-lvm is fine)

# Standard SSD storage for containers  
lvmthin: standard-lvm
    thinpool standard-pool
    vgname pve-standard
    content rootdir,images

# PBS backup server
pbs: backup
    datastore backup
    server 192.168.86.33
    content backup
    fingerprint 05:a5:a7:89:a3:c2:56:5b:b0:af:30:80:fb:23:04:04:48:a9:78:69:35:85:89:e7:9d:83:ca:0a:6a:a7:43:b0
    prune-backups keep-all=1
    username root@pam
```

**Note: No bulk storage pools needed - TrueNAS provides network storage via NFS/SMB**

### Step 5: Verify Storage Setup
```bash
# Check storage pools
pvesm status

# Check LVM layout
pvs && vgs && lvs

# Check RAID status
cat /proc/mdstat

# Check mounts
df -h
```

---

## RESTORATION PROCESS

### Step 1: Copy Backups to System
```bash
# Mount external USB drive
mkdir /mnt/usb
mount /dev/sdX1 /mnt/usb  # Replace X with actual device

# Copy backups to local storage (since no bulk storage pool)
cp /mnt/usb/proxmox_backup_2025-07-13.tar.gz /var/lib/vz/dump/
cp /mnt/usb/vzdump-qemu-201-2025_07_13-19_03_52.vma.zst /var/lib/vz/dump/
```

### Step 2: Restore Proxmox Configuration
```bash
# Extract configuration backup
cd /tmp
tar -xzf /var/lib/vz/dump/proxmox_backup_2025-07-13.tar.gz

# Restore network config (if needed)
cp /tmp/proxmox_backup_2025-07-13/interfaces /etc/network/interfaces.backup
# Review and apply manually if different

# Restore other configs can be done via Ansible later
```

### Step 3: Restore TrueNAS VM
```bash
# Restore to fast storage (NVMe)
qmrestore /var/lib/vz/dump/vzdump-qemu-201-2025_07_13-19_03_52.vma.zst 201 \
  --storage local-lvm

# Add disk passthroughs (CORRECTED - 3 HDDs + 1 SSD)
# Add Kingston SSD
qm set 201 -scsi1 /dev/disk/by-id/ata-KINGSTON_SA400S37480G_50026B7784E64AEC,backup=0,cache=none,discard=on

# Add 3x ST8000 HDDs
qm set 201 -scsi2 /dev/disk/by-id/ata-ST8000VN004-3CP101_WWZ20F1E,backup=0,cache=none,discard=on
qm set 201 -scsi3 /dev/disk/by-id/ata-ST8000VN004-3CP101_WWZ1ZYD1,backup=0,cache=none,discard=on
qm set 201 -scsi4 /dev/disk/by-id/ata-ST8000VN004-3CP101_WWZ1MLJL,backup=0,cache=none,discard=on

# Enable serial console
qm set 201 -serial0 socket

# Start TrueNAS
qm start 201
```

### Step 4: Restore Containers from PBS
1. Open Proxmox web UI: https://192.168.86.143:8006
2. Go to Datacenter > Storage > backup (PBS)
3. Select container backups and restore to `standard-lvm` storage

---

## VERIFICATION CHECKLIST

- [ ] Proxmox web UI accessible: https://192.168.86.143:8006
- [ ] All storage pools visible and active
- [ ] TrueNAS VM boots and accessible
- [ ] Serial console works: `qm terminal 201`
- [ ] TrueNAS recognizes all ZFS pools and data
- [ ] Containers restored and running
- [ ] Network connectivity to all services
- [ ] PBS backup working
- [ ] WireGuard VPN accessible from outside

---

## IMPORTANT NOTES

⚠️  **ZFS Data Safety**: The Kingston SSD and 3x HDDs contain ZFS pools with your data. These drives will be passed through unchanged to TrueNAS - NO data loss!

⚠️  **Disk Passthrough**: Make sure to add `backup=0` to all TrueNAS data disks to prevent huge backups.

⚠️  **Storage Mapping**: 
- Critical VMs (201,202,203) → local-lvm (NVMe)
- Containers (100-117) → standard-lvm (SATA SSD)  
- TrueNAS data → Kingston SSD + 3x HDDs (passed through)

⚠️  **Network**: Double-check IP settings match current configuration.

✅  **Success Indicator**: When you can access TrueNAS shares via NFS/SMB and all containers are running.

**Total expected setup time: 1-2 hours (no RAID sync needed)**
