Write-Host "`n=== SafeStride Power Cells Test Suite ===" -ForegroundColor Cyan

$supabaseCli = "C:\Users\kbsat\scoop\shims\supabase.exe"
$workdir = "C:\safestride"
$webUrl = "http://localhost:8080/power-cells.html"
$localApi = "http://127.0.0.1:54321"
$anon = "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"

$results = @()

function Add-Result {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Details
    )

    $status = if ($Passed) { "PASS" } else { "FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    Write-Host ("[{0}] {1} - {2}" -f $status, $Name, $Details) -ForegroundColor $color
    $script:results += [PSCustomObject]@{
        Name = $Name
        Passed = $Passed
        Details = $Details
    }
}

Write-Host "`n1) Supabase local status" -ForegroundColor Yellow
try {
    $statusOutput = & $supabaseCli --workdir $workdir status 2>&1 | Out-String
    $healthy =
        $statusOutput -match "local development setup is running" -or
        $statusOutput -match "Project URL" -or
        $statusOutput -match "supabase_db"
    $statusDetails = "Supabase services not ready"
    if ($healthy) {
        $statusDetails = "Local services detected"
    }
    Add-Result -Name "Supabase Status" -Passed $healthy -Details $statusDetails
} catch {
    Add-Result -Name "Supabase Status" -Passed $false -Details $_.Exception.Message
}

Write-Host "`n2) Web server reachability" -ForegroundColor Yellow
try {
    $webResp = Invoke-WebRequest -Uri $webUrl -UseBasicParsing -TimeoutSec 8
    Add-Result -Name "Web Reachability" -Passed ($webResp.StatusCode -eq 200) -Details "HTTP $($webResp.StatusCode)"
} catch {
    Add-Result -Name "Web Reachability" -Passed $false -Details $_.Exception.Message
}

Write-Host "`n3) Edge function endpoint" -ForegroundColor Yellow
try {
    $headers = @{
        apikey = $anon
        Authorization = "Bearer $anon"
        "Content-Type" = "application/json"
    }

    $resp = Invoke-WebRequest -Uri "$localApi/functions/v1/power-cells-get" -Method POST -Headers $headers -Body '{"user_id":""}' -UseBasicParsing -TimeoutSec 10
    $ok = $resp.StatusCode -eq 200 -or $resp.StatusCode -eq 400
    Add-Result -Name "Edge Function" -Passed $ok -Details "HTTP $($resp.StatusCode)"
} catch {
    if ($_.Exception.Response) {
        $status = [int]$_.Exception.Response.StatusCode
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $body = $reader.ReadToEnd()
        $expected = $status -eq 400
        Add-Result -Name "Edge Function" -Passed $expected -Details "HTTP $status $body"
    } else {
        Add-Result -Name "Edge Function" -Passed $false -Details $_.Exception.Message
    }
}

Write-Host "`n4) Database verification" -ForegroundColor Yellow
try {
    $query = @"
SELECT
  (SELECT COUNT(*) FROM public.power_cell_protocols) AS protocol_count,
  (SELECT COUNT(*) FROM public.power_cell_types) AS power_cell_count;
"@

    $dbOutput = $query | docker exec -i supabase_db_safestride psql -t -A -U postgres -d postgres
    $trimmed = ($dbOutput | Out-String).Trim()

    if ($trimmed) {
        $parts = $trimmed.Split("|")
        $protocolCount = [int]$parts[0]
        $powerCellCount = [int]$parts[1]
        $passed = ($protocolCount -eq 7 -and $powerCellCount -eq 26)
        Add-Result -Name "Database Counts" -Passed $passed -Details "Protocols=$protocolCount, PowerCells=$powerCellCount"
    } else {
        Add-Result -Name "Database Counts" -Passed $false -Details "No result returned"
    }
} catch {
    Add-Result -Name "Database Counts" -Passed $false -Details $_.Exception.Message
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
$passCount = ($results | Where-Object { $_.Passed }).Count
$failCount = ($results | Where-Object { -not $_.Passed }).Count
Write-Host ("Passed: {0}, Failed: {1}" -f $passCount, $failCount) -ForegroundColor Cyan

if ($failCount -eq 0) {
    Write-Host "All checks passed." -ForegroundColor Green
    exit 0
}

Write-Host "Some checks failed. Review output above." -ForegroundColor Red
exit 1
