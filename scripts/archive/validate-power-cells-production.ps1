$ErrorActionPreference = 'Stop'
$base = 'https://bdisppaxbvygsspcuymb.supabase.co'
$anon = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkaXNwcGF4YnZ5Z3NzcGN1eW1iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyNDY4NDQsImV4cCI6MjA4NjgyMjg0NH0.bjgoVhVboDQTmIPe_A5_4yiWvTBvckVtw88lQ7GWFrc'
$headers = @{ apikey = $anon; Authorization = "Bearer $anon"; 'Content-Type' = 'application/json' }

function Get-TokenAndUser {
  param([string]$Email,[string]$Password,[int]$Aisri)

  $signupBody = @{ email = $Email; password = $Password; data = @{ aisri = $Aisri } } | ConvertTo-Json -Depth 5 -Compress
  try {
    Invoke-RestMethod -Uri "$base/auth/v1/signup" -Method POST -Headers $headers -Body $signupBody | Out-Null
  } catch {
    # Continue: user may already exist
  }

  $tokenBody = @{ email = $Email; password = $Password } | ConvertTo-Json -Compress
  $token = Invoke-RestMethod -Uri "$base/auth/v1/token?grant_type=password" -Method POST -Headers $headers -Body $tokenBody

  return [PSCustomObject]@{
    AccessToken = $token.access_token
    UserId = $token.user.id
    Email = $Email
  }
}

function Call-PowerCells {
  param([string]$Token,[string]$UserId)
  $h = @{ apikey = $anon; Authorization = "Bearer $Token"; 'Content-Type' = 'application/json' }
  $body = @{ user_id = $UserId } | ConvertTo-Json -Compress
  return Invoke-RestMethod -Uri "$base/functions/v1/power-cells-get" -Method POST -Headers $h -Body $body
}

$u40 = Get-TokenAndUser -Email ("pc40_" + [guid]::NewGuid().ToString('N').Substring(0,8) + '@example.com') -Password 'PowerCell@123' -Aisri 40
$r40 = Call-PowerCells -Token $u40.AccessToken -UserId $u40.UserId

$u70 = Get-TokenAndUser -Email ("pc70_" + [guid]::NewGuid().ToString('N').Substring(0,8) + '@example.com') -Password 'PowerCell@123' -Aisri 70
$r70 = Call-PowerCells -Token $u70.AccessToken -UserId $u70.UserId

$historyInserted = $false
if (($r70.available_power_cells | Measure-Object).Count -gt 0) {
  $cellId = $r70.available_power_cells[0].id
  $h70 = @{ apikey = $anon; Authorization = "Bearer $($u70.AccessToken)"; 'Content-Type' = 'application/json'; Prefer = 'return=representation' }
  $insertBody = @{
    user_id = $u70.UserId
    power_cell_type_id = $cellId
    scheduled_date = (Get-Date).ToString('yyyy-MM-dd')
    completed_at = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    actual_duration_minutes = 30
    actual_distance_km = 5.1
    actual_pace_min_per_km = 5.88
    compliance_score = 94
    coach_notes = 'Automated production validation entry'
  } | ConvertTo-Json -Compress

  Invoke-RestMethod -Uri "$base/rest/v1/user_power_cells" -Method POST -Headers $h70 -Body $insertBody | Out-Null
  $historyInserted = $true
}

$r70AfterHistory = Call-PowerCells -Token $u70.AccessToken -UserId $u70.UserId

$result = [PSCustomObject]@{
  scenario40 = [PSCustomObject]@{
    userId = $u40.UserId
    userAisri = $r40.user_aisri
    availableCount = ($r40.available_power_cells | Measure-Object).Count
    protocolCount = ($r40.protocols | Measure-Object).Count
    historyCount = ($r40.user_history | Measure-Object).Count
  }
  scenario70 = [PSCustomObject]@{
    userId = $u70.UserId
    userAisri = $r70.user_aisri
    availableCount = ($r70.available_power_cells | Measure-Object).Count
    protocolCount = ($r70.protocols | Measure-Object).Count
    historyCountBeforeInsert = ($r70.user_history | Measure-Object).Count
    historyInserted = $historyInserted
    historyCountAfterInsert = ($r70AfterHistory.user_history | Measure-Object).Count
  }
  fieldsPresent = [PSCustomObject]@{
    available_power_cells = ($null -ne $r70AfterHistory.available_power_cells)
    user_history = ($null -ne $r70AfterHistory.user_history)
    user_aisri = ($null -ne $r70AfterHistory.user_aisri)
    protocols = ($null -ne $r70AfterHistory.protocols)
  }
}

$result | ConvertTo-Json -Depth 8