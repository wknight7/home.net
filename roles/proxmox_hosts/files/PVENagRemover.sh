#!/bin/bash

# Backup the original file
cp /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js.backup

# Apply the working fix - invert the subscription check logic
sed -i 's/data\.status\.toLowerCase() == '\''active'\''/data.status.toLowerCase() !== '\''active'\''/g' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js