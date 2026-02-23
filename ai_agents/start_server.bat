@echo off
REM Start FastAPI Server - Windows Batch Script

cd /d C:\safestride\ai_agents

REM Set default port if not already set
if not defined PORT set PORT=8001

echo.
echo ================================================
echo    Starting SafeStride AI FastAPI Server
echo ================================================
echo.
echo Local:   http://localhost:%PORT%
echo Network: http://0.0.0.0:%PORT%
echo.
echo Press Ctrl+C to stop
echo.
echo ================================================
echo.

uvicorn main:app --host 0.0.0.0 --port %PORT%

pause
