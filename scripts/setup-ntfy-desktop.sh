#!/bin/bash
# Quick setup script for ntfy desktop notifications
# Run this on your workstation

echo "Setting up ntfy desktop notifications..."

# Create user config directory
mkdir -p ~/.config/ntfy

# Create a simple user config for notifications
cat > ~/.config/ntfy/client.yml << 'EOF'
# ntfy client configuration for desktop notifications
default-host: "http://192.168.86.97"
default-user: "system-notifications"
default-password: "YOUR_NTFY_PASSWORD_HERE"

# Desktop notification command
default-command: "notify-send -u normal -t 10000 'ntfy: \$title' '\$message'"

# Subscriptions for this workstation
subscribe:
  - topic: "system-alerts-$(hostname)"
    command: "notify-send -u critical -t 0 'System Alert: \$title' '\$message'"
  
  - topic: "workstation-$(hostname)"
    command: "notify-send -u normal -t 5000 'Workstation: \$title' '\$message'"
  
  - topic: "broadcast"
    command: "notify-send -u low -t 3000 'Broadcast: \$title' '\$message'"

  - topic: "test"
    command: "notify-send -u normal -t 5000 'Test: \$title' '\$message'"
EOF

echo "Configuration created. Now starting ntfy subscriber..."
echo "You should see desktop notifications for messages sent to:"
echo "  - system-alerts-$(hostname)"
echo "  - workstation-$(hostname)" 
echo "  - broadcast"
echo "  - test"
echo ""
echo "To test, run in another terminal:"
echo "  ntfy publish test 'Hello Desktop!'"
echo ""
echo "Starting ntfy subscriber (press Ctrl+C to stop)..."

# Start the subscriber
/usr/local/bin/ntfy subscribe --config ~/.config/ntfy/client.yml
