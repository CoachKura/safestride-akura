# Start FastAPI Server - PowerShell Version

# Set default port (can be overridden by environment variable)
if (-not $env:PORT) {
    $env:PORT = "8001"
}

Write-Host "`n🚀 Starting FastAPI Server" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "📡 Local:    http://localhost:$env:PORT" -ForegroundColor Green
Write-Host "🌍 Network:  http://0.0.0.0:$env:PORT" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "`n💡 Press Ctrl+C to stop`n" -ForegroundColor Yellow

# Change to ai_agents directory
Set-Location C:\safestride\ai_agents

# Start uvicorn
uvicorn main:app --host 0.0.0.0 --port $env:PORT
