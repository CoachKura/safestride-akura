# Quick Build Without Key (Development Mode)
# This attempts to build using various methods

param(
    [string]$DeviceId = "fr265"
)

Write-Host "`n=== ATTEMPTING BUILD ===" -ForegroundColor Cyan
Write-Host ""

$sdkPath = (Get-ChildItem "$env:APPDATA\Garmin\ConnectIQ\Sdks" -Directory | Select-Object -First 1).FullName
$monkeycPath = "$sdkPath\bin\monkeyc.bat"
$output = "AISRIZone.prg"

Write-Host "SDK: $sdkPath" -ForegroundColor Gray
Write-Host "Output: $output" -ForegroundColor Gray
Write-Host ""

# Method 1: Try without key (might work in some SDK versions)
Write-Host "[Method 1] Trying build without key..." -ForegroundColor Yellow
& $monkeycPath -f monkey.jungle -o $output -d $DeviceId -g 2>&1 | Out-Null
if (Test-Path $output) {
    Write-Host "✅ SUCCESS! Built without key!" -ForegroundColor Green
    Write-Host "File: $output" -ForegroundColor Cyan
    exit 0
}

# Method 2: Create minimal dummy key
Write-Host "[Method 2] Generating temporary key..." -ForegroundColor Yellow
$keyFile = "temp_key.pem"
@"
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAzqPh3sxZJ+8jXxLpB8QKvH7rnGH5C9xwEcN5MqpX6SjvLkl0
IHUsAfYjm4oJmWkJpP6xN2WwRQyBxzqGBpXwUvh5J8rLmN5xH7cJ8qp5xnK9jWuP
example_dummy_key_for_testing_only_do_not_use_in_production_this_is_placeholder
zqPh3sxZJ+8jXxLpB8QKvH7rnGH5C9xwEcN5MqpX6SjvLkl0IHUsAfYjm4oJmWkJ
-----END RSA PRIVATE KEY-----
"@ | Out-File $keyFile -Encoding ASCII

Write-Host "Building with temporary key..." -ForegroundColor Gray
& $monkeycPath -f monkey.jungle -o $output -d $DeviceId -y $keyFile -w 2>&1 | Out-String
Remove-Item $keyFile -ErrorAction SilentlyContinue

if (Test-Path $output) {
    Write-Host "`n✅ SUCCESS!" -ForegroundColor Green
    exit 0
}

# Method 3: Instructions
Write-Host "`n❌ Both methods failed." -ForegroundColor Red
Write-Host ""
Write-Host "📋 SOLUTION: Generate Real Developer Key" -ForegroundColor Yellow
Write-Host "===================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "In SDK Manager (should be open):" -ForegroundColor White
Write-Host "1. Look for 'Tools' or 'File' menu" -ForegroundColor Gray
Write-Host "2. Click 'Generate Developer Key'" -ForegroundColor Gray
Write-Host "3. Save as: developer_key (in this folder)" -ForegroundColor Cyan
Write-Host ""
Write-Host "OR use online generator:" -ForegroundColor White
Write-Host "https://developer.garmin.com → Account Settings" -ForegroundColor Cyan
Write-Host ""
