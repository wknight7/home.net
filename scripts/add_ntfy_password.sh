#!/bin/bash

echo "Adding ntfy_password to vault.yml"
echo ""
echo "The ntfy system-notifications user password is: Jackson0317!"
echo ""
echo "You need to add this line to your vault.yml:"
echo 'ntfy_password: "Jackson0317!"'
echo ""
echo "Opening vault for editing..."
echo ""
read -p "Press Enter to continue..."

ansible-vault edit vault.yml
