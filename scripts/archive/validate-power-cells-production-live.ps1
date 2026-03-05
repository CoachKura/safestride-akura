$ErrorActionPreference = 'Stop'

$base = 'https://bdisppaxbvygsspcuymb.supabase.co'
$supabaseCli = 'C:\Users\kbsat\scoop\shims\supabase.exe'
$keysJson = (& $supabaseCli projects api-keys --project-ref bdisppaxbvygsspcuymb -o json | Out-String)
$keys = $keysJson | ConvertFrom-Json

$anonKey = ($keys | Where-Object { $_.id -eq 'anon' }).api_key
$serviceRoleKey = ($keys | Where-Object { $_.id -eq 'service_role' }).api_key

$anonHeaders = @{ apikey = $anonKey; Authorization = "Bearer $anonKey"; 'Content-Type' = 'application/json' }
$serviceHeaders = @{ apikey = $serviceRoleKey; Authorization = "Bearer $serviceRoleKey"; 'Content-Type' = 'application/json'; Prefer = 'return=representation' }

function Get-ProtocolsMap {
  $rows = Invoke-RestMethod -Uri "$base/rest/v1/power_cell_protocols?select=id,protocol_name" -Headers $serviceHeaders -Method GET
  $map = @{}
  foreach ($row in $rows) {
    $map[$row.protocol_name] = [int64]$row.id
  }
  return $map
}

function Reset-And-SeedPowerCellTypes {
  param([hashtable]$protocols)

  Invoke-RestMethod -Uri "$base/rest/v1/power_cell_types?id=gt.0" -Headers $serviceHeaders -Method DELETE | Out-Null

  $rows = @(
    @{ name='START-Foundation-10'; protocol_id=$protocols.START; zone_requirement=1; aisri_minimum=20; duration_minutes=10; intensity='easy'; description='Light warm-up and mobility activation' },
    @{ name='START-Dynamic-15'; protocol_id=$protocols.START; zone_requirement=1; aisri_minimum=30; duration_minutes=15; intensity='easy'; description='Dynamic drill sequence and movement prep' },
    @{ name='START-Complete-20'; protocol_id=$protocols.START; zone_requirement=1; aisri_minimum=40; duration_minutes=20; intensity='moderate'; description='Complete warm-up with coordination drills' },

    @{ name='ENGINE-Easy-30'; protocol_id=$protocols.ENGINE; zone_requirement=1; aisri_minimum=30; duration_minutes=30; intensity='easy'; description='Easy aerobic base run' },
    @{ name='ENGINE-Steady-45'; protocol_id=$protocols.ENGINE; zone_requirement=2; aisri_minimum=45; duration_minutes=45; intensity='moderate'; description='Steady aerobic conditioning run' },
    @{ name='ENGINE-Tempo-60'; protocol_id=$protocols.ENGINE; zone_requirement=3; aisri_minimum=60; duration_minutes=60; intensity='hard'; description='Tempo effort with sustained control' },
    @{ name='ENGINE-Long-90'; protocol_id=$protocols.ENGINE; zone_requirement=3; aisri_minimum=65; duration_minutes=90; intensity='moderate'; description='Extended endurance progression' },

    @{ name='OXYGEN-Intervals-30'; protocol_id=$protocols.OXYGEN; zone_requirement=4; aisri_minimum=65; duration_minutes=30; intensity='hard'; description='VO2 intervals with controlled recovery' },
    @{ name='OXYGEN-Threshold-40'; protocol_id=$protocols.OXYGEN; zone_requirement=4; aisri_minimum=70; duration_minutes=40; intensity='hard'; description='Threshold block session' },
    @{ name='OXYGEN-Peak-25'; protocol_id=$protocols.OXYGEN; zone_requirement=5; aisri_minimum=75; duration_minutes=25; intensity='very_hard'; description='Peak oxygen power intervals' },

    @{ name='POWER-Intervals-30'; protocol_id=$protocols.POWER; zone_requirement=4; aisri_minimum=70; duration_minutes=30; intensity='very_hard'; description='High-intensity power intervals' },
    @{ name='POWER-Hills-20'; protocol_id=$protocols.POWER; zone_requirement=4; aisri_minimum=65; duration_minutes=20; intensity='very_hard'; description='Short uphill sprint repeats' },
    @{ name='POWER-Fartlek-35'; protocol_id=$protocols.POWER; zone_requirement=4; aisri_minimum=70; duration_minutes=35; intensity='hard'; description='Variable speed power development' },
    @{ name='POWER-Track-40'; protocol_id=$protocols.POWER; zone_requirement=5; aisri_minimum=75; duration_minutes=40; intensity='very_hard'; description='Track speed and stride power' },

    @{ name='ZONES-Progressive-45'; protocol_id=$protocols.ZONES; zone_requirement=2; aisri_minimum=50; duration_minutes=45; intensity='moderate'; description='Progressive multi-zone conditioning' },
    @{ name='ZONES-Pyramid-50'; protocol_id=$protocols.ZONES; zone_requirement=3; aisri_minimum=60; duration_minutes=50; intensity='hard'; description='Pyramid heart-rate zone ladder' },
    @{ name='ZONES-Mixed-40'; protocol_id=$protocols.ZONES; zone_requirement=3; aisri_minimum=55; duration_minutes=40; intensity='moderate'; description='Alternating mixed-zone blocks' },

    @{ name='STRENGTH-Foundation-30'; protocol_id=$protocols.STRENGTH; zone_requirement=1; aisri_minimum=35; duration_minutes=30; intensity='moderate'; description='Core and stability base session' },
    @{ name='STRENGTH-Runners-40'; protocol_id=$protocols.STRENGTH; zone_requirement=1; aisri_minimum=40; duration_minutes=40; intensity='moderate'; description='Runner-focused lower body strength' },
    @{ name='STRENGTH-Power-45'; protocol_id=$protocols.STRENGTH; zone_requirement=2; aisri_minimum=50; duration_minutes=45; intensity='hard'; description='Explosive strength and plyometric mix' },
    @{ name='STRENGTH-Maintenance-25'; protocol_id=$protocols.STRENGTH; zone_requirement=1; aisri_minimum=30; duration_minutes=25; intensity='easy'; description='Short maintenance and prehab set' },

    @{ name='LONG_RUN-Base-60'; protocol_id=$protocols.LONG_RUN; zone_requirement=2; aisri_minimum=50; duration_minutes=60; intensity='easy'; description='Base long run at easy effort' },
    @{ name='LONG_RUN-Steady-75'; protocol_id=$protocols.LONG_RUN; zone_requirement=2; aisri_minimum=55; duration_minutes=75; intensity='moderate'; description='Steady state long endurance run' },
    @{ name='LONG_RUN-Progressive-90'; protocol_id=$protocols.LONG_RUN; zone_requirement=3; aisri_minimum=60; duration_minutes=90; intensity='moderate'; description='Progressive pace long run' },
    @{ name='LONG_RUN-Endurance-120'; protocol_id=$protocols.LONG_RUN; zone_requirement=3; aisri_minimum=65; duration_minutes=120; intensity='moderate'; description='Extended aerobic endurance run' },
    @{ name='LONG_RUN-Marathon-150'; protocol_id=$protocols.LONG_RUN; zone_requirement=3; aisri_minimum=70; duration_minutes=150; intensity='hard'; description='Marathon-specific long run' }
  )

  $json = $rows | ConvertTo-Json -Depth 6
  Invoke-RestMethod -Uri "$base/rest/v1/power_cell_types" -Headers $serviceHeaders -Method POST -Body $json | Out-Null
}

function New-ValidationUser {
  param([string]$email,[string]$password,[int]$aisri)

  $body = @{
    email = $email
    password = $password
    email_confirm = $true
    user_metadata = @{ aisri = $aisri }
  } | ConvertTo-Json -Depth 5

  $adminHeaders = @{ apikey = $serviceRoleKey; Authorization = "Bearer $serviceRoleKey"; 'Content-Type' = 'application/json' }
  $user = Invoke-RestMethod -Uri "$base/auth/v1/admin/users" -Headers $adminHeaders -Method POST -Body $body

  $tokenBody = @{ email = $email; password = $password } | ConvertTo-Json -Compress
  $token = Invoke-RestMethod -Uri "$base/auth/v1/token?grant_type=password" -Method POST -Headers $anonHeaders -Body $tokenBody

  return [PSCustomObject]@{
    userId = $user.id
    email = $email
    token = $token.access_token
  }
}

function Call-PowerCells {
  param([string]$token,[string]$userId)
  $headers = @{ apikey = $anonKey; Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }
  $body = @{ user_id = $userId } | ConvertTo-Json -Compress
  return Invoke-RestMethod -Uri "$base/functions/v1/power-cells-get" -Method POST -Headers $headers -Body $body
}

$protocols = Get-ProtocolsMap
Reset-And-SeedPowerCellTypes -protocols $protocols

$seedCount = Invoke-RestMethod -Uri "$base/rest/v1/power_cell_types?select=id" -Headers $serviceHeaders -Method GET

$u40 = New-ValidationUser -email ("pc40_live_" + [guid]::NewGuid().ToString('N').Substring(0,8) + '@example.com') -password 'PowerCell@123' -aisri 40
$r40 = Call-PowerCells -token $u40.token -userId $u40.userId

$u70 = New-ValidationUser -email ("pc70_live_" + [guid]::NewGuid().ToString('N').Substring(0,8) + '@example.com') -password 'PowerCell@123' -aisri 70
$r70 = Call-PowerCells -token $u70.token -userId $u70.userId

$protocols40 = @()
foreach ($cell in $r40.available_power_cells) {
  $p = $cell.power_cell_protocols
  if ($p -is [array]) { $protocols40 += $p[0].protocol_name } else { $protocols40 += $p.protocol_name }
}
$protocols40 = $protocols40 | Sort-Object -Unique

$firstCellId = $null
if (($r70.available_power_cells | Measure-Object).Count -gt 0) {
  $firstCellId = $r70.available_power_cells[0].id
}

if ($firstCellId) {
  $userHeaders = @{ apikey = $anonKey; Authorization = "Bearer $($u70.token)"; 'Content-Type' = 'application/json'; Prefer = 'return=representation' }
  $historyBody = @{
    user_id = $u70.userId
    power_cell_type_id = $firstCellId
    scheduled_date = (Get-Date).ToString('yyyy-MM-dd')
    completed_at = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    actual_duration_minutes = 35
    actual_distance_km = 5.25
    actual_pace_min_per_km = 6.10
    compliance_score = 95
    coach_notes = 'Production validation history row'
  } | ConvertTo-Json -Compress

  Invoke-RestMethod -Uri "$base/rest/v1/user_power_cells" -Headers $userHeaders -Method POST -Body $historyBody | Out-Null
}

$r70History = Call-PowerCells -token $u70.token -userId $u70.userId

$result = [PSCustomObject]@{
  seed = [PSCustomObject]@{
    protocolCount = ($protocols.Keys | Measure-Object).Count
    powerCellTypeCount = ($seedCount | Measure-Object).Count
  }
  scenario40 = [PSCustomObject]@{
    userAisri = $r40.user_aisri
    availableCount = ($r40.available_power_cells | Measure-Object).Count
    protocolNames = $protocols40
  }
  scenario70 = [PSCustomObject]@{
    userAisri = $r70.user_aisri
    availableCount = ($r70.available_power_cells | Measure-Object).Count
    protocolCount = ($r70.protocols | Measure-Object).Count
    historyCountAfterInsert = ($r70History.user_history | Measure-Object).Count
  }
  fieldsPresent = [PSCustomObject]@{
    available_power_cells = ($null -ne $r70History.available_power_cells)
    user_history = ($null -ne $r70History.user_history)
    user_aisri = ($null -ne $r70History.user_aisri)
    protocols = ($null -ne $r70History.protocols)
  }
}

$result | ConvertTo-Json -Depth 10