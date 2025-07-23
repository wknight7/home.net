# Proxmox API Authentication Setup

You have several options for authenticating with the Proxmox API:

## Option 1: Use Root Password (Simplest)
Ensure that `root_passwd` in your `vault.yml` file matches the actual root password of your Proxmox server.

## Option 2: API Token (Recommended)
1. Log into your Proxmox web interface
2. Go to Datacenter → Permissions → API Tokens
3. Create a new token:
   - User: root@pam
   - Token ID: ansible
   - Privilege Separation: Unchecked (for full access)
4. Copy the token value
5. Add these variables to your `host_vars/pve.yml`:
   ```yaml
   proxmox_api_user: "root@pam!ansible"
   proxmox_api_token: "your-token-value-here"
   ```
6. Update the playbook to use tokens instead of passwords

## Option 3: Dedicated API User
1. Create a dedicated user for API access in Proxmox
2. Set appropriate permissions
3. Add credentials to your vault or host_vars

## Current Error
The authentication error suggests that either:
- The `root_passwd` in vault.yml doesn't match your Proxmox root password
- Proxmox is configured to require API tokens instead of passwords
- There might be network/SSL issues

## Quick Test
You can test your credentials manually:
```bash
curl -k -d "username=root@pam&password=YOUR_PASSWORD" https://192.168.86.143:8006/api2/json/access/ticket
```

If this returns a ticket, your credentials are correct.
