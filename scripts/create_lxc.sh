#!/bin/bash

# LXC Container Creation Script
# This script runs the Ansible playbook to create a new Proxmox LXC container

set -e

echo "======================================"
echo "    LXC Container Creation Tool"
echo "======================================"
echo ""

# Check if we're in the correct directory
if [[ ! -f "create_lxc.yml" ]]; then
    echo "Error: create_lxc.yml not found. Please run this script from the home.net directory."
    exit 1
fi

# Check if inventory file exists
if [[ ! -f "inventory" ]]; then
    echo "Error: inventory file not found. Please run this script from the home.net directory."
    exit 1
fi

echo "This script will:"
echo "1. Prompt you for container specifications"
echo "2. Create a new LXC container on Proxmox"
echo "3. Configure the container with your bootstrap script"
echo "4. Add the container to your Ansible inventory"
echo ""

read -p "Do you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Starting LXC container creation..."
echo ""

# Run the Ansible playbook
ansible-playbook -i inventory create_lxc.yml

echo ""
echo "======================================"
echo "    Container creation completed!"
echo "======================================"
