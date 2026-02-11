# Build for Simulator (No Developer Key Needed!)
# Quick test script for AISRI Zone Monitor

param(
    [Parameter(Mandatory=$false)]
    [string]$DeviceId = "fr265"
)

Write-Host "`n🧪 SIMULATOR BUILD - NO KEY NEEDED" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Configuration - Auto-detect SDK location
$SDKPath = "$env:APPDATA\Garmin\ConnectIQ\Sdks"
$installedSDK = Get-ChildItem $SDKPath -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if ($installedSDK) {
    $SDKPath = $installedSDK.FullName
    $MonkeyCPath = "$SDKPath\bin\monkeyc.bat"
    $SimulatorPath = "$SDKPath\bin\simulator.exe"
} else {
    # Fallback to default location
    $SDKPath = "C:\Garmin\ConnectIQ"
    $MonkeyCPath = "$SDKPath\bin\monkeyc.exe"
    $SimulatorPath = "$SDKPath\bin\simulator.exe"
}
$ProjectPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutputFile = "AISRIZone.prg"

# Step 1: Verify SDK
Write-Host "Step 1: Checking SDK..." -ForegroundColor Yellow
if (-not (Test-Path $MonkeyCPath)) {
    Write-Host "❌ SDK not found!" -ForegroundColor Red
    Write-Host "Please install from: https://developer.garmin.com/connect-iq/sdk/" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ SDK found!`n" -ForegroundColor Green

# Step 2: Build for Simulator (no key needed!)
Write-Host "Step 2: Building for simulator..." -ForegroundColor Yellow
Write-Host "Device: $DeviceId" -ForegroundColor Gray

Push-Location $ProjectPath

try {
    # Set environment variable
    $env:CIQ_HOME = $SDKPath
    
    # Build with developer key
    $keyPath = "$ProjectPath\developer_key"
    $buildArgs = @(
        "-f", "monkey.jungle",
        "-o", $OutputFile,
        "-d", $DeviceId,
        "-w",  # Show warnings
        "-y", $keyPath  # Developer key for signing
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
        Write-Host "`n❌ Output file not found!" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    Write-Host "✅ Build successful!`n" -ForegroundColor Green
    
    $fileSize = (Get-Item $OutputFile).Length
    Write-Host "File: $OutputFile ($([math]::Round($fileSize / 1KB, 2)) KB)" -ForegroundColor Gray
    
} catch {
    Write-Host "`n❌ Error: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location

# Step 3: Launch Simulator
Write-Host "`nStep 3: Ready to test!`n" -ForegroundColor Yellow

Write-Host "🎮 SIMULATOR INSTRUCTIONS:" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────" -ForegroundColor Gray
Write-Host "1. Run simulator:" -ForegroundColor White
Write-Host "   $SimulatorPath`n" -ForegroundColor Cyan

Write-Host "2. In simulator:" -ForegroundColor White
Write-Host "   - Select device: $DeviceId" -ForegroundColor Gray
Write-Host "   - Choose activity: Running" -ForegroundColor Gray
Write-Host "   - File → Load Device App" -ForegroundColor Gray
Write-Host "   - Select: $ProjectPath\$OutputFile`n" -ForegroundColor Gray

Write-Host "3. Test it:" -ForegroundColor White
Write-Host "   - Click Play button to start activity" -ForegroundColor Gray
Write-Host "   - Add AISRI Zone to data screen" -ForegroundColor Gray
Write-Host "   - Watch zone change with heart rate!`n" -ForegroundColor Gray

Write-Host "💡 Want to launch simulator now? [Y/N]: " -ForegroundColor Yellow -NoNewline
$response = Read-Host

if ($response -eq "Y" -or $response -eq "y") {
    Write-Host "`nLaunching simulator...`n" -ForegroundColor Green
    Start-Process $SimulatorPath
} else {
    Write-Host "`nRun manually: $SimulatorPath`n" -ForegroundColor White
}

Write-Host "─────────────────────────────────────────" -ForegroundColor Gray
Write-Host "✅ Simulator build complete!" -ForegroundColor Green
Write-Host "─────────────────────────────────────────`n" -ForegroundColor Gray

Write-Host "📝 NOTE:" -ForegroundColor Yellow
Write-Host "This build works in SIMULATOR only." -ForegroundColor White
Write-Host "For real watch, get developer key from:" -ForegroundColor White
Write-Host "https://developer.garmin.com/ → Account Settings → Developer Key`n" -ForegroundColor Cyan
