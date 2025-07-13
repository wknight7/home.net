# Google Fiber Router IP Reservation Automation

## Current Problem:
Google Fiber routers use the Google Home app for configuration, which doesn't provide:
- Bulk IP reservations
- Command-line access
- API for automation
- Easy export/import of DHCP reservations

## Solution Options:

### Option 1: Semi-Automated MAC Address Collection
First, let's collect all your container MAC addresses and current IPs:

```bash
# Get all container MAC addresses and IPs
echo "Container,MAC,IP,Hostname" > /tmp/container_network_info.csv
for id in {101..117}; do
    hostname=$(ssh pve "sudo cat /etc/pve/lxc/$id.conf 2>/dev/null | grep 'hostname:' | cut -d' ' -f2")
    mac=$(ssh pve "sudo cat /etc/pve/lxc/$id.conf 2>/dev/null | grep 'hwaddr=' | sed 's/.*hwaddr=\([^,]*\).*/\1/'")
    ip=$(ssh pve "sudo pct exec $id -- ip -4 addr show eth0 2>/dev/null | grep inet | awk '{print \$2}' | cut -d/ -f1")
    if [ ! -z "$hostname" ] && [ ! -z "$mac" ] && [ ! -z "$ip" ]; then
        echo "$id,$mac,$ip,$hostname"
    fi
done | sort
```

### Option 2: Google Home App Batch Process
Unfortunately, Google Home app requires manual entry, but you can streamline it:

1. **Prepare a list** (from the script above)
2. **Use voice commands**: "Hey Google, reserve IP 192.168.86.66 for device with MAC BC:24:11:..."
3. **Screen recording**: Record the process once, then follow the pattern

### Option 3: Router Replacement (Best Long-term)
Replace the Google Fiber router's WiFi/DHCP with your own equipment:

#### Bridge Mode Setup:
1. **Keep Google Fiber box** (required for internet)
2. **Add your own router** behind it
3. **Popular options**:
   - **UniFi Dream Machine** (enterprise-grade, web interface)
   - **pfSense box** (open source, powerful)
   - **ASUS AX6000** (consumer, good web interface)

#### Benefits:
- Full control over DHCP reservations
- Command-line access
- Bulk configuration
- Better firewall rules
- VLANs for segmentation

### Option 4: DNS/DHCP Server Override
Run your own DHCP server on the network:

```bash
# Install dnsmasq on a dedicated container
ssh pve "sudo pct create 120 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \\
  --hostname dhcp-server \\
  --memory 512 \\
  --cores 1 \\
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \\
  --storage local-lvm"

# Configure dnsmasq with static reservations
# This requires disabling DHCP on Google router (if possible)
```

### Option 5: Ansible Automation for Documentation
At minimum, let's automate the documentation:

```yaml
# Create ansible playbook to generate reservation list
- name: Generate DHCP reservation list
  hosts: localhost
  tasks:
    - name: Get container network info
      shell: |
        for id in {101..117}; do
          hostname=$(ssh pve "sudo cat /etc/pve/lxc/$id.conf 2>/dev/null | grep 'hostname:' | cut -d' ' -f2")
          mac=$(ssh pve "sudo cat /etc/pve/lxc/$id.conf 2>/dev/null | grep 'hwaddr=' | sed 's/.*hwaddr=\\([^,]*\\).*/\\1/'")
          ip=$(ssh pve "sudo pct exec $id -- ip -4 addr show eth0 2>/dev/null | grep inet | awk '{print $2}' | cut -d/ -f1")
          if [ ! -z "$hostname" ] && [ ! -z "$mac" ] && [ ! -z "$ip" ]; then
            echo "Reserve $ip for $hostname ($mac)"
          fi
        done
      register: reservations
    
    - name: Create reservation checklist
      copy:
        content: |
          # DHCP Reservations Checklist for Google Home App
          {{ reservations.stdout }}
        dest: /tmp/dhcp_reservations.txt
```

## Recommended Approach:

### Immediate (Next 30 minutes):
1. Run the MAC/IP collection script above
2. Use Google Home app to manually reserve the critical services:
   - Prowlarr: 192.168.86.123
   - Sonarr: 192.168.86.66  
   - Radarr: 192.168.86.79
   - Sabnzbd: 192.168.86.86
   - Bazarr: 192.168.86.76

### Medium-term (Next month):
Consider a proper router upgrade for better network management.

### Alternative Workaround:
Use **static IP configuration** in the containers themselves instead of DHCP reservations:

```bash
# Set static IP in container (example for Prowlarr)
ssh pve "sudo pct exec 117 -- tee /etc/netplan/01-static.yaml << EOF
network:
  version: 2
  ethernets:
    eth0:
      addresses: [192.168.86.123/24]
      gateway4: 192.168.86.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
EOF"
ssh pve "sudo pct exec 117 -- netplan apply"
```

Would you like me to create the MAC address collection script for your containers so you can at least streamline the manual Google Home app process?
