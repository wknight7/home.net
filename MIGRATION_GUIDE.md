# Manual Workstation Preparation Guide for NFS Migration

This guide will help you manually prepare your workstations for the new resilient NFS directory structure. After completing these steps, Ansible will handle the final setup automatically.

## Overview
We're moving from local directories to NFS-backed symlinks for Documents and Downloads, while keeping some directories local (Desktop, Code, Git).

## Before You Begin
1. **Check current mounts**: Run `mount | grep truenas` to see what's already mounted
2. **Backup Important Data**: While TrueNAS has your data, make local backups of anything critical
3. **Close All Applications**: Especially file managers, text editors, and anything using Documents/Downloads
4. **Have TrueNAS Running**: Ensure 192.168.86.109 is accessible

## Current Mount Status (as of migration)
- **Desktop (192.168.86.40)**: Has BOTH old direct mounts AND new resilient mounts (CONFLICT!)
- **Dell (192.168.86.55)**: Has shared mounts + DIRECT user directory mounts (old style)
- **Samsung & Lily's laptop**: Currently offline

**CRITICAL**: Both Desktop and Dell have the problematic direct mounting approach where home directories are mounted directly to TrueNAS. Desktop also has duplicate mounts. We need to clean this up first.

## Step-by-Step Manual Preparation

### Quick Summary by Workstation:
- **Desktop**: Step 0 (Clean up conflicting mounts) → Common Steps 1-6
- **Dell**: Step 0 (Unmount direct mounts) → Common Steps 1-6  
- **Samsung/Lily's laptop**: Common Steps 1-6 only

---

### For Workstations WITH BOTH Old and New Mounts (Desktop):

#### Step 0: Clean Up Conflicting Mounts
```bash
# First unmount ALL the old direct home directory mounts
sudo umount /home/bill/downloads
sudo umount /home/lily/documents
sudo umount /home/lily/downloads
sudo umount /home/loretta/documents
sudo umount /home/loretta/downloads
sudo umount /home/bill/media

# Also unmount any old shared mounts in wrong locations
sudo umount /mnt/shared_files 2>/dev/null || true

# Keep the new resilient mounts in /mnt/truenas/
# Verify what's left:
mount | grep truenas
```

### For Workstations WITH Direct User Directory Mounts (Dell):

#### Step 0: Unmount Direct User Directory Mounts
```bash
# Check what's directly mounted to home directories
mount | grep '/home/'

# Unmount the old direct mounts
sudo umount /home/bill/documents
sudo umount /home/bill/downloads  # if mounted
sudo umount /home/lily/documents  # if mounted
sudo umount /home/lily/downloads   # if mounted
sudo umount /home/loretta/documents # if mounted
sudo umount /home/loretta/downloads # if mounted

# Verify they're unmounted
mount | grep '/home/' || echo "No home directory mounts remaining"
```

**THEN CONTINUE TO "Common Steps for All Workstations" BELOW**

### For Workstations WITHOUT User NFS Mounts (Samsung, Lily's laptop):

#### Step 1: Create Migration Backup Directory
```bash
mkdir -p /home/bill/migration-backup-$(date +%Y%m%d)
mkdir -p /home/lily/migration-backup-$(date +%Y%m%d)     # if lily user exists
mkdir -p /home/loretta/migration-backup-$(date +%Y%m%d) # if loretta user exists
```

### Common Steps for All Workstations:

#### Step 2: Move Existing Content to Backup (Bill's directories)
```bash
# Move bill's existing directories
cd /home/bill
if [ -d "Documents" ] && [ "$(ls -A Documents)" ]; then
    mv Documents migration-backup-$(date +%Y%m%d)/Documents-old
fi
if [ -d "Downloads" ] && [ "$(ls -A Downloads)" ]; then
    mv Downloads migration-backup-$(date +%Y%m%d)/Downloads-old
fi
if [ -d "media" ]; then
    rm -rf media  # Remove any existing media directory/symlink
fi

# Remove other default directories we don't want
rm -rf Desktop Music Pictures Public Templates Videos 2>/dev/null || true
```

#### Step 3: Move Existing Content (Lily's directories, if user exists)
```bash
# Only if lily user exists on this workstation
if id "lily" &>/dev/null; then
    cd /home/lily
    if [ -d "Documents" ] && [ "$(ls -A Documents)" ]; then
        mv Documents migration-backup-$(date +%Y%m%d)/Documents-old
    fi
    if [ -d "Downloads" ] && [ "$(ls -A Downloads)" ]; then
        mv Downloads migration-backup-$(date +%Y%m%d)/Downloads-old
    fi
    rm -rf Desktop Music Pictures Public Templates Videos 2>/dev/null || true
fi
```

#### Step 4: Move Existing Content (Loretta's directories, if user exists)
```bash
# Only if loretta user exists on this workstation
if id "loretta" &>/dev/null; then
    cd /home/loretta
    if [ -d "Documents" ] && [ "$(ls -A Documents)" ]; then
        mv Documents migration-backup-$(date +%Y%m%d)/Documents-old
    fi
    if [ -d "Downloads" ] && [ "$(ls -A Downloads)" ]; then
        mv Downloads migration-backup-$(date +%Y%m%d)/Downloads-old
    fi
    rm -rf Desktop Music Pictures Public Templates Videos 2>/dev/null || true
fi
```

#### Step 5: Verify NFS Server Accessibility
```bash
# Test that TrueNAS is reachable
ping -c 3 192.168.86.109

# Test NFS exports are available
showmount -e 192.168.86.109
```

#### Step 6: Create Basic Directory Structure
```bash
# For bill
mkdir -p /home/bill/{desktop,code,git}

# For lily (if exists)
if id "lily" &>/dev/null; then
    mkdir -p /home/lily/desktop
fi

# For loretta (if exists)  
if id "loretta" &>/dev/null; then
    mkdir -p /home/loretta/desktop
fi
```

### Important Data Migration Notes

#### What to do with backup data:
1. **Documents**: After Ansible runs, you can copy files from `migration-backup-*/Documents-old/` into the new NFS-backed `Documents` symlink
2. **Downloads**: Same process for Downloads directory
3. **Keep backups**: Don't delete the migration-backup directories until you're sure everything is working

#### One-time manual copy to TrueNAS (if needed):
If you have important local data that's not already on TrueNAS:
```bash
# After Ansible runs and symlinks are created, copy backed up data:
cp -r /home/bill/migration-backup-*/Documents-old/* /home/bill/documents/
cp -r /home/bill/migration-backup-*/Downloads-old/* /home/bill/downloads/
```

## After Manual Preparation: Run Ansible

Once you've completed the manual preparation on a workstation, run:

```bash
# Test on one workstation first (replace 'dell' with your test machine)
./test-migration.sh dell

# If successful, run on all workstations
ansible-playbook -i inventory -l desktop,samsung,dell,lily_laptop local.yml
```

## Post-Migration Verification

After Ansible completes:

1. **Check symlinks exist**:
   ```bash
   ls -la /home/bill/
   # Should show documents -> /mnt/truenas/bill-documents
   ```

2. **Test NFS accessibility**:
   ```bash
   ls -la /home/bill/documents/
   touch /home/bill/documents/test-file.txt
   rm /home/bill/documents/test-file.txt
   ```

3. **Copy backup data** if needed (see above)

## Troubleshooting

- **NFS mount fails**: Check TrueNAS is running and network connectivity
- **Permission issues**: The mounts use uid/gid mapping, so file ownership should work correctly
- **Symlink creation fails**: Ensure the target directories were properly cleaned in manual prep

## Rollback Plan

If something goes wrong:
1. Stop using the new symlinks
2. Restore from migration-backup directories
3. Remove NFS mounts: `sudo umount /mnt/truenas/*`
4. Restore original directory structure from backups

## Quick Reference Commands

### Check current mounts:
```bash
mount | grep truenas
```

### Unmount user directories only (for Desktop):
```bash
sudo umount /mnt/truenas/bill-documents /mnt/truenas/bill-downloads
sudo umount /mnt/truenas/lily-documents /mnt/truenas/lily-downloads  
sudo umount /mnt/truenas/loretta-documents /mnt/truenas/loretta-downloads
```

### Unmount direct home directory mounts (for Dell):
```bash
sudo umount /home/bill/documents /home/bill/downloads
sudo umount /home/lily/documents /home/lily/downloads
sudo umount /home/loretta/documents /home/loretta/downloads
```

### Test readiness for automation:
```bash
# This should FAIL if manual prep isn't complete
./test-migration.sh dell

# Look for errors like "refusing to convert from directory to symlink"
# This means you need to complete the manual preparation steps first
```
