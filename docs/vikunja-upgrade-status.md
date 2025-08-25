# Vikunja Upgrade Status and History

**Last Updated:** August 25, 2025  
**Current Status:** STABLE - Running Vikunja v0.24.5  
**Next Action:** Monitor for stable v1.0.x releases

## Current Working Configuration

### Container Details
- **LXC Container:** ID 115 "tasks" at 192.168.86.126
- **OS:** Alpine Linux (unprivileged LXC)
- **Docker:** Enabled with proper user namespace mappings
- **Vikunja Version:** v0.24.5 (STABLE)
- **Database:** PostgreSQL 16

### Security Configuration
- **JWT Secret:** `uWY2reFu6QEc3U3DuftTSmZh0grciwB1Bq9NJQWzUZUiFMiIXQdRkX27puYm10L3` (64 chars)
- **Database Password:** `JsIeeI6BDo8E5F6e5IS5hR2PK89RMMub` (32 chars)
- **User Account:** bill / `m8$ao5MIMacTee@MjkgB`

### Working Files
- **LXC Config:** `/etc/pve/lxc/115.conf` (with user namespace mappings from SABnzbd container)
- **Docker Compose:** `/opt/vikunja/docker-compose.yml` (pinned to vikunja/vikunja:0.24.5)

## Problem History

### Initial Issue
- **Date:** August 25, 2025
- **Problem:** Unable to save "Default project" setting in Vikunja
- **Error:** "Unauthorized" error in lower left corner
- **Root Cause:** Insecure default JWT secret

### Authentication Crisis (v1.0.0-rc1)
- **Problem:** After fixing JWT, user registration and login completely broken
- **Symptoms:** 401 Unauthorized errors on all authentication endpoints
- **Version:** Vikunja v1.0.0-rc1 (latest at time)
- **Workarounds Attempted:**
  - Regenerated all security tokens
  - Enabled registration via environment variables
  - Created user via CLI: `docker exec vikunja /app/vikunja/vikunja user create`
  - **Result:** CLI user creation worked, but web login still broken

### Container Recreation Journey
- **Reason:** Started with insecure defaults, decided to rebuild with proper security
- **Challenge:** Docker in unprivileged LXC required user namespace mappings
- **Solution:** Copied working configuration from SABnzbd container (ID 112)
- **Key Config:** Added lxc.idmap entries and features: fuse=1,nesting=1

### Version Downgrade Success
- **Discovery:** User provided documentation showing v1.0.0-rc1 has known authentication bugs
- **Action:** Downgraded from `latest` (RC1) to stable `vikunja/vikunja:0.24.5`
- **Result:** ✅ Authentication works, user can log in, original settings save issue resolved

## Technical Lessons Learned

1. **Release Candidates are Risky:** v1.0.0-rc1 had fundamental authentication bugs
2. **Default Secrets are Dangerous:** Always generate secure JWT secrets (64+ characters)
3. **LXC + Docker Complexity:** User namespace mappings critical for unprivileged containers
4. **CLI Bypass:** Command line tools can work when web interfaces are broken
5. **Version Pinning:** Always pin to specific stable versions in production

## Upgrade Safety Criteria

### ❌ DO NOT UPGRADE IF:
- Version is RC, alpha, beta, or pre-release
- Less than 2-4 weeks since release (wait for community feedback)
- GitHub issues mention authentication problems
- No clear migration documentation provided

### ✅ SAFE TO UPGRADE WHEN:
- Stable release with patch version (e.g., v1.0.1, v1.0.2)
- Community reports confirm authentication works
- Official release notes mention bug fixes for login/registration
- At least 4 weeks of community testing
- Clear upgrade path documented

### Pre-Upgrade Checklist
1. **Backup Database:**
   ```bash
   cd /home/bill/git/lxc
   ansible tasks -m shell -a "cd /opt/vikunja && docker-compose exec vikunja-db pg_dump -U vikunja vikunja > /tmp/vikunja-backup-$(date +%Y%m%d).sql"
   ```

2. **Test in Development:**
   - Create test container with new version
   - Verify authentication works
   - Test all critical features

3. **Upgrade Process:**
   ```bash
   # Update docker-compose.yml with new version
   cd /opt/vikunja
   docker-compose down
   docker-compose pull
   docker-compose up -d
   ```

4. **Rollback Plan:**
   ```bash
   # If upgrade fails, revert to v0.24.5
   # Edit docker-compose.yml back to vikunja/vikunja:0.24.5
   docker-compose down
   docker-compose up -d
   # Restore database if needed
   ```

## Current Status Summary

**✅ WORKING:** Vikunja v0.24.5 with full authentication and settings functionality  
**✅ SECURE:** All default secrets replaced with strong generated values  
**✅ STABLE:** Container and Docker configuration proven reliable  

**📝 MONITORING:** Watch GitHub releases for stable v1.0.x without authentication issues  

---

## Questions for Future Upgrade Decisions

When considering an upgrade, check these questions:

1. **Is the new version a stable release (not RC/beta/alpha)?**
2. **Have at least 4 weeks passed since the release?**
3. **Are there GitHub issues mentioning authentication problems?**
4. **Do release notes specifically mention fixing login/registration bugs?**
5. **Has the community reported successful upgrades?**
6. **Do we have a recent database backup?**
7. **Can we test the upgrade in a development environment first?**

**Decision Rule:** All questions 1-2 and 4-7 must be YES, and question 3 must be NO before upgrading.
