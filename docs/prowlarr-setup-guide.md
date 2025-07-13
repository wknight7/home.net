# Prowlarr Configuration Guide

## Your Media Stack Overview

**Prowlarr** (Index Manager): http://192.168.86.123:9696
**Sonarr** (TV Shows): http://192.168.86.66:8989  
**Radarr** (Movies): http://192.168.86.79:7878
**Sabnzbd** (Downloads): http://192.168.86.86:7777
**Bazarr** (Subtitles): http://192.168.86.76:6767

## Step 1: Initial Prowlarr Setup

1. Open Prowlarr at http://192.168.86.123:9696
2. Complete the initial setup wizard
3. Set authentication if desired (Settings > General > Security)

## Step 2: Configure Applications (Apps)

Go to Settings > Apps and add your applications:

### Sonarr (TV Shows)
- **Name**: Sonarr
- **Prowlarr Server**: http://192.168.86.123:9696
- **Sonarr Server**: http://192.168.86.66:8989
- **API Key**: (Get from Sonarr > Settings > General)
- **Sync Categories**: TV (5000), TV/Anime (5070)

### Radarr (Movies)  
- **Name**: Radarr
- **Prowlarr Server**: http://192.168.86.123:9696
- **Radarr Server**: http://192.168.86.79:7878
- **API Key**: (Get from Radarr > Settings > General)
- **Sync Categories**: Movies (2000)

## Step 3: Configure Download Clients

Go to Settings > Download Clients:

### Sabnzbd
- **Name**: Sabnzbd
- **Enable**: Yes
- **Host**: 192.168.86.86
- **Port**: 7777
- **API Key**: (Get from Sabnzbd > Config > General)
- **Category**: (Optional: movies, tv, etc.)
- **Priority**: 25

## Step 4: Add Indexers

Go to Indexers > Add Indexer and add popular indexers like:

### Free/Public Indexers (No API key required):
- **EZTV** (TV Shows)
- **YTS** (Movies)
- **The Pirate Bay** (General)
- **1337x** (General)

### Private/Paid Indexers (Require registration/API keys):
- **NZBgeek** (Premium Usenet)
- **DrunkenSlug** (Usenet)
- **NZB.su** (Usenet)

## Step 5: Test Configuration

1. **Test Apps**: Go to Settings > Apps, click "Test" on each app
2. **Test Download Clients**: Go to Settings > Download Clients, click "Test"
3. **Test Indexers**: Go to Indexers, click "Test" on each indexer
4. **Sync Apps**: Click "Sync App Indexers" to push indexers to Sonarr/Radarr

## API Keys Retrieval Commands

Run these commands to get the API keys:

```bash
# Get Sonarr API Key
ssh pve "sudo pct exec 107 -- grep -r 'ApiKey' /home/bill/.config/Sonarr/"

# Get Radarr API Key  
ssh pve "sudo pct exec 106 -- grep -r 'ApiKey' /home/bill/.config/Radarr/"

# Get Sabnzbd API Key
ssh pve "sudo pct exec 116 -- grep '^api_key' /home/bill/.sabnzbd/sabnzbd.ini"
```

## Recommended Indexer Categories

- **Movies**: 2000-2099
- **TV Shows**: 5000-5099  
- **Anime**: 5070
- **Music**: 3000-3099
- **Books**: 7000-7099

## Automation Tips

1. **Enable RSS Sync**: Indexers > Settings > Enable RSS sync for automatic updates
2. **Sync Interval**: Set to 15-30 minutes for active indexers
3. **Health Check**: Regularly check System > Status for any issues
4. **Log Monitoring**: Check System > Logs for errors or warnings

## Maintenance

- **Update Indexers**: Prowlarr will automatically update indexer definitions
- **Monitor Stats**: Check Indexers page for response times and success rates
- **Clean Failed**: Periodically clean failed downloads in download clients

## Security Notes

- **API Keys**: Keep API keys secure and don't share them
- **Network Access**: Prowlarr needs network access to all apps and indexers
- **VPN**: Consider using a VPN for private tracker access
- **Authentication**: Enable authentication for web interface if exposed externally

## Troubleshooting

1. **Connection Failed**: Check IP addresses and ports
2. **API Key Invalid**: Regenerate API keys in respective applications
3. **Indexer Down**: Check indexer status on their websites
4. **Downloads Stuck**: Check download client and disk space
5. **Categories Missing**: Ensure proper category mapping in apps

Visit the Prowlarr web interface to start configuration: http://192.168.86.123:9696
