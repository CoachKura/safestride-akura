# Apply Strava Signup Migration Directly to Supabase
# This script runs the migration using the Supabase connection string

Write-Host "🔄 Applying Strava Signup Migration..." -ForegroundColor Cyan
Write-Host ""

# Get the migration file path
$migrationFile = "supabase\migrations\20240115_strava_signup_stats.sql"

if (-Not (Test-Path $migrationFile)) {
    Write-Host "❌ Migration file not found: $migrationFile" -ForegroundColor Red
    exit 1
}

# Load environment variables
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]*?)\s*=\s*(.*?)\s*$') {
            $name = $matches[1]
            $value = $matches[2]
            Set-Item -Path "env:$name" -Value $value
        }
    }
}

# Get database URL
$dbUrl = $env:DATABASE_URL

if (-Not $dbUrl) {
    Write-Host "⚠️  DATABASE_URL not found in .env" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please use the Supabase Dashboard instead:" -ForegroundColor Cyan
    Write-Host "1. Go to: https://app.supabase.com/project/xzxnnswggwqtctcgpocr/editor" -ForegroundColor White
    Write-Host "2. Click 'SQL Editor' in left sidebar" -ForegroundColor White
    Write-Host "3. Click 'New Query'" -ForegroundColor White
    Write-Host "4. Copy and paste the contents of:" -ForegroundColor White
    Write-Host "   $migrationFile" -ForegroundColor Yellow
    Write-Host "5. Click 'Run' or press Ctrl+Enter" -ForegroundColor White
    Write-Host ""
    
    # Open the SQL Editor in browser
    $openBrowser = Read-Host "Open SQL Editor in browser? (y/n)"
    if ($openBrowser -eq 'y') {
        Start-Process "https://app.supabase.com/project/xzxnnswggwqtctcgpocr/sql/new"
    }
    
    # Copy migration to clipboard
    $copyToClipboard = Read-Host "Copy migration SQL to clipboard? (y/n)"
    if ($copyToClipboard -eq 'y') {
        Get-Content $migrationFile -Raw | Set-Clipboard
        Write-Host "✅ Migration SQL copied to clipboard!" -ForegroundColor Green
        Write-Host "   Paste it into the SQL Editor and run it." -ForegroundColor White
    }
    
    exit 0
}

# Check if psql is available
$psqlAvailable = Get-Command psql -ErrorAction SilentlyContinue

if (-Not $psqlAvailable) {
    Write-Host "⚠️  psql not found. Using manual method instead." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please use the Supabase Dashboard:" -ForegroundColor Cyan
    Write-Host "1. Go to: https://app.supabase.com/project/xzxnnswggwqtctcgpocr/editor" -ForegroundColor White
    Write-Host "2. Click 'SQL Editor' in left sidebar" -ForegroundColor White
    Write-Host "3. Copy and paste the migration SQL" -ForegroundColor White
    Write-Host "4. Click 'Run'" -ForegroundColor White
    Write-Host ""
    
    # Copy to clipboard
    Get-Content $migrationFile -Raw | Set-Clipboard
    Write-Host "✅ Migration SQL copied to clipboard!" -ForegroundColor Green
    Write-Host "   Opening SQL Editor..." -ForegroundColor White
    Start-Process "https://app.supabase.com/project/xzxnnswggwqtctcgpocr/sql/new"
    
    exit 0
}

# Apply migration using psql
Write-Host "📊 Applying migration using psql..." -ForegroundColor Yellow

try {
    $result = Get-Content $migrationFile | psql $dbUrl 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Migration applied successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "New columns added to profiles table:" -ForegroundColor Cyan
        Write-Host "  - strava_athlete_id" -ForegroundColor White
        Write-Host "  - pb_5k, pb_10k, pb_half_marathon, pb_marathon" -ForegroundColor White
        Write-Host "  - total_runs, total_distance_km, avg_pace_min_per_km" -ForegroundColor White
        Write-Host "  - profile_photo_url, gender, weight, height" -ForegroundColor White
        Write-Host ""
        Write-Host "New table created:" -ForegroundColor Cyan
        Write-Host "  - strava_activities" -ForegroundColor White
    }
    else {
        throw "psql command failed with exit code $LASTEXITCODE"
    }
}
catch {
    Write-Host "❌ Migration failed: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please apply manually in Supabase Dashboard:" -ForegroundColor Yellow
    Write-Host "https://app.supabase.com/project/xzxnnswggwqtctcgpocr/sql/new" -ForegroundColor White
    exit 1
}
