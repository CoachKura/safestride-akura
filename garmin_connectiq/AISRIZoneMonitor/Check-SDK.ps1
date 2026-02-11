# Quick SDK Installation Checker

Write-Host "`n=== SDK INSTALLATION CHECK ===" -ForegroundColor Cyan
Write-Host ""

# Check SDK Manager installation location first
$sdkManagerPath = "$env:APPDATA\Garmin\ConnectIQ\Sdks"
$installedSDK = Get-ChildItem $sdkManagerPath -Directory -ErrorAction SilentlyContinue | Select-Object -First 1

if ($installedSDK) {
    $sdkPath = $installedSDK.FullName
    $monkeycPath = "$sdkPath\bin\monkeyc.bat"
    $simulatorPath = "$sdkPath\bin\simulator.exe"
} else {
    # Fallback to default location
    $sdkPath = "C:\Garmin\ConnectIQ"
    $monkeycPath = "$sdkPath\bin\monkeyc.exe"
    $simulatorPath = "$sdkPath\bin\simulator.exe"
}

Write-Host "Checking SDK installation..." -ForegroundColor Yellow

if (Test-Path $monkeycPath) {
    Write-Host "[OK] SDK is INSTALLED!" -ForegroundColor Green
    Write-Host ""
    Write-Host "SDK Location: $sdkPath" -ForegroundColor Gray
    Write-Host "Compiler: $monkeycPath" -ForegroundColor Gray
    
    if (Test-Path $simulatorPath) {
        Write-Host "Simulator: $simulatorPath" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "You're ready to build! Run:" -ForegroundColor Green
    Write-Host "  .\Build-Simulator.ps1" -ForegroundColor Cyan
    Write-Host ""
    
} else {
    Write-Host "[NOT FOUND] SDK is NOT installed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Where I looked: $monkeycPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "What to do:" -ForegroundColor Yellow
    Write-Host "1. Open SDK Manager (should be running)" -ForegroundColor White
    Write-Host "2. Check box next to 'Connect IQ SDK'" -ForegroundColor White
    Write-Host "3. Click 'Install' button" -ForegroundColor White
    Write-Host "4. Wait for download to finish" -ForegroundColor White
    Write-Host "5. Run this script again to verify" -ForegroundColor White
    Write-Host ""
    Write-Host "To launch SDK Manager:" -ForegroundColor Yellow
    Write-Host "  Start-Process 'C:\Garmin\connectiq-sdk-manager-windows\sdkmanager.exe'" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""
