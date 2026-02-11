# Deploy Strava OAuth Callback Function to Supabase
# This script deploys the edge function that handles Strava authorization

Write-Host "`n🚀 Deploying Strava Callback Function..." -ForegroundColor Cyan

# Check if Supabase CLI is available
try {
    npx supabase --version | Out-Null
} catch {
    Write-Host "❌ Supabase CLI not available. Install with: npm install -g supabase" -ForegroundColor Red
    exit 1
}

# Deploy the function
Write-Host "`n📦 Deploying strava-callback function..." -ForegroundColor Yellow

npx supabase functions deploy strava-callback --project-ref xzxnnswggwqtctcgpocr

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Deployment successful!" -ForegroundColor Green
    Write-Host "`n📍 Your callback URL is:" -ForegroundColor Cyan
    Write-Host "   https://xzxnnswggwqtctcgpocr.supabase.co/functions/v1/strava-callback" -ForegroundColor White
    
    Write-Host "`n🔧 Update your Strava App Settings:" -ForegroundColor Cyan
    Write-Host "   1. Go to: https://www.strava.com/settings/api" -ForegroundColor White
    Write-Host "   2. Set Authorization Callback Domain to:" -ForegroundColor White
    Write-Host "      xzxnnswggwqtctcgpocr.supabase.co" -ForegroundColor Yellow
    Write-Host "   3. OAuth flow will now work correctly!" -ForegroundColor White
    
} else {
    Write-Host "`n❌ Deployment failed. Check the errors above." -ForegroundColor Red
    Write-Host "   Make sure you're logged in: npx supabase login" -ForegroundColor Yellow
}

Write-Host ""
