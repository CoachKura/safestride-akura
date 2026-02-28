# SafeStride Strava Signup API - Quick Start
# This script starts the Strava OAuth signup backend API

Write-Host "🚀 SafeStride Strava Signup API Startup" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Check if Python is installed
try {
    $pythonVersion = python --version
    Write-Host "✅ Python detected: $pythonVersion" -ForegroundColor Green
}
catch {
    Write-Host "❌ Python not found. Please install Python 3.8+." -ForegroundColor Red
    exit 1
}

# Navigate to ai_agents directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$aiAgentsPath = Join-Path $scriptPath "ai_agents"

if (-Not (Test-Path $aiAgentsPath)) {
    Write-Host "❌ ai_agents directory not found." -ForegroundColor Red
    exit 1
}

Set-Location $aiAgentsPath
Write-Host "📂 Working directory: $aiAgentsPath" -ForegroundColor Yellow
Write-Host ""

# Check if .env file exists
$envFile = Join-Path (Split-Path -Parent $aiAgentsPath) ".env"
if (-Not (Test-Path $envFile)) {
    Write-Host "⚠️  .env file not found. Make sure to configure:" -ForegroundColor Yellow
    Write-Host "   - STRAVA_CLIENT_ID" -ForegroundColor Yellow
    Write-Host "   - STRAVA_CLIENT_SECRET" -ForegroundColor Yellow
    Write-Host "   - SUPABASE_URL" -ForegroundColor Yellow
    Write-Host "   - SUPABASE_SERVICE_ROLE_KEY" -ForegroundColor Yellow
    Write-Host ""
}

# Install dependencies
Write-Host "📦 Installing/Checking dependencies..." -ForegroundColor Cyan
pip install fastapi uvicorn httpx python-dotenv supabase --quiet

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install dependencies." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Dependencies installed" -ForegroundColor Green
Write-Host ""

# Start the API server
Write-Host "🌐 Starting Strava Signup API server..." -ForegroundColor Cyan
Write-Host ""
Write-Host "API Endpoints:" -ForegroundColor Green
Write-Host "  - Health Check: http://localhost:8000/health" -ForegroundColor White
Write-Host "  - Signup:       POST http://localhost:8000/api/strava-signup" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Start server
python strava_signup_api.py
