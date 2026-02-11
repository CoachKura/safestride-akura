# Build and Deploy Script for AISRI Zone Monitor
# Quick build and copy to Garmin watch

param(
    [Parameter(Mandatory=$false)]
    [string]$DeviceId = "fr955",  # Default to Forerunner 955
    
    [Parameter(Mandatory=$false)]
    [string]$WatchDrive = ""  # Auto-detect if not specified
)

Write-Host "`n🚀 AISRI ZONE MONITOR - BUILD & DEPLOY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Configuration
$SDKPath = "C:\Garmin\ConnectIQ"
$DevKeyPath = "$SDKPath\developer_key"
$MonkeyCPath = "$SDKPath\bin\monkeyc.exe"
$ProjectPath = "c:\safestride\garmin_connectiq\AISRIZoneMonitor"
$OutputFile = "AISRIZone.prg"

# Step 1: Verify SDK Installation
Write-Host "Step 1: Checking Connect IQ SDK..." -ForegroundColor Yellow

if (-not (Test-Path $MonkeyCPath)) {
    Write-Host "❌ SDK not found at: $MonkeyCPath" -ForegroundColor Red
    Write-Host "`n📥 Please install SDK from:" -ForegroundColor Yellow
    Write-Host "   https://developer.garmin.com/connect-iq/sdk/" -ForegroundColor White
    exit 1
}
Write-Host "✅ SDK found!" -ForegroundColor Green

# Step 2: Verify Developer Key
Write-Host "`nStep 2: Checking developer key..." -ForegroundColor Yellow

if (-not (Test-Path $DevKeyPath)) {
    Write-Host "❌ Developer key not found at: $DevKeyPath" -ForegroundColor Red
    Write-Host "`n🔑 Please download developer key from:" -ForegroundColor Yellow
    Write-Host "   https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/" -ForegroundColor White
    Write-Host "`n   Save it to: $DevKeyPath" -ForegroundColor White
    exit 1
}
Write-Host "✅ Developer key found!" -ForegroundColor Green

# Step 3: Build App
Write-Host "`nStep 3: Building app for device ID: $DeviceId..." -ForegroundColor Yellow

Push-Location $ProjectPath

try {
    $buildArgs = @(
        "-f", "monkey.jungle",
        "-o", $OutputFile,
        "-y", $DevKeyPath,
        "-d", $DeviceId
    )
    
    Write-Host "Running: monkeyc $($buildArgs -join ' ')" -ForegroundColor Gray
    
    & $MonkeyCPath $buildArgs 2>&1 | Tee-Object -Variable buildOutput
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n❌ Build failed!" -ForegroundColor Red
        Write-Host $buildOutput -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    if (-not (Test-Path $OutputFile)) {
        Write-Host "`n❌ Build output file not found: $OutputFile" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    Write-Host "✅ Build successful!" -ForegroundColor Green
    
    # Show file size
    $fileSize = (Get-Item $OutputFile).Length
    Write-Host "   File size: $([math]::Round($fileSize / 1KB, 2)) KB" -ForegroundColor Gray
    
} catch {
    Write-Host "`n❌ Build error: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Step 4: Find Watch Drive (if not specified)
Write-Host "`nStep 4: Looking for Garmin watch..." -ForegroundColor Yellow

if ($WatchDrive -eq "") {
    # Auto-detect Garmin watch
    $garminDrives = Get-PSDrive -PSProvider FileSystem | Where-Object {
        Test-Path "$($_.Root)GARMIN"
    }
    
    if ($garminDrives.Count -eq 0) {
        Write-Host "⚠️  No Garmin watch detected" -ForegroundColor Yellow
        Write-Host "`n📱 To copy manually:" -ForegroundColor Cyan
        Write-Host "   1. Connect watch via USB" -ForegroundColor White
        Write-Host "   2. Wait for drive to appear" -ForegroundColor White
        Write-Host "   3. Copy $OutputFile to [DRIVE]:\GARMIN\APPS\" -ForegroundColor White
        Write-Host "`n✅ Build file ready at: $ProjectPath\$OutputFile" -ForegroundColor Green
        Pop-Location
        exit 0
    }
    
    $WatchDrive = $garminDrives[0].Root
    Write-Host "✅ Found Garmin watch at: $WatchDrive" -ForegroundColor Green
} else {
    if (-not (Test-Path $WatchDrive)) {
        Write-Host "❌ Specified drive not found: $WatchDrive" -ForegroundColor Red
        Pop-Location
        exit 1
    }
}

# Step 5: Copy to Watch
Write-Host "`nStep 5: Copying to watch..." -ForegroundColor Yellow

$appsFolder = Join-Path $WatchDrive "GARMIN\APPS"

try {
    # Create APPS folder if it doesn't exist
    if (-not (Test-Path $appsFolder)) {
        New-Item -Path $appsFolder -ItemType Directory -Force | Out-Null
    }
    
    # Copy app file
    $destination = Join-Path $appsFolder $OutputFile
    Copy-Item $OutputFile -Destination $destination -Force
    
    Write-Host "✅ Copied to: $destination" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Copy failed: $_" -ForegroundColor Red
    Write-Host "`n📱 Please copy manually:" -ForegroundColor Yellow
    Write-Host "   Copy: $ProjectPath\$OutputFile" -ForegroundColor White
    Write-Host "   To:   $appsFolder\" -ForegroundColor White
    Pop-Location
    exit 1
}

Pop-Location

# Success!
Write-Host "`n🎉 SUCCESS!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "📱 Next steps on your watch:" -ForegroundColor Cyan
Write-Host "   1. Safely eject USB (don't just unplug!)" -ForegroundColor White
Write-Host "   2. Start a Run activity" -ForegroundColor White
Write-Host "   3. Press UP → Activity Settings → Data Screens" -ForegroundColor White
Write-Host "   4. Edit screen → Add Field → AISRI Zone" -ForegroundColor White
Write-Host "   5. Start run and enjoy! 🏃‍♂️" -ForegroundColor White

Write-Host "`n⌚ Watch Details:" -ForegroundColor Cyan
Write-Host "   Device: $DeviceId" -ForegroundColor White
Write-Host "   Location: $appsFolder\$OutputFile" -ForegroundColor White

Write-Host "`n📚 For help:" -ForegroundColor Cyan
Write-Host "   See: README.md or SETUP_GUIDE.md" -ForegroundColor White
Write-Host "`n"
