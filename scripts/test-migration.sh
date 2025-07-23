#!/bin/bash
# Simple script to test post-migration setup on one workstation

echo "=== Testing Resilient NFS Setup ==="
echo "Target: $1"
echo

if [ -z "$1" ]; then
    echo "Usage: $0 <workstation-name>"
    echo "Example: $0 dell"
    exit 1
fi

TARGET="$1"

echo "Running resilient NFS test on $TARGET..."
echo "This will use the simple post-migration tasks assuming manual prep is done."
echo

# Create a simple test playbook for the specific workstation
cat > "test-${TARGET}-temp.yml" << EOF
---
- name: Test resilient NFS setup on $TARGET
  hosts: $TARGET
  become: yes
  vars_files:
    - group_vars/workstations_new.yml
  tasks:
    - name: Test fstab setup
      include_tasks: roles/workstation/tasks/fstab_new.yml
    
    - name: Test user directory setup  
      include_tasks: roles/workstation/tasks/user_directories.yml
EOF

ansible-playbook -i inventory "test-${TARGET}-temp.yml"

echo
echo "=== Manual Verification Steps ==="
echo "SSH to $TARGET and run:"
echo "  ls -la /home/bill/"
echo "  ls -la /home/bill/documents/"
echo "  touch /home/bill/documents/test-$(date +%s).txt"
echo "  ls -la /mnt/truenas/"
echo "  mount | grep truenas"
echo
echo "If everything looks good, run full deployment:"
echo "  ansible-playbook -i inventory -l desktop,samsung,dell,lily_laptop local.yml"

# Clean up
rm -f "test-${TARGET}-temp.yml"
