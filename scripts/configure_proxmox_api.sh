#!/bin/bash

# Proxmox API Configuration Helper
# This script helps configure API access for Ansible

echo "======================================"
echo "    Proxmox API Configuration"
echo "======================================"
echo ""

echo "You have two options for Proxmox API authentication:"
echo ""
echo "1. API Token (Recommended - More Secure)"
echo "   - Log into Proxmox web interface: https://192.168.86.143:8006"
echo "   - Navigate to: Datacenter → Permissions → API Tokens"
echo "   - Create token for user: root@pam"
echo "   - Token ID: ansible"
echo "   - Uncheck 'Privilege Separation' for full access"
echo "   - Copy the generated secret (you'll only see it once!)"
echo ""
echo "2. Root Password (Less Secure)"
echo "   - Use the plaintext root password for Proxmox"
echo ""

read -p "Which method do you want to use? (token/password): " method

if [[ "$method" == "token" ]]; then
    echo ""
    echo "After creating the API token in Proxmox web interface:"
    echo ""
    read -p "Enter the Token ID (default: ansible): " token_id
    token_id=${token_id:-ansible}
    
    read -s -p "Enter the Token Secret: " token_secret
    echo ""
    
    echo ""
    echo "Now updating your vault file..."
    
    # Create temporary file with new token values
    cat << EOF > /tmp/proxmox_token.yml
# Add these lines to your vault.yml file:
proxmox_api_token_id: "$token_id"
proxmox_api_token_secret: "$token_secret"
EOF
    
    echo ""
    echo "To add these to your encrypted vault file, run:"
    echo "  ansible-vault edit vault.yml"
    echo ""
    echo "Then add these lines:"
    cat /tmp/proxmox_token.yml
    echo ""
    
    # Clean up
    rm /tmp/proxmox_token.yml
    
elif [[ "$method" == "password" ]]; then
    echo ""
    read -s -p "Enter the Proxmox root password: " root_password
    echo ""
    
    echo ""
    echo "Now updating your vault file..."
    echo ""
    echo "To add the password to your encrypted vault file, run:"
    echo "  ansible-vault edit vault.yml"
    echo ""
    echo "Then update this line:"
    echo "  proxmox_api_password: \"$root_password\""
    echo ""
    
else
    echo "Invalid selection. Please run the script again and choose 'token' or 'password'."
    exit 1
fi

echo ""
echo "After updating vault.yml, test the connection with:"
echo "  ansible-playbook -i inventory test_proxmox_auth.yml"
echo ""
echo "Then try creating an LXC container with:"
echo "  ./create_lxc.sh"
