#!/bin/bash
# Proxmox Backup Execution Script
# NOTE: Containers are already backed up to separate bare metal Proxmox server

set -e

echo "=========================================="
echo "Proxmox Configuration Backup Script"
echo "=========================================="

# Get the current date
BACKUP_DATE=$(date +%Y%m%d)
echo "Backup date: $BACKUP_DATE"

# Step 1: Backup Proxmox host configuration
echo ""
echo "Step 1: Backing up Proxmox host configuration..."
ansible-playbook -i inventory playbooks/proxmox_backup.yml

echo ""
echo "=========================================="
echo "Configuration backup completed!"
echo "=========================================="
echo ""
echo "NEXT MANUAL STEPS:"
echo "1. Backup TrueNAS VM manually (CRITICAL!):"
echo "   ssh root@192.168.86.143"
echo "   qm backup 201 /var/lib/vz/dump/vzdump-qemu-201-\$(date +%Y_%m_%d).vma.gz --compress gzip"
echo ""
echo "2. Copy VM backup to external storage"
echo ""
echo "3. Document your desired new LVM layout"
echo ""
echo "BACKUP LOCATIONS:"
echo "- Proxmox config: ./proxmox_backup_${BACKUP_DATE}/"
echo "- Containers: Already on separate Proxmox server ✓"
echo "- VMs: Manual backup required (see commands above)"
echo ""
echo "Ready for Proxmox reinstallation once VM backup is complete!"
