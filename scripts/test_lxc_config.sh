#!/bin/bash

# LXC Configuration Test Script
# This script tests the LXC mount configuration without applying changes

echo "=== LXC Configuration Test ==="
echo "Testing LXC mount point and user mapping configuration..."
echo

# Test with a specific container (change this to test different containers)
TEST_CONTAINER=${1:-"trilium"}

echo "Testing configuration for container: $TEST_CONTAINER"
echo

# Check if host vars exist
HOST_VARS_FILE="host_vars/${TEST_CONTAINER}.yml"
if [ ! -f "$HOST_VARS_FILE" ]; then
    echo "❌ ERROR: Host vars file not found: $HOST_VARS_FILE"
    exit 1
fi

echo "✅ Host vars file found: $HOST_VARS_FILE"

# Check if container_id exists in inventory
CONTAINER_ID=$(grep "^${TEST_CONTAINER} " inventory | grep -o 'container_id=[0-9]*' | cut -d'=' -f2)
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ ERROR: container_id not found for $TEST_CONTAINER in inventory"
    exit 1
fi

echo "✅ Container ID found: $CONTAINER_ID"

# Check if needed_mounts are defined
MOUNTS_DEFINED=$(grep -q "needed_mounts:" "$HOST_VARS_FILE" && echo "yes" || echo "no")
echo "📁 Mount points defined: $MOUNTS_DEFINED"

# Check if user_maps are defined
USER_MAPS_DEFINED=$(grep -q "user_maps:" "$HOST_VARS_FILE" && echo "yes" || echo "no")
echo "👤 User maps defined: $USER_MAPS_DEFINED"

echo
echo "=== Dry Run Test ==="
echo "Running Ansible in check mode (no changes will be made)..."

# Run ansible in check mode
ansible-playbook -i inventory local.yml \
  --limit "$TEST_CONTAINER" \
  --tags "lxc_mounts" \
  --check \
  --diff \
  -v

echo
echo "=== Test Complete ==="
echo "If no errors appeared above, the configuration should be safe to apply."
echo "To apply for real, run: ansible-playbook -i inventory local.yml --limit $TEST_CONTAINER --tags lxc_mounts"
