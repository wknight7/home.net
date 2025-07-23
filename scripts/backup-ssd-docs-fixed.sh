#!/bin/bash
# TrueNAS Rsync Backup Script for ssd-docs
# Fixed version with proper SSH configuration

set -e

# Configuration
PBS_SERVER="192.168.86.33"
PBS_USER="bill"
BACKUP_ID="ssd-docs"
BACKUP_PATH="/mnt/ssd-files/docs"
REMOTE_PATH="/srv/backups/truenas/${BACKUP_ID}/"
SSH_KEY="/root/.ssh/pbs_backup_rsa"

# Logging
LOG_FILE="/var/log/backup-${BACKUP_ID}.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "=== Starting TrueNAS Backup: ${BACKUP_ID} at $(date) ==="

# Check if backup path exists
if [ ! -d "${BACKUP_PATH}" ]; then
    echo "ERROR: Backup path ${BACKUP_PATH} does not exist!"
    exit 1
fi

# Check SSH connectivity
if ! ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no "${PBS_USER}@${PBS_SERVER}" "echo 'SSH connection successful'"; then
    echo "ERROR: Cannot connect to PBS server via SSH"
    exit 1
fi

# Build exclude parameters
EXCLUDE_ARGS="--exclude='*.tmp' --exclude='**/.Trash*/**' --exclude='**/Recycle.Bin/**' --exclude='**/@eaDir/**' --exclude='**/.DS_Store' --exclude='**/*.lock' --exclude='**/~$*'"

# Run backup with rsync
echo "Syncing ${BACKUP_PATH} to ${PBS_SERVER}:${REMOTE_PATH}"

eval rsync -avz --delete \
    --progress \
    --stats \
    --human-readable \
    ${EXCLUDE_ARGS} \
    -e "ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no" \
    "${BACKUP_PATH}/" \
    "${PBS_USER}@${PBS_SERVER}:${REMOTE_PATH}"

if [ $? -eq 0 ]; then
    echo "=== Backup completed successfully at $(date) ==="
    # Create backup completion marker
    ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no "${PBS_USER}@${PBS_SERVER}" "echo '$(date)' > ${REMOTE_PATH}/.backup-completed"
else
    echo "=== Backup failed at $(date) ==="
    exit 1
fi
