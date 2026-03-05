$ErrorActionPreference = 'Stop'
$base = 'https://bdisppaxbvygsspcuymb.supabase.co'

$keysJson = (& 'C:\Users\kbsat\scoop\shims\supabase.exe' projects api-keys --project-ref bdisppaxbvygsspcuymb -o json | Out-String)
$keys = $keysJson | ConvertFrom-Json
$anonKey = ($keys | Where-Object { $_.id -eq 'anon' }).api_key
$serviceRoleKey = ($keys | Where-Object { $_.id -eq 'service_role' }).api_key

$adminHeaders = @{ apikey = $serviceRoleKey; Authorization = "Bearer $serviceRoleKey"; 'Content-Type' = 'application/json' }
$anonHeaders = @{ apikey = $anonKey; Authorization = "Bearer $anonKey"; 'Content-Type' = 'application/json' }

function New-UserSession {
  param([int]$aisri)
  $email = ("pc_live_" + $aisri + "_" + [guid]::NewGuid().ToString('N').Substring(0,8) + '@example.com')
  $password = 'PowerCell@123'

  $createBody = @{
    email = $email
    password = $password
    email_confirm = $true
    user_metadata = @{ aisri = $aisri }
  } | ConvertTo-Json -Depth 5

  $user = Invoke-RestMethod -Uri "$base/auth/v1/admin/users" -Headers $adminHeaders -Method POST -Body $createBody

  $tokenBody = @{ email = $email; password = $password } | ConvertTo-Json -Compress
  $token = Invoke-RestMethod -Uri "$base/auth/v1/token?grant_type=password" -Headers $anonHeaders -Method POST -Body $tokenBody

  return [PSCustomObject]@{
    userId = $user.id
    accessToken = $token.access_token
  }
}

function Call-PowerCells {
  param([string]$token,[string]$userId)
  $headers = @{ apikey = $anonKey; Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }
  $body = @{ user_id = $userId } | ConvertTo-Json -Compress
  return Invoke-RestMethod -Uri "$base/functions/v1/power-cells-get" -Headers $headers -Method POST -Body $body
}

$user40 = New-UserSession -aisri 40
$response40 = Call-PowerCells -token $user40.accessToken -userId $user40.userId

$user70 = New-UserSession -aisri 70
$response70 = Call-PowerCells -token $user70.accessToken -userId $user70.userId

$protocols40 = @()
foreach ($cell in $response40.available_power_cells) {
  $protocolName = $null
  if ($cell.protocol) {
    $protocolName = $cell.protocol.protocol_name
  } elseif ($cell.power_cell_protocols) {
    if ($cell.power_cell_protocols -is [array]) {
      $protocolName = $cell.power_cell_protocols[0].protocol_name
    } else {
      $protocolName = $cell.power_cell_protocols.protocol_name
    }
  }
  if ($protocolName) { $protocols40 += $protocolName }
}
$protocols40 = $protocols40 | Sort-Object -Unique

if (($response70.available_power_cells | Measure-Object).Count -gt 0) {
  $cellId = $response70.available_power_cells[0].id

  $insertHeaders = @{ apikey = $anonKey; Authorization = "Bearer $($user70.accessToken)"; 'Content-Type' = 'application/json'; Prefer = 'return=representation' }
  $historyBody = @{
    user_id = $user70.userId
    power_cell_type_id = $cellId
    scheduled_for = (Get-Date).ToString('yyyy-MM-dd')
    completed_at = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    status = 'completed'
    actual_duration_minutes = 32
    compliance_score = 95
    compliance_notes = 'Validation history entry'
  } | ConvertTo-Json -Compress

  Invoke-RestMethod -Uri "$base/rest/v1/user_power_cells" -Headers $insertHeaders -Method POST -Body $historyBody | Out-Null
}

$response70History = Call-PowerCells -token $user70.accessToken -userId $user70.userId

$result = [PSCustomObject]@{
  scenario40 = [PSCustomObject]@{
    user_aisri = $response40.user_aisri
    available_count = ($response40.available_power_cells | Measure-Object).Count
    protocols_visible = $protocols40
  }
  scenario70 = [PSCustomObject]@{
    user_aisri = $response70.user_aisri
    available_count = ($response70.available_power_cells | Measure-Object).Count
    protocol_count = ($response70.protocols | Measure-Object).Count
  }
  scenarioHistory = [PSCustomObject]@{
    history_count = ($response70History.user_history | Measure-Object).Count
    has_required_history_fields = [PSCustomObject]@{
      scheduled_date = ($null -ne $response70History.user_history[0].scheduled_date)
      completed_at = ($null -ne $response70History.user_history[0].completed_at)
      compliance_score = ($null -ne $response70History.user_history[0].compliance_score)
    }
  }
  fieldsPresent = [PSCustomObject]@{
    available_power_cells = ($null -ne $response70History.available_power_cells)
    user_history = ($null -ne $response70History.user_history)
    user_aisri = ($null -ne $response70History.user_aisri)
    protocols = ($null -ne $response70History.protocols)
  }
}

$result | ConvertTo-Json -Depth 8