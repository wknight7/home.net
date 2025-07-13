#!/bin/bash
# Set static IPs for all LXC containers using their current DHCP assignments

# Container network information (current DHCP assignments)
declare -A containers=(
    ["101"]="192.168.86.104:wg"
    ["102"]="192.168.86.43:cloudflared"
    ["103"]="192.168.86.95:photoprism"
    ["104"]="192.168.86.78:trilium"
    ["105"]="192.168.86.49:overseer"
    ["106"]="192.168.86.79:radarr"
    ["107"]="192.168.86.66:sonarr"
    ["108"]="192.168.86.65:maintainerr"
    ["109"]="192.168.86.70:books"
    ["110"]="192.168.86.72:tautulli"
    ["111"]="192.168.86.76:bazarr"
    ["112"]="192.168.86.96:paperless"
    ["113"]="192.168.86.97:ntfy"
    ["114"]="192.168.86.101:homepage"
    ["115"]="192.168.86.103:calibre-web"
    ["116"]="192.168.86.86:sab"
    ["117"]="192.168.86.123:prowlarr"
)

# Network settings
GATEWAY="192.168.86.1"
DNS_SERVERS="8.8.8.8,1.1.1.1"

echo "Setting static IPs for all containers..."
echo "========================================"

for container_id in "${!containers[@]}"; do
    IFS=':' read -r ip hostname <<< "${containers[$container_id]}"
    
    echo "Processing Container $container_id ($hostname) -> $ip"
    
    # Create netplan configuration
    ssh pve "sudo pct exec $container_id -- tee /etc/netplan/01-static.yaml > /dev/null << EOF
network:
  version: 2
  ethernets:
    eth0:
      addresses: [$ip/24]
      gateway4: $GATEWAY
      nameservers:
        addresses: [$DNS_SERVERS]
      dhcp4: false
EOF"

    if [ $? -eq 0 ]; then
        echo "  ✓ Created netplan config for $hostname"
        
        # Apply the configuration
        ssh pve "sudo pct exec $container_id -- netplan apply" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "  ✓ Applied static IP $ip for $hostname"
        else
            echo "  ⚠ Warning: netplan apply might need manual verification for $hostname"
        fi
    else
        echo "  ✗ Failed to create config for $hostname"
    fi
    
    echo ""
done

echo "Static IP configuration complete!"
echo ""
echo "Verification commands:"
echo "====================="
for container_id in "${!containers[@]}"; do
    IFS=':' read -r ip hostname <<< "${containers[$container_id]}"
    echo "# Verify $hostname (Container $container_id)"
    echo "ssh pve \"sudo pct exec $container_id -- ip addr show eth0 | grep 'inet '\""
    echo "ping -c 1 $ip"
    echo ""
done

echo "Post-configuration steps:"
echo "========================"
echo "1. Test connectivity to all services"
echo "2. Update any hardcoded IPs in configurations"
echo "3. Remove DHCP reservations from Google Home app (no longer needed)"
echo "4. Consider expanding IP range if you plan to add more containers"
