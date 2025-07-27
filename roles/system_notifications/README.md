# System Notifications via ntfy

This role configures system mail forwarding to ntfy for push notifications.

## Features

- Forwards system mail (cron, dmesg, systemd failures) to ntfy
- Configures msmtp as lightweight mail relay
- Sets up postfix/mailx aliases
- Supports priority levels for different types of notifications
- Mobile-friendly push notifications

## Configuration

Configure in `group_vars/` or `host_vars/`:

```yaml
ntfy_server: "http://192.168.86.97"
ntfy_topic: "system-alerts"
system_notifications:
  enabled: true
  priorities:
    critical: "urgent"
    error: "high" 
    warning: "default"
    info: "low"
```

## Topics

- `system-alerts-{hostname}` - General system notifications
- `system-critical-{hostname}` - Critical alerts (service failures)
- `system-cron-{hostname}` - Cron job outputs
- `system-updates-{hostname}` - Update notifications

## Usage

Subscribe to notifications on your phone:
1. Install ntfy app
2. Subscribe to topic: `system-alerts-{hostname}`
3. Get push notifications for system events!
