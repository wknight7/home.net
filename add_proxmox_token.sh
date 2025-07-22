#!/bin/bash

# Add Proxmox API Token to Vault
echo "======================================"
echo "    Add Proxmox Token to Vault"
echo "======================================"
echo ""

echo "After creating your new Proxmox API token, you should have:"
echo "- Token ID: ansible"
echo "- Token Secret: (the long string you copied)"
echo ""

read -s -p "Enter the Token Secret from Proxmox: " token_secret
echo ""

if [[ -z "$token_secret" ]]; then
    echo "Error: Token secret cannot be empty"
    exit 1
fi

echo ""
echo "Now I'll help you add these to your vault.yml file."
echo ""
echo "The vault will be opened for editing. Add these lines:"
echo ""
echo "proxmox_api_token_id: \"ansible\""
echo "proxmox_api_token_secret: \"$token_secret\""
echo ""
echo "Then save and exit the editor."
echo ""

read -p "Press Enter to open vault for editing..."

# Open vault for editing
ansible-vault edit vault.yml

echo ""
echo "Vault updated! Now let's test the connection:"
echo ""
echo "Running: ansible-playbook -i inventory test_proxmox_auth.yml"
echo ""

# Test the connection
ansible-playbook -i inventory test_proxmox_auth.yml
