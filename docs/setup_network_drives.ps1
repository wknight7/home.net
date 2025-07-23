# PowerShell script to set up network drives on Windows
# This must be run directly on the Windows machine (not via WinRM)

Write-Host "Setting up network drives for TrueNAS connection..."

# Clear any existing connections
Write-Host "Clearing existing network connections..."
net use * /delete /yes

# Add stored credentials to Windows Credential Manager
Write-Host "Adding stored credentials for TrueNAS server..."
cmdkey /add:"192.168.86.109" /user:"bill" /pass:"I4V69b^WOR!@8OxVD4mE"

# Wait a moment for credentials to be stored
Start-Sleep -Seconds 2

# Map network drives
Write-Host "Mapping network drives..."

$drives = @{
    "H:" = "\\192.168.86.109\Documents"
    "I:" = "\\192.168.86.109\Downloads" 
    "M:" = "\\192.168.86.109\media"
    "P:" = "\\192.168.86.109\paper"
    "S:" = "\\192.168.86.109\shared_files"
    "W:" = "\\192.168.86.109\workouts"
}

foreach ($drive in $drives.GetEnumerator()) {
    Write-Host "Mapping $($drive.Key) to $($drive.Value)..."
    try {
        net use $drive.Key $drive.Value /persistent:yes
        Write-Host "✅ Successfully mapped $($drive.Key)" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to map $($drive.Key): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nNetwork drive setup complete!"
Write-Host "Checking final status..."
net use

Write-Host "`nIf drives show as 'Unavailable', try:"
Write-Host "1. Open File Explorer"
Write-Host "2. Click on each drive to authenticate"
Write-Host "3. Use username: bill"
Write-Host "4. Use password: I4V69b^WOR!@8OxVD4mE"
Write-Host "5. Check 'Remember my credentials'"
