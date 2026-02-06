param(
    [string]$NgrokPath = "ngrok",
    [int]$Port = 5173
)

Write-Host "Starting Vite dev server in new PowerShell window..."
Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-Command", "npm run dev" -WorkingDirectory (Get-Location)

Start-Sleep -Seconds 1

Write-Host "Starting ngrok in new PowerShell window..."
Start-Process -FilePath $NgrokPath -ArgumentList "http $Port --host-header=localhost:$Port"

Write-Host "Started both processes. Close the windows or Ctrl+C inside them to stop."