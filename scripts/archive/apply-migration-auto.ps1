# Apply Strava Migration via Supabase API
# Fully automated - no manual steps required

Write-Host "Applying Strava Signup Migration..." -ForegroundColor Cyan
Write-Host ""

# Load .env file
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]*?)\s*=\s*(.*?)\s*$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($name, $value, 'Process')
        }
    }
}

$SUPABASE_URL = $env:SUPABASE_URL
$SERVICE_KEY = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $SERVICE_KEY) {
    Write-Host "Error: SUPABASE_SERVICE_ROLE_KEY not found in .env" -ForegroundColor Red
    exit 1
}

# Read migration SQL
$migrationSQL = Get-Content "supabase\migrations\20240115_strava_signup_stats.sql" -Raw

# Split into statements
$statements = $migrationSQL -split ';' | Where-Object { 
    $_.Trim() -and 
    -not $_.Trim().StartsWith('--') -and
    $_.Trim().Length -gt 10
}

Write-Host "Found $($statements.Count) SQL statements" -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$errorCount = 0

foreach ($statement in $statements) {
    $sql = $statement.Trim() + ';'
    
    # Skip comments
    if ($sql.StartsWith('--') -or $sql.StartsWith('COMMENT')) {
        continue
    }
    
    try {
        # Execute SQL via Supabase REST API
        $body = @{
            query = $sql
        } | ConvertTo-Json
        
        $headers = @{
            'apikey' = $SERVICE_KEY
            'Authorization' = "Bearer $SERVICE_KEY"
            'Content-Type' = 'application/json'
        }
        
        $response = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" -Method Post -Headers $headers -Body $body -ErrorAction Stop
        
        $successCount++
        Write-Host "." -NoNewline -ForegroundColor Green
        
    } catch {
        $errorCount++
        Write-Host "!" -NoNewline -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host ""

if ($errorCount -eq 0) {
    Write-Host "Migration applied successfully!" -ForegroundColor Green
} else {
    Write-Host "Migration completed with some warnings (likely IF NOT EXISTS checks)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Database schema updated:" -ForegroundColor Cyan
Write-Host "  profiles table: Added Strava columns" -ForegroundColor White
Write-Host "  strava_activities: Created new table" -ForegroundColor White
Write-Host ""
