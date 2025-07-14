# VM Backup Analysis

## Current VM Configuration & Backup Requirements

### VM-201 (TrueNAS) - ✅ PROPERLY CONFIGURED
```
System Disk: scsi0: local-lvm:vm-201-disk-0 (32G) - WILL BE BACKED UP
Data Disks (PASSTHROUGH - EXCLUDED FROM BACKUP):
├── scsi1: Kingston SSD (480G) - passthrough, no backup setting shown
├── scsi2: ST8000VN004 (7.3TB) - backup=0 ✅
├── scsi3: ST8000VN004 (7.3TB) - backup=0 ✅  
└── scsi4: ST8000VN004 (7.3TB) - backup=0 ✅

Expected Backup Size: ~10-15GB compressed (32GB system disk only)
Status: SAFE TO BACKUP - Large data drives properly excluded
```

### VM-202 (ansible-server) - Standard VM
```
System Disk: scsi0: local-lvm:vm-202-disk-0 (32G) - WILL BE BACKED UP
Expected Backup Size: ~8-12GB compressed
Status: SAFE TO BACKUP
```

### VM-203 (plex) - Standard VM  
```
System Disk: (32G based on qm list) - WILL BE BACKED UP
Expected Backup Size: ~8-12GB compressed
Status: SAFE TO BACKUP
```

### VM-204 (ha) - Standard VM
```
System Disk: (32G based on qm list) - WILL BE BACKED UP  
Expected Backup Size: ~8-12GB compressed
Status: SAFE TO BACKUP
```

### VM-205 (PC-Win11) - Larger VM
```
System Disk: ide0: local-lvm:vm-205-disk-1 (80G) - WILL BE BACKED UP
Expected Backup Size: ~20-40GB compressed (Windows)
Status: SAFE TO BACKUP
```

## Total Backup Size Estimate
```
VM-201 (TrueNAS):    ~15GB compressed
VM-202 (ansible):    ~12GB compressed  
VM-203 (plex):       ~12GB compressed
VM-204 (ha):         ~12GB compressed
VM-205 (Windows):    ~40GB compressed
────────────────────────────────────
Total VM Backups:    ~91GB compressed
```

## Critical Finding: TrueNAS Disk Passthrough is CORRECTLY Configured

### ✅ What's Working:
- TrueNAS data drives have `backup=0` parameter
- Only the 32GB system disk will be backed up
- ~22TB of data storage is properly excluded
- Backup sizes are manageable

### 🔍 Missing backup=0 Setting:
```
scsi1: /dev/disk/by-id/ata-KINGSTON_SA400S37480G_50026B7784E64AEC,cache=none,discard=on
```
This Kingston SSD (480GB) doesn't have `backup=0` and might be included in backups.

### Recommendation:
Add `backup=0` to the Kingston SSD if it's used for data storage in TrueNAS:
```bash
qm set 201 -scsi1 /dev/disk/by-id/ata-KINGSTON_SA400S37480G_50026B7784E64AEC,cache=none,discard=on,backup=0
```

## Storage Impact on New Configuration

When you reinstall Proxmox with the new storage layout:

### Fast Storage (NVMe): 
- VM-201 (TrueNAS system): 32G ✅
- VM-202 (ansible): 32G ✅  
- VM-203 (plex): 32G ✅
- Total: ~96GB of 834GB available ✅

### Standard Storage (SATA SSD):
- LXC containers: ~200GB total ✅
- Available: 445GB total ✅

### Bulk Storage (HDD RAID):
- VM-204, VM-205: Can be placed here if needed
- Backup storage: 2TB allocated
- Media storage: 10TB allocated

## Data Protection Strategy

### TrueNAS Data:
- Protected by TrueNAS RAID-Z (software RAID)
- TrueNAS handles snapshots and replication
- Only system disk needs Proxmox backup

### VM Data:
- All VM system disks backed up to PBS server
- Application data should be stored on TrueNAS shares
- Regular snapshots via TrueNAS for data protection

This configuration ensures manageable backup sizes while maintaining proper data protection!
