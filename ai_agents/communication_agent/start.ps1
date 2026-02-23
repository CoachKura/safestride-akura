# AISRi Communication Agent - Windows Startup Script
# PowerShell script to start the server

Write-Host "
🚀 AISRi Communication Agent - Startup
" -ForegroundColor Cyan

# Check Python installation
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    Write-Host "❌ Python not found. Please install Python 3.11+" -ForegroundColor Red
    exit 1
}

$pythonVersion = python --version 2>&1
Write-Host "✅ $pythonVersion" -ForegroundColor Green

# Check if .env exists
if (-not (Test-Path ".env")) {
    Write-Host "❌ .env file not found" -ForegroundColor Red
    Write-Host "💡 Copy .env.example to .env and configure:
" -ForegroundColor Yellow
    Write-Host "   Copy-Item .env.example .env
" -ForegroundColor White
    Write-Host "Then edit .env with your credentials" -ForegroundColor White
    exit 1
}

Write-Host "✅ .env file found" -ForegroundColor Green

# Check if dependencies are installed
Write-Host "
📦 Checking dependencies..." -ForegroundColor Cyan
$requirementsMet = $true

$modules = @('fastapi', 'uvicorn', 'python-telegram-bot', 'httpx', 'supabase', 'APScheduler')
foreach ($module in $modules) {
    $installed = python -c "import $module" 2>$null
    if ($LASTEXITCODE -ne 0) {
        $requirementsMet = $false
        break
    }
}

if (-not $requirementsMet) {
    Write-Host "⚠️  Installing dependencies..." -ForegroundColor Yellow
    pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Dependencies installed" -ForegroundColor Green
} else {
    Write-Host "✅ All dependencies installed" -ForegroundColor Green
}

Write-Host "
🎯 Starting AISRi Communication Agent...
" -ForegroundColor Green
Write-Host "Server running on: http://localhost:8000" -ForegroundColor White
Write-Host "Health check: http://localhost:8000/health" -ForegroundColor White
Write-Host "Telegram webhook: http://localhost:8000/telegram/webhook" -ForegroundColor White
Write-Host "WhatsApp webhook: http://localhost:8000/whatsapp/webhook" -ForegroundColor White
Write-Host "
Press Ctrl+C to stop
" -ForegroundColor Yellow

# Run the application
python start.py
