# Windows Network Drive Management Script
# This script maps network drives to your TrueNAS server
# Update the $TrueNASIP variable when your TrueNAS IP address changes

param(
    [string]$TrueNASIP = "192.168.86.109",
    [string]$Username = $env:USERNAME,
    [switch]$Disconnect = $false
)

# Define drive mappings (modify as needed)
$NetworkDrives = @(
    @{ Letter = "H:"; Path = "\\$TrueNASIP\home\$Username\Documents"; Name = "User Documents" },
    @{ Letter = "I:"; Path = "\\$TrueNASIP\home\$Username\Downloads"; Name = "User Downloads" },
    @{ Letter = "M:"; Path = "\\$TrueNASIP\media"; Name = "Media" },
    @{ Letter = "P:"; Path = "\\$TrueNASIP\paperless"; Name = "Paperless Documents" },
    @{ Letter = "S:"; Path = "\\$TrueNASIP\shared_files"; Name = "Shared Files" },
    @{ Letter = "W:"; Path = "\\$TrueNASIP\workouts"; Name = "Workouts" }
)

if ($Disconnect) {
    Write-Host "Disconnecting network drives..." -ForegroundColor Yellow
    foreach ($drive in $NetworkDrives) {
        try {
            net use $drive.Letter /delete /yes
            Write-Host "Disconnected $($drive.Letter) ($($drive.Name))" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to disconnect $($drive.Letter): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "Mapping network drives to TrueNAS server at $TrueNASIP..." -ForegroundColor Yellow
    
    # Prompt for credentials (you may want to modify this for automation)
    $credential = Get-Credential -Message "Enter TrueNAS SMB credentials"
    
    foreach ($drive in $NetworkDrives) {
        try {
            # Disconnect existing drive if it exists
            net use $drive.Letter /delete /yes 2>$null
            
            # Map the drive
            $netUseCmd = "net use $($drive.Letter) `"$($drive.Path)`" /user:$($credential.UserName) $($credential.GetNetworkCredential().Password) /persistent:yes"
            Invoke-Expression $netUseCmd
            Write-Host "Mapped $($drive.Letter) to $($drive.Path) ($($drive.Name))" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to map $($drive.Letter): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host "`nTesting drive connectivity..." -ForegroundColor Yellow
    foreach ($drive in $NetworkDrives) {
        if (Test-Path $drive.Letter) {
            Write-Host "$($drive.Letter) ($($drive.Name)): Connected" -ForegroundColor Green
        } else {
            Write-Host "$($drive.Letter) ($($drive.Name)): Failed" -ForegroundColor Red
        }
    }
}

Write-Host "`nScript completed." -ForegroundColor Cyan
