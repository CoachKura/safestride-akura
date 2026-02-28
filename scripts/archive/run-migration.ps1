# Apply Migration Directly - No Manual Steps
Write-Host "Applying Strava Migration..." -ForegroundColor Cyan

# Get database connection details from .env
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^DATABASE_URL\s*=\s*(.+)$') {
            $env:DATABASE_URL = $matches[1].Trim()
        }
    }
}

$dbUrl = $env:DATABASE_URL

if (-not $dbUrl) {
    Write-Host "DATABASE_URL not found. Using Supabase project directly..." -ForegroundColor Yellow
    
    # Try with project ref
    npx supabase db execute --project-ref xzxnnswggwqtctcgpocr --file supabase/migrations/20240115_strava_signup_stats.sql
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "" 
        Write-Host "Migration applied successfully!" -ForegroundColor Green
        exit 0
    }
}

# Try with database URL if available
if ($dbUrl) {
    Write-Host "Applying migration using database URL..." -ForegroundColor Yellow
    npx supabase db execute --db-url $dbUrl --file supabase/migrations/20240115_strava_signup_stats.sql
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Migration applied successfully!" -ForegroundColor Green
        exit 0
    }
}

Write-Host ""
Write-Host "Automated methods failed. Falling back to manual method:" -ForegroundColor Yellow
Write-Host "1. Copying SQL to clipboard..." -ForegroundColor White

Get-Content "supabase\migrations\20240115_strava_signup_stats.sql" -Raw | Set-Clipboard

Write-Host "2. Opening Supabase SQL Editor..." -ForegroundColor White
Start-Process "https://app.supabase.com/project/xzxnnswggwqtctcgpocr/sql/new"

Write-Host ""
Write-Host "Please paste (Ctrl+V) and click Run in the SQL Editor" -ForegroundColor Cyan
