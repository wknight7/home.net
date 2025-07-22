#!/bin/bash
# TrueNAS Rsync Backup Script for all directories
# Final working version

set -e

# Configuration
PBS_SERVER="192.168.86.33"
PBS_USER="bill"
SSH_KEY="/root/.ssh/pbs_backup_rsa"
LOG_FILE="/var/log/backup-all.log"

# Directories to backup
declare -A BACKUP_DIRS=(
    ["ssd-docs"]="/mnt/ssd-files/docs"
    ["ssd-fileshare"]="/mnt/ssd-files/fileshare"
    ["ssd-home"]="/mnt/ssd-files/home"
    ["ssd-photo-storage"]="/mnt/ssd-files/photo_storage"
    ["ssd-workouts"]="/mnt/ssd-files/workouts"
    ["data-books"]="/mnt/Data/books"
    ["data-home-videos"]="/mnt/Data/media/storage/home_videos"
    ["data-photos"]="/mnt/Data/media/storage/photos"
)

# Logging
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "=== Starting All TrueNAS Backups at $(date) ==="

# Check PBS connectivity first
if ! ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no "${PBS_USER}@${PBS_SERVER}" "echo 'PBS connection verified'"; then
    echo "ERROR: Cannot connect to PBS server"
    exit 1
fi

FAILED_BACKUPS=0
SUCCESSFUL_BACKUPS=0

for BACKUP_ID in "${!BACKUP_DIRS[@]}"; do
    BACKUP_PATH="${BACKUP_DIRS[$BACKUP_ID]}"
    REMOTE_PATH="/srv/backups/truenas/${BACKUP_ID}/"
    
    echo ""
    echo "=== Backing up: ${BACKUP_ID} ==="
    echo "Source: ${BACKUP_PATH}"
    echo "Destination: ${PBS_SERVER}:${REMOTE_PATH}"
    
    START_TIME=$(date +%s)
    
    # Check if source exists
    if [ ! -d "${BACKUP_PATH}" ]; then
        echo "WARNING: Source directory ${BACKUP_PATH} does not exist - skipping"
        continue
    fi
    
    # Run rsync backup
    if rsync -avz --delete --progress \
        --exclude='*.tmp' \
        --exclude='**/.Trash*/**' \
        --exclude='**/Recycle.Bin/**' \
        --exclude='**/@eaDir/**' \
        --exclude='**/.DS_Store' \
        --exclude='**/*.lock' \
        --exclude='**/~$*' \
        --exclude='**/.cache/**' \
        --exclude='**/node_modules/**' \
        --exclude='**/.git/**' \
        --exclude='**/Thumbs.db' \
        --exclude='**/calibre-web.log*' \
        --exclude='**/*.part' \
        --exclude='**/*.xmp.bak' \
        -e "ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no" \
        "${BACKUP_PATH}/" \
        "${PBS_USER}@${PBS_SERVER}:${REMOTE_PATH}"; then
        
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        
        echo "✅ SUCCESS: ${BACKUP_ID} completed in ${DURATION} seconds"
        SUCCESSFUL_BACKUPS=$((SUCCESSFUL_BACKUPS + 1))
        
        # Create completion marker
        ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no "${PBS_USER}@${PBS_SERVER}" "echo '$(date)' > ${REMOTE_PATH}/.backup-completed"
        
        # Get backup size
        SIZE=$(ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no "${PBS_USER}@${PBS_SERVER}" "du -sh ${REMOTE_PATH} 2>/dev/null | cut -f1" || echo "Unknown")
        echo "Backup size: ${SIZE}"
    else
        echo "❌ ERROR: ${BACKUP_ID} backup failed"
        FAILED_BACKUPS=$((FAILED_BACKUPS + 1))
    fi
done

# Summary
echo ""
echo "=== Backup Summary $(date) ==="
echo "Total directories: ${#BACKUP_DIRS[@]}"
echo "Successful: ${SUCCESSFUL_BACKUPS}"
echo "Failed: ${FAILED_BACKUPS}"

# Get total backup storage
TOTAL_SIZE=$(ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no "${PBS_USER}@${PBS_SERVER}" "du -sh /srv/backups/truenas 2>/dev/null | cut -f1" || echo "Unknown")
echo "Total storage used: ${TOTAL_SIZE}"

if [ ${FAILED_BACKUPS} -gt 0 ]; then
    echo "⚠️  WARNING: ${FAILED_BACKUPS} backup(s) failed"
    exit 1
else
    echo "🎉 SUCCESS: All backups completed successfully!"
fi
