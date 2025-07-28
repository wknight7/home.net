#!/bin/bash
# Permanent setup script for ntfy desktop notifications as systemd user service
# Run this on your workstation

echo "Setting up permanent ntfy desktop notifications..."

# Get the ntfy password from user
echo "You'll need your ntfy password. Check with: grep ntfy_password ~/git/home.net/vault.yml"
read -s -p "Enter ntfy password: " NTFY_PASSWORD
echo

# Create user directories
mkdir -p ~/.config/ntfy
mkdir -p ~/.config/systemd/user

# Create user config
cat > ~/.config/ntfy/client.yml << EOF
# ntfy client configuration for desktop notifications
default-host: "http://192.168.86.97"
default-user: "system-notifications"
default-password: "$NTFY_PASSWORD"

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

  - topic: "personal-$(whoami)"
    command: "notify-send -u normal -t 5000 'Personal: \$title' '\$message'"

# Client settings
cache-duration: "12h"
keepalive-interval: "45s"
log-level: "info"
EOF

# Create systemd user service
cat > ~/.config/systemd/user/ntfy-desktop.service << EOF
[Unit]
Description=ntfy desktop notification service
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=exec
ExecStart=/usr/local/bin/ntfy subscribe --config %h/.config/ntfy/client.yml
Restart=always
RestartSec=30
Environment=DISPLAY=:0

[Install]
WantedBy=default.target
EOF

# Reload systemd user daemon
systemctl --user daemon-reload

# Enable and start the service
systemctl --user enable ntfy-desktop.service
systemctl --user start ntfy-desktop.service

# Check status
echo ""
echo "Service status:"
systemctl --user status ntfy-desktop.service

echo ""
echo "Setup complete! Your workstation will now show desktop notifications for:"
echo "  - system-alerts-$(hostname)"
echo "  - workstation-$(hostname)"
echo "  - broadcast"
echo "  - test"
echo "  - personal-$(whoami)"
echo ""
echo "To test, run:"
echo "  ntfy publish test 'Hello Desktop!'"
echo ""
echo "To check service logs:"
echo "  journalctl --user -u ntfy-desktop.service -f"
