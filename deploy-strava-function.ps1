# Deploy Strava OAuth Callback Edge Function to Supabase
# Run this from the akura_mobile directory

Write-Host "🚀 Deploying Strava OAuth Callback to Supabase..." -ForegroundColor Cyan

# Check if Supabase CLI is installed
$supabaseCli = Get-Command supabase -ErrorAction SilentlyContinue
if (-not $supabaseCli) {
    Write-Host "❌ Supabase CLI not found. Installing..." -ForegroundColor Yellow
    npm install -g supabase
}

# Deploy the function
Write-Host "📦 Deploying strava-callback function..." -ForegroundColor Green
supabase functions deploy strava-callback --project-ref yawxlwcniqfspcgefuro

Write-Host ""
Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Go to: https://www.strava.com/settings/api" -ForegroundColor White
Write-Host "2. Update Authorization Callback Domain to:" -ForegroundColor White
Write-Host "   yawxlwcniqfspcgefuro.supabase.co" -ForegroundColor Yellow
Write-Host "3. Test the connection in your mobile app!" -ForegroundColor White
Write-Host ""
Write-Host "🔗 Function URL:" -ForegroundColor Cyan
Write-Host "   https://yawxlwcniqfspcgefuro.supabase.co/functions/v1/strava-callback" -ForegroundColor Yellow
