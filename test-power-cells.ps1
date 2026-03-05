Write-Host "`n=== SafeStride Power Cells Smoke Test ===" -ForegroundColor Cyan

$supabase = "C:\Users\kbsat\scoop\shims\supabase.exe"
$workdir = "C:\safestride"
$localApi = "http://127.0.0.1:54321"
$webUrl = "http://localhost:8080/power-cells.html"
$anon = "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"

Write-Host "1) Checking Supabase status..." -ForegroundColor Yellow
& $supabase --workdir $workdir status

Write-Host "`n2) Checking web page..." -ForegroundColor Yellow
try {
    $webResp = Invoke-WebRequest -Uri $webUrl -UseBasicParsing -TimeoutSec 8
    if ($webResp.StatusCode -eq 200) {
        Write-Host "   OK: power-cells.html reachable" -ForegroundColor Green
    } else {
        Write-Host "   WARN: Unexpected status $($webResp.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   WARN: Web server is not reachable at $webUrl" -ForegroundColor Yellow
}

Write-Host "`n3) Checking local function endpoint..." -ForegroundColor Yellow
try {
    $headers = @{
        apikey        = $anon
        Authorization = "Bearer $anon"
        'Content-Type' = 'application/json'
    }
    $fnResp = Invoke-WebRequest -Uri "$localApi/functions/v1/power-cells-get" -Method POST -Headers $headers -Body '{"userId":""}' -UseBasicParsing -TimeoutSec 10
    Write-Host "   Function status: $($fnResp.StatusCode)" -ForegroundColor Green
    Write-Host "   Response: $($fnResp.Content)"
} catch {
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $body = $reader.ReadToEnd()
        Write-Host "   Function status: $([int]$_.Exception.Response.StatusCode)" -ForegroundColor Yellow
        Write-Host "   Response: $body"
        Write-Host "   Note: 400 with 'userId is required' is expected for smoke test." -ForegroundColor DarkYellow
    } else {
        Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nDone. Next: use a real userId in the function request for full validation." -ForegroundColor Cyan
