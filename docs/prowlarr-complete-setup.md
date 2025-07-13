# Prowlarr Complete Setup Configuration

## UPDATED Container Information (Post-Rebuild)

### Container IDs and Services:
- **Prowlarr**: Container 117 → http://192.168.86.123:9696
- **Sonarr**: Container 107 → http://192.168.86.66:8989
- **Radarr**: Container 106 → http://192.168.86.79:7878
- **Sabnzbd**: Container 116 → http://192.168.86.86:7777  
- **Bazarr**: Container 111 → http://192.168.86.76:6767

### API Keys (Retrieved from containers):
- **Sonarr API Key**: `df4282b8508c432f8e641aff095ed830`
- **Radarr API Key**: `f541721a0ef74d63845ffd5a99107039`
- **Sabnzbd API Key**: `lq6suq3i0iinj0u11ujzzzmnky3l7uoo`

## Quick Setup Steps:

### 1. Access Prowlarr
Open: http://192.168.86.123:9696

### 2. Add Applications (Settings > Apps)

#### Sonarr Configuration:
- **Name**: Sonarr
- **Prowlarr Server**: http://192.168.86.123:9696
- **Sonarr Server**: http://192.168.86.66:8989
- **API Key**: df4282b8508c432f8e641aff095ed830
- **Sync Categories**: TV (5000), TV/Anime (5070)

#### Radarr Configuration:
- **Name**: Radarr  
- **Prowlarr Server**: http://192.168.86.123:9696
- **Radarr Server**: http://192.168.86.79:7878
- **API Key**: f541721a0ef74d63845ffd5a99107039
- **Sync Categories**: Movies (2000)

### 3. Add Download Client (Settings > Download Clients)

#### Sabnzbd Configuration:
- **Name**: Sabnzbd
- **Enable**: Yes
- **Host**: 192.168.86.86
- **Port**: 7777
- **API Key**: lq6suq3i0iinj0u11ujzzzmnky3l7uoo
- **Category**: (Optional: movies, tv, etc.)
- **Priority**: 25

### 4. Recommended Indexers to Add:

#### Free/Public (No registration needed):
- **EZTV** (TV Shows)
- **YTS/YIFY** (Movies)  
- **1337x** (General)
- **The Pirate Bay** (General)
- **Torrentz2** (Meta-search)

#### Premium/Usenet (Require accounts):
- **NZBgeek** (Premium Usenet)
- **DrunkenSlug** (Usenet)
- **NZB.su** (Usenet)
- **NZBFinder** (Usenet)

### 4a. API Limits & Rate Limiting (IMPORTANT):

#### Recommended API Limits by Indexer Type:

**Free/Public Indexers:**
- **Requests per minute**: 5-10 (be conservative)
- **Daily limit**: 100-500 requests
- **Search delay**: 2-3 seconds between requests

**Premium/Private Indexers:**
- **Requests per minute**: 20-60 (check your account limits)
- **Daily limit**: 1000-5000 requests (varies by provider)
- **Search delay**: 1-2 seconds

**Usenet Indexers (Paid):**
- **Requests per minute**: 60-120 (usually higher limits)
- **Daily limit**: 5000+ requests
- **Search delay**: 0.5-1 second

#### How to Set API Limits in Prowlarr:
1. Go to **Indexers** page
2. Edit each indexer (click the indexer name or edit icon)
3. Look for these settings (field names may vary by indexer):
   - **API Requests per Day** or **Daily API Limit**
   - **API Requests per Hour** or **Hourly API Limit** 
   - **Request Delay** or **Query Delay**
   - **Enable RSS** checkbox (use sparingly)
4. **Alternative locations**:
   - Settings > Indexers > Default settings
   - Individual indexer configuration pages
   - Some limits may be under "Advanced Settings"

**Note**: Different indexers may have different field names for rate limiting. Common variations include:
- "API Limit", "Request Limit", "Rate Limit"
- "Grab Limit", "Download Limit", "Daily Quota"
- "Search Delay", "Request Interval", "Cooldown"

#### If You Don't See Limit Fields:
Some indexers may not expose rate limiting settings directly in Prowlarr. In those cases:

1. **Check indexer documentation** - visit the indexer's website for API limits
2. **Use general Prowlarr settings**:
   - Settings > Indexers > "Minimum Seeders" (for torrents)
   - Settings > Indexers > "Retention" (for usenet)
3. **Monitor usage manually** - watch for error messages in logs
4. **Global RSS settings**: Settings > Indexers > RSS Sync Interval (set to 25+ minutes)

#### Prowlarr Global Settings to Check:
- **Settings > General > Updates**: Set RSS sync intervals
- **Settings > Indexers**: Default minimum seeders, retention settings
- **System > Status**: Monitor for indexer health warnings

#### Critical Guidelines:
- **Start conservative** - you can always increase limits later
- **Monitor indexer stats** - check for failed requests in Prowlarr logs
- **Respect indexer rules** - check each site's API documentation
- **Use RSS sparingly** - only enable for your most reliable indexers
- **Stagger searches** - don't hammer all indexers simultaneously

#### Signs You Need to Lower Limits:
- Getting 429 (Too Many Requests) errors
- Indexer temporarily banning your IP
- Frequent timeouts or failed searches
- Indexer performance degrading

#### Pro Tips:
- **Quality over quantity** - 3-5 good indexers beats 20 unreliable ones
- **Use categories wisely** - only sync relevant categories to reduce API calls
- **Monitor health regularly** - disable problematic indexers temporarily

### 5. Testing & Sync:
1. Test all apps: Settings > Apps → Click "Test" on each
2. Test download client: Settings > Download Clients → Click "Test"  
3. Test indexers: Indexers → Click "Test" on each indexer
4. **Sync Apps**: Click "Sync App Indexers" to push all indexers to Sonarr/Radarr

### 6. Media Stack Status Check:

You can verify all services are running with these commands:

```bash
# Check service status
curl -s -o /dev/null -w "%{http_code}" http://192.168.86.123:9696  # Prowlarr (expect 302)
curl -s -o /dev/null -w "%{http_code}" http://192.168.86.66:8989   # Sonarr (expect 200)
curl -s -o /dev/null -w "%{http_code}" http://192.168.86.79:7878   # Radarr (expect 200)
curl -s -o /dev/null -w "%{http_code}" http://192.168.86.86:7777   # Sabnzbd (expect 303)
curl -s -o /dev/null -w "%{http_code}" http://192.168.86.76:6767   # Bazarr (expect 200)
```

### 7. Integration Benefits:

Once configured, Prowlarr will:
- **Centrally manage all indexers** in one place
- **Automatically sync indexers** to Sonarr and Radarr
- **Test and monitor indexer health** 
- **Handle indexer updates** automatically
- **Provide unified search** across all indexers
- **Manage rate limiting** and API quotas

### 8. Post-Setup Automation:

- **RSS Sync**: Enable for active indexers (15-30 min intervals)
- **Health Monitoring**: Check System > Status regularly
- **Log Review**: Monitor System > Logs for issues
- **Indexer Stats**: Review response times in Indexers page

### 9. API Monitoring & Maintenance:

#### Daily Monitoring:
```bash
# Check Prowlarr logs for API errors
ssh pve "sudo pct exec 117 -- tail -f /var/log/prowlarr/prowlarr.txt | grep -i 'api\|limit\|error'"

# Monitor indexer response times
# Access Prowlarr > Indexers page to see stats
```

#### Weekly Tasks:
- Review indexer statistics (success/failure rates)
- Adjust API limits based on performance
- Disable consistently failing indexers
- Check for indexer definition updates

#### Monthly Tasks:
- Review and optimize indexer selection
- Update indexer credentials if needed
- Clean up old search history
- Backup Prowlarr configuration
