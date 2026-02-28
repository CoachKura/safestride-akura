# Apply Strava Signup Migration to Supabase
Write-Host "Applying Strava Signup Migration..." -ForegroundColor Cyan
Write-Host ""

$migrationFile = "supabase\migrations\20240115_strava_signup_stats.sql"

if (-Not (Test-Path $migrationFile)) {
    Write-Host "Error: Migration file not found" -ForegroundColor Red
    exit 1
}

Write-Host "Migration will be copied to clipboard." -ForegroundColor Yellow
Write-Host "Please paste it into Supabase SQL Editor." -ForegroundColor Yellow
Write-Host ""
Write-Host "Steps:" -ForegroundColor Cyan
Write-Host "1. SQL will be copied to clipboard" -ForegroundColor White
Write-Host "2. Browser will open to SQL Editor" -ForegroundColor White
Write-Host "3. Paste (Ctrl+V) and click Run" -ForegroundColor White
Write-Host ""

$continue = Read-Host "Continue? (y/n)"
if ($continue -ne 'y') {
    exit 0
}

# Copy to clipboard
Get-Content $migrationFile -Raw | Set-Clipboard
Write-Host ""
Write-Host "Migration SQL copied to clipboard!" -ForegroundColor Green

# Open SQL Editor
Write-Host "Opening Supabase SQL Editor..." -ForegroundColor Cyan
Start-Process "https://app.supabase.com/project/xzxnnswggwqtctcgpocr/sql/new"

Write-Host ""
Write-Host "Next: Paste the SQL and click Run" -ForegroundColor Yellow
Write-Host ""
