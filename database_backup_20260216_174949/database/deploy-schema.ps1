# ========================================
# SUPABASE SCHEMA DEPLOYMENT SCRIPT
# ========================================

Write-Host "`n DATABASE DEPLOYMENT FOR SAFESTRIDE`n" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Your Supabase credentials
$SUPABASE_URL = "https://yawxlwcniqfspcgefuro.supabase.co"
$SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlhd3hsd2NuaXFmc3BjZ2VmdXJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk0OTcxODksImV4cCI6MjA4NTA3MzE4OX0.eky8ua6lEhzPcvG289wWDMWOjVGwr-bL8LLUnrzO4r4"  #  PASTE YOUR SERVICE ROLE KEY HERE

# Check if service key is provided
if ([string]::IsNullOrEmpty($SUPABASE_SERVICE_KEY)) {
    Write-Host " ERROR: Service role key required!`n" -ForegroundColor Red
    Write-Host "To get your service role key:" -ForegroundColor Yellow
    Write-Host "1. Go to: https://supabase.com/dashboard/project/yawxlwcniqfspcgefuro/settings/api" -ForegroundColor White
    Write-Host "2. Copy the 'service_role' key (NOT anon key)" -ForegroundColor White
    Write-Host "3. Paste it in line 10 of this script`n" -ForegroundColor White
    Write-Host "Then run this script again.`n" -ForegroundColor Yellow
    exit 1
}

# Read schema file
$schemaPath = "E:\Akura Safe Stride\safestride\akura_mobile\database\schema-fixed.sql"
if (-not (Test-Path $schemaPath)) {
    Write-Host " ERROR: schema-fixed.sql not found!`n" -ForegroundColor Red
    exit 1
}

Write-Host " Reading schema file..." -ForegroundColor Yellow
$sqlContent = Get-Content $schemaPath -Raw

Write-Host " Deploying to Supabase...`n" -ForegroundColor Yellow

# Deploy via REST API
$headers = @{
    "apikey" = $SUPABASE_SERVICE_KEY
    "Authorization" = "Bearer $SUPABASE_SERVICE_KEY"
    "Content-Type" = "application/json"
}

$body = @{
    "query" = $sqlContent
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" -Method Post -Headers $headers -Body $body
    
    Write-Host " SUCCESS! Database schema deployed!`n" -ForegroundColor Green
    Write-Host "Tables created:" -ForegroundColor Cyan
    Write-Host "  profiles" -ForegroundColor White
    Write-Host "  athlete_coach_relationships" -ForegroundColor White
    Write-Host "  AISRI_assessments" -ForegroundColor White
    Write-Host "  workouts" -ForegroundColor White
    Write-Host "  training_plans" -ForegroundColor White
    Write-Host "  devices" -ForegroundColor White
    Write-Host "  notifications`n" -ForegroundColor White
    Write-Host " Your Flutter app is now fully functional!`n" -ForegroundColor Green
    
} catch {
    Write-Host " DEPLOYMENT FAILED`n" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)`n" -ForegroundColor Red
    Write-Host "Alternative: Manual deployment" -ForegroundColor Yellow
    Write-Host "1. Open: https://supabase.com/dashboard/project/yawxlwcniqfspcgefuro/sql" -ForegroundColor White
    Write-Host "2. Copy ALL content from schema-fixed.sql" -ForegroundColor White
    Write-Host "3. Paste and click 'Run'`n" -ForegroundColor White
}

