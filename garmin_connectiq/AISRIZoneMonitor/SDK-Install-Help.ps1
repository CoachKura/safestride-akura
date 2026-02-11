# SDK Manager Visual Guide

Write-Host "`n===================================" -ForegroundColor Cyan
Write-Host "   WHAT YOU SHOULD SEE" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "SDK Manager Window Layout:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  +--------------------------------+" -ForegroundColor Gray
Write-Host "  | Connect IQ SDK Manager         |" -ForegroundColor Gray
Write-Host "  +--------------------------------+" -ForegroundColor Gray
Write-Host "  |                                |" -ForegroundColor Gray
Write-Host "  | [ ] Connect IQ SDK v5.x.x      |" -ForegroundColor Gray
Write-Host "  | [ ] Device Simulators          |" -ForegroundColor Gray
Write-Host "  | [ ] Other components...        |" -ForegroundColor Gray
Write-Host "  |                                |" -ForegroundColor Gray
Write-Host "  |                                |" -ForegroundColor Gray
Write-Host "  |                  [Install]     |" -ForegroundColor Gray
Write-Host "  +--------------------------------+" -ForegroundColor Gray
Write-Host ""

Write-Host "STEP BY STEP:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Click the checkbox [ ]" -ForegroundColor White
Write-Host "   Next to 'Connect IQ SDK'" -ForegroundColor Gray
Write-Host "   It will change to [X]" -ForegroundColor Green
Write-Host ""
Write-Host "2. Click [Install] button" -ForegroundColor White
Write-Host "   (Bottom right corner)" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Wait for download" -ForegroundColor White
Write-Host "   Progress bar will show" -ForegroundColor Gray
Write-Host "   Takes 2-5 minutes" -ForegroundColor Gray
Write-Host ""
Write-Host "4. When complete:" -ForegroundColor White
Write-Host "   Close the window" -ForegroundColor Gray
Write-Host "   Run: .\Check-SDK.ps1" -ForegroundColor Cyan
Write-Host ""

Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Quick action buttons
Write-Host "QUICK ACTIONS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "[1] Launch SDK Manager again" -ForegroundColor White
Write-Host "[2] Check if SDK installed" -ForegroundColor White
Write-Host "[3] Continue (SDK already installed)" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter choice (1-3)"

switch ($choice) {
    "1" {
        Write-Host "`nLaunching SDK Manager..." -ForegroundColor Green
        Start-Process 'C:\Garmin\connectiq-sdk-manager-windows\sdkmanager.exe'
        Write-Host "Follow the steps above!" -ForegroundColor Yellow
    }
    "2" {
        Write-Host "`n"
        & ".\Check-SDK.ps1"
    }
    "3" {
        if (Test-Path 'C:\Garmin\ConnectIQ\bin\monkeyc.exe') {
            Write-Host "`nGreat! Running build..." -ForegroundColor Green
            & ".\Build-Simulator.ps1"
        } else {
            Write-Host "`nSDK not found yet!" -ForegroundColor Red
            Write-Host "Please install it first." -ForegroundColor Yellow
        }
    }
    default {
        Write-Host "`nInvalid choice. Run the script again." -ForegroundColor Red
    }
}

Write-Host ""
