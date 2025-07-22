#!/bin/bash
# Quick Test Backup Script for TrueNAS to PBS
# Test the backup connection and small directory sync

set -e

# Configuration
PBS_SERVER="192.168.86.33"
PBS_USER="bill"
SSH_KEY="/root/.ssh/pbs_backup_rsa"
TEST_PATH="/mnt/ssd-files/workouts"
REMOTE_PATH="/srv/backups/truenas/ssd-workouts/"

echo "=== Testing TrueNAS to PBS Backup Connection ==="

# Test SSH connection
echo "Testing SSH connection..."
if ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no "${PBS_USER}@${PBS_SERVER}" "echo 'SSH connection successful'"; then
    echo "✅ SSH connection working"
else
    echo "❌ SSH connection failed"
    exit 1
fi

# Check source directory
if [ ! -d "${TEST_PATH}" ]; then
    echo "❌ Source directory ${TEST_PATH} does not exist"
    exit 1
else
    echo "✅ Source directory exists"
fi

# Test rsync
echo "Testing rsync backup..."
rsync -avz --dry-run \
    --exclude='*.tmp' \
    --exclude='**/.Trash*/**' \
    -e "ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no" \
    "${TEST_PATH}/" \
    "${PBS_USER}@${PBS_SERVER}:${REMOTE_PATH}"

if [ $? -eq 0 ]; then
    echo "✅ Dry run successful - ready for real backup"
    echo ""
    echo "To run actual backup:"
    echo "  /mnt/ssd-files/scripts/test-pbs-backup.sh --real"
else
    echo "❌ Dry run failed"
    exit 1
fi

# If --real flag is provided, do the actual backup
if [ "$1" = "--real" ]; then
    echo ""
    echo "=== Running REAL backup ==="
    rsync -avz --progress \
        --exclude='*.tmp' \
        --exclude='**/.Trash*/**' \
        -e "ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no" \
        "${TEST_PATH}/" \
        "${PBS_USER}@${PBS_SERVER}:${REMOTE_PATH}"
    
    if [ $? -eq 0 ]; then
        echo "✅ Backup completed successfully!"
    else
        echo "❌ Backup failed"
        exit 1
    fi
fi
