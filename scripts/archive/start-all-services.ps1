# SafeStride AI - Start All Services
# Run this script to start both FastAPI and n8n servers

Write-Host "`n═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🚀 STARTING SAFESTRIDE AI SERVICES" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════`n" -ForegroundColor Cyan

# Check if ports are already in use
Write-Host "📋 Checking ports..." -ForegroundColor Yellow

$port8001 = Test-NetConnection -ComputerName localhost -Port 8001 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
$port5678 = Test-NetConnection -ComputerName localhost -Port 5678 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

if ($port8001.TcpTestSucceeded) {
    Write-Host "   ✅ FastAPI already running on port 8001" -ForegroundColor Green
}
else {
    Write-Host "   ⏳ Starting FastAPI on port 8001..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd C:\safestride\ai_agents; Write-Host '🔷 FASTAPI SERVER' -ForegroundColor Blue; python main.py"
    Start-Sleep -Seconds 3
}

if ($port5678.TcpTestSucceeded) {
    Write-Host "   ✅ n8n already running on port 5678" -ForegroundColor Green
}
else {
    Write-Host "   ⏳ Starting n8n on port 5678..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd C:\safestride; Write-Host '🟢 N8N SERVER' -ForegroundColor Green; npx n8n"
    Start-Sleep -Seconds 5
}

Write-Host "`n═══════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ SERVICES STARTING!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════`n" -ForegroundColor Green

Write-Host "📍 Access Points:" -ForegroundColor Cyan
Write-Host "   n8n Workflow:  http://localhost:5678" -ForegroundColor White
Write-Host "   FastAPI Docs:  http://127.0.0.1:8001/docs`n" -ForegroundColor White

Write-Host "⏳ Wait 10 seconds, then test the connections..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "`n🧪 Testing connections...`n" -ForegroundColor Cyan

try {
    $n8n = Invoke-WebRequest -Uri "http://localhost:5678" -Method GET -TimeoutSec 3 -UseBasicParsing
    Write-Host "   ✅ n8n is accessible!" -ForegroundColor Green
}
catch {
    Write-Host "   ❌ n8n not responding yet - give it more time" -ForegroundColor Red
}

try {
    $api = Invoke-RestMethod -Uri "http://127.0.0.1:8001/docs" -Method GET -TimeoutSec 3
    Write-Host "   ✅ FastAPI is accessible!" -ForegroundColor Green
}
catch {
    Write-Host "   ❌ FastAPI not responding yet - give it more time" -ForegroundColor Red
}

Write-Host "`n✨ All services should be running now!" -ForegroundColor Green
Write-Host "💡 Two new PowerShell windows opened - KEEP THEM OPEN!`n" -ForegroundColor Yellow
