# Home Assistant SSH Access Setup

## Overview
Setting up SSH access to Home Assistant (VM-204) at 192.168.86.51 for efficient automation development using VS Code Remote-SSH extension.

## Prerequisites
- VS Code with Remote-SSH extension installed
- Home Assistant OS running on VM-204
- Network access to 192.168.86.51

## Step 1: Enable SSH on Home Assistant

### Option A: Home Assistant SSH & Web Terminal Add-on (Recommended)
1. Open Home Assistant web interface: http://192.168.86.51:8123
2. Go to **Settings** → **Add-ons** → **Add-on Store**
3. Search for "SSH & Web Terminal" (official add-on)
4. Install the add-on
5. Configure the add-on:
   ```yaml
   username: hassio
   password: your_secure_password
   authorized_keys:
     - ssh-rsa AAAAB3... your_public_key_here
   sftp: true
   compatibility_mode: false
   allow_agent_forwarding: false
   allow_remote_port_forwarding: false
   allow_tcp_forwarding: false
   ```
6. Start the add-on
7. Enable "Start on boot" and "Watchdog"

### Option B: Advanced SSH & Web Terminal (More Features)
1. Add the Community Add-ons repository: https://github.com/hassio-addons/repository
2. Install "Advanced SSH & Web Terminal"
3. Configure similarly to Option A but with additional features

## Step 2: Generate SSH Key (if needed)
```bash
# Generate new SSH key for Home Assistant
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_homeassistant -C "homeassistant@192.168.86.51"

# Add to SSH agent
ssh-add ~/.ssh/id_rsa_homeassistant

# Copy public key to clipboard
cat ~/.ssh/id_rsa_homeassistant.pub
```

## Step 3: Configure SSH Connection

### Update SSH Config
Add to `~/.ssh/config`:
```
Host homeassistant
    HostName 192.168.86.51
    User root
    Port 22
    IdentityFile ~/.ssh/bill_ansible
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

### Test SSH Connection
```bash
ssh homeassistant
```

## Step 4: VS Code Remote-SSH Setup

### Install Required Extensions
1. **Remote - SSH** (ms-vscode-remote.remote-ssh)
2. **Home Assistant Config Helper** (keesschollaart.vscode-home-assistant)
3. **YAML** (redhat.vscode-yaml)

### Connect to Home Assistant
1. Open VS Code
2. Press `Ctrl+Shift+P` → "Remote-SSH: Connect to Host"
3. Select "homeassistant" or enter "root@192.168.86.51"
4. VS Code will connect and install the VS Code Server

### Configure Workspace
1. Open folder: `/config` (Home Assistant configuration directory)
2. Install recommended extensions when prompted
3. Configure YAML language server for Home Assistant:
   ```json
   {
     "yaml.schemas": {
       "https://raw.githubusercontent.com/home-assistant/core/dev/homeassistant/helpers/config_validation.py": "*.yaml"
     },
     "files.associations": {
       "*.yaml": "home-assistant"
     }
   }
   ```

## Step 5: Development Workflow

### File Structure
```
/config/
├── configuration.yaml
├── automations.yaml
├── scripts.yaml
├── scenes.yaml
├── custom_components/
├── packages/
└── www/
```

### VS Code Features for HA Development
- **IntelliSense**: Auto-completion for HA entities and services
- **Syntax Highlighting**: YAML with HA-specific highlighting
- **Validation**: Real-time YAML validation
- **Git Integration**: Version control for configurations
- **File Explorer**: Easy navigation of HA config files
- **Integrated Terminal**: Run HA CLI commands

### Useful VS Code Extensions for HA
```json
{
  "recommendations": [
    "ms-vscode-remote.remote-ssh",
    "keesschollaart.vscode-home-assistant",
    "redhat.vscode-yaml",
    "ms-vscode.vscode-json",
    "esbenp.prettier-vscode",
    "streetsidesoftware.code-spell-checker"
  ]
}
```

## Step 6: Configuration Validation

### Check Configuration Before Restart
```bash
# SSH to Home Assistant
ssh homeassistant

# Check configuration
ha core check

# Restart if valid
ha core restart
```

### VS Code Tasks for HA
Create `.vscode/tasks.json` in the HA config directory:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Check HA Config",
      "type": "shell",
      "command": "ha",
      "args": ["core", "check"],
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "Restart HA Core",
      "type": "shell",
      "command": "ha",
      "args": ["core", "restart"],
      "group": "build",
      "dependsOn": "Check HA Config"
    }
  ]
}
```

## Connection Information
- **Host**: 192.168.86.51
- **VM**: VM-204 (Home Assistant)
- **Port**: 22 (default SSH)
- **User**: hassio (or root, depending on add-on choice)
- **Config Directory**: /config

## Benefits of VS Code Remote Development
- **Syntax Highlighting**: Better than HA web editor
- **IntelliSense**: Auto-completion for entities and services
- **Git Integration**: Version control for configurations
- **Multi-file Editing**: Work on multiple files simultaneously
- **Extensions**: Rich ecosystem of YAML and HA-specific tools
- **Debugging**: Better error detection and validation
- **Backup**: Easy to commit changes to git repository

## Troubleshooting

### Common Issues
1. **Connection Refused**: Check if SSH add-on is running
2. **Permission Denied**: Verify SSH key is properly configured
3. **VS Code Server Install Fails**: Check disk space on HA
4. **Config Validation Errors**: Use `ha core check` before restart

### Useful Commands
```bash
# Check HA status
ha core info

# View logs
ha core logs

# List add-ons
ha addons

# Restart specific add-on
ha addons restart core_ssh
```

## Security Notes
- Use SSH keys instead of passwords
- Consider changing default SSH port
- Limit SSH access to specific IP ranges if needed
- Regular backup of HA configuration
- Keep SSH add-on updated

---

**Next Steps**: Install the SSH add-on in Home Assistant and test the connection!
