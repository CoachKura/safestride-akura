# AISRi Services Startup Script
# Starts both AI Engine and Communication Agent

Write-Host "🚀 Starting AISRi Services..." -ForegroundColor Cyan
Write-Host ""

# Change to AI agents directory
Set-Location -Path "c:\safestride\ai_agents"

# Check .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "❌ ERROR: .env file not found!" -ForegroundColor Red
    Write-Host "Please create .env file with required environment variables" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Environment file found" -ForegroundColor Green

# Start AI Engine (main.py) on port 8001
Write-Host ""
Write-Host "Starting AI Engine on port 8001..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd c:\safestride\ai_agents; python main.py"
Start-Sleep -Seconds 3

# Check if AI Engine is running
$aiEngineRunning = Test-NetConnection -ComputerName localhost -Port 8001 -InformationLevel Quiet
if ($aiEngineRunning) {
    Write-Host "✓ AI Engine started successfully" -ForegroundColor Green
}
else {
    Write-Host "⚠️  AI Engine may still be starting..." -ForegroundColor Yellow
}

# Start Communication Agent (communication_agent_v2.py) on port 10000
Write-Host ""
Write-Host "Starting Communication Agent on port 10000..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd c:\safestride\ai_agents; python communication_agent_v2.py"
Start-Sleep -Seconds 3

# Check if Communication Agent is running
$commAgentRunning = Test-NetConnection -ComputerName localhost -Port 10000 -InformationLevel Quiet
if ($commAgentRunning) {
    Write-Host "✓ Communication Agent started successfully" -ForegroundColor Green
}
else {
    Write-Host "⚠️  Communication Agent may still be starting..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🎉 AISRi Services Startup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Services:" -ForegroundColor White
Write-Host "  • AI Engine:          http://localhost:8001" -ForegroundColor Gray
Write-Host "  • Communication Agent: http://localhost:10000" -ForegroundColor Gray
Write-Host ""
Write-Host "Testing:" -ForegroundColor White
Write-Host "  • AI Engine Health:   http://localhost:8001/health" -ForegroundColor Gray
Write-Host "  • Comm Agent Health:  http://localhost:10000/health" -ForegroundColor Gray
Write-Host ""
Write-Host "Now you can test via Telegram with messages like:" -ForegroundColor Yellow
Write-Host "  - What pace for my 10K race" -ForegroundColor Cyan
Write-Host "  - Show me my performance predictions" -ForegroundColor Cyan
Write-Host "  - What should I train today" -ForegroundColor Cyan
Write-Host ""
