# Deploy Athlete Goals Evaluation Tracking Migration
# Run this script to add evaluation tracking columns to athlete_goals table

param(
    [string]$SupabaseUrl = $env:SUPABASE_URL,
    [string]$SupabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY
)

if (-not $SupabaseUrl -or -not $SupabaseKey) {
    Write-Host "Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables must be set" -ForegroundColor Red
    Write-Host ""
    Write-Host "Set them with:" -ForegroundColor Yellow
    Write-Host '$env:SUPABASE_URL = "https://your-project.supabase.co"'
    Write-Host '$env:SUPABASE_SERVICE_ROLE_KEY = "your-service-role-key"'
    exit 1
}

Write-Host "Deploying evaluation tracking migration..." -ForegroundColor Cyan

$migrationFile = Join-Path $PSScriptRoot "migration_athlete_goals_evaluation_tracking.sql"
$sql = Get-Content $migrationFile -Raw

$body = @{
    query = $sql
} | ConvertTo-Json

$headers = @{
    "apikey" = $SupabaseKey
    "Authorization" = "Bearer $SupabaseKey"
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri "$SupabaseUrl/rest/v1/rpc/exec_sql" -Method Post -Headers $headers -Body $body
    Write-Host "✓ Migration applied successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "New columns added to athlete_goals table:" -ForegroundColor Green
    Write-Host "  - generated_from_evaluation (boolean)"
    Write-Host "  - evaluation_date (timestamptz)"
    Write-Host "  - AISRI_score (decimal)"
    Write-Host "  - fitness_level (text)"
    Write-Host "  - injury_risk (text)"
    Write-Host "  - recommended_weekly_frequency (integer)"
    Write-Host "  - recommended_weekly_volume (decimal)"
    Write-Host "  - focus_areas (text[])"
    Write-Host "  - protocol_duration_weeks (integer)"
} catch {
    Write-Host "✗ Migration failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
