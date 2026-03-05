$ErrorActionPreference = 'Stop'
$base = 'https://bdisppaxbvygsspcuymb.supabase.co'

$keysJson = (& 'C:\Users\kbsat\scoop\shims\supabase.exe' projects api-keys --project-ref bdisppaxbvygsspcuymb -o json | Out-String)
$keys = $keysJson | ConvertFrom-Json
$serviceRoleKey = ($keys | Where-Object { $_.id -eq 'service_role' }).api_key

$headers = @{ apikey = $serviceRoleKey; Authorization = "Bearer $serviceRoleKey"; 'Content-Type' = 'application/json'; Prefer = 'return=representation' }

$protocolRows = Invoke-RestMethod -Uri "$base/rest/v1/power_cell_protocols?select=id,protocol_code" -Method GET -Headers $headers
$protocolMap = @{}
foreach ($row in $protocolRows) {
  $protocolMap[$row.protocol_code] = $row.id
}

Invoke-RestMethod -Uri "$base/rest/v1/power_cell_types?id=not.is.null" -Method DELETE -Headers $headers | Out-Null

$rows = @(
  @{ name='START-Foundation-10'; protocol_id=$protocolMap.START; zone_requirement=1; aisri_minimum=20; duration_minutes=10; intensity='easy'; description='Light warm-up and mobility activation'; is_active=$true },
  @{ name='START-Dynamic-15'; protocol_id=$protocolMap.START; zone_requirement=1; aisri_minimum=30; duration_minutes=15; intensity='easy'; description='Dynamic drill sequence and movement prep'; is_active=$true },
  @{ name='START-Complete-20'; protocol_id=$protocolMap.START; zone_requirement=1; aisri_minimum=40; duration_minutes=20; intensity='moderate'; description='Complete warm-up with coordination drills'; is_active=$true },

  @{ name='ENGINE-Easy-30'; protocol_id=$protocolMap.ENGINE; zone_requirement=1; aisri_minimum=30; duration_minutes=30; intensity='easy'; description='Easy aerobic base run'; is_active=$true },
  @{ name='ENGINE-Steady-45'; protocol_id=$protocolMap.ENGINE; zone_requirement=2; aisri_minimum=45; duration_minutes=45; intensity='moderate'; description='Steady aerobic conditioning run'; is_active=$true },
  @{ name='ENGINE-Tempo-60'; protocol_id=$protocolMap.ENGINE; zone_requirement=3; aisri_minimum=60; duration_minutes=60; intensity='hard'; description='Tempo effort with sustained control'; is_active=$true },
  @{ name='ENGINE-Long-90'; protocol_id=$protocolMap.ENGINE; zone_requirement=3; aisri_minimum=65; duration_minutes=90; intensity='moderate'; description='Extended endurance progression'; is_active=$true },

  @{ name='OXYGEN-Intervals-30'; protocol_id=$protocolMap.OXYGEN; zone_requirement=4; aisri_minimum=65; duration_minutes=30; intensity='hard'; description='VO2 intervals with controlled recovery'; is_active=$true },
  @{ name='OXYGEN-Threshold-40'; protocol_id=$protocolMap.OXYGEN; zone_requirement=4; aisri_minimum=70; duration_minutes=40; intensity='hard'; description='Threshold block session'; is_active=$true },
  @{ name='OXYGEN-Peak-25'; protocol_id=$protocolMap.OXYGEN; zone_requirement=5; aisri_minimum=75; duration_minutes=25; intensity='very_hard'; description='Peak oxygen power intervals'; is_active=$true },

  @{ name='POWER-Intervals-30'; protocol_id=$protocolMap.POWER; zone_requirement=4; aisri_minimum=70; duration_minutes=30; intensity='very_hard'; description='High-intensity power intervals'; is_active=$true },
  @{ name='POWER-Hills-20'; protocol_id=$protocolMap.POWER; zone_requirement=4; aisri_minimum=65; duration_minutes=20; intensity='very_hard'; description='Short uphill sprint repeats'; is_active=$true },
  @{ name='POWER-Fartlek-35'; protocol_id=$protocolMap.POWER; zone_requirement=4; aisri_minimum=70; duration_minutes=35; intensity='hard'; description='Variable speed power development'; is_active=$true },
  @{ name='POWER-Track-40'; protocol_id=$protocolMap.POWER; zone_requirement=5; aisri_minimum=75; duration_minutes=40; intensity='very_hard'; description='Track speed and stride power'; is_active=$true },

  @{ name='ZONES-Progressive-45'; protocol_id=$protocolMap.ZONES; zone_requirement=2; aisri_minimum=50; duration_minutes=45; intensity='moderate'; description='Progressive multi-zone conditioning'; is_active=$true },
  @{ name='ZONES-Pyramid-50'; protocol_id=$protocolMap.ZONES; zone_requirement=3; aisri_minimum=60; duration_minutes=50; intensity='hard'; description='Pyramid heart-rate zone ladder'; is_active=$true },
  @{ name='ZONES-Mixed-40'; protocol_id=$protocolMap.ZONES; zone_requirement=3; aisri_minimum=55; duration_minutes=40; intensity='moderate'; description='Alternating mixed-zone blocks'; is_active=$true },

  @{ name='STRENGTH-Foundation-30'; protocol_id=$protocolMap.STRENGTH; zone_requirement=1; aisri_minimum=35; duration_minutes=30; intensity='moderate'; description='Core and stability base session'; is_active=$true },
  @{ name='STRENGTH-Runners-40'; protocol_id=$protocolMap.STRENGTH; zone_requirement=1; aisri_minimum=40; duration_minutes=40; intensity='moderate'; description='Runner-focused lower body strength'; is_active=$true },
  @{ name='STRENGTH-Power-45'; protocol_id=$protocolMap.STRENGTH; zone_requirement=2; aisri_minimum=50; duration_minutes=45; intensity='hard'; description='Explosive strength and plyometric mix'; is_active=$true },
  @{ name='STRENGTH-Maintenance-25'; protocol_id=$protocolMap.STRENGTH; zone_requirement=1; aisri_minimum=30; duration_minutes=25; intensity='easy'; description='Short maintenance and prehab set'; is_active=$true },

  @{ name='LONG_RUN-Base-60'; protocol_id=$protocolMap.LONG_RUN; zone_requirement=2; aisri_minimum=50; duration_minutes=60; intensity='easy'; description='Base long run at easy effort'; is_active=$true },
  @{ name='LONG_RUN-Steady-75'; protocol_id=$protocolMap.LONG_RUN; zone_requirement=2; aisri_minimum=55; duration_minutes=75; intensity='moderate'; description='Steady state long endurance run'; is_active=$true },
  @{ name='LONG_RUN-Progressive-90'; protocol_id=$protocolMap.LONG_RUN; zone_requirement=3; aisri_minimum=60; duration_minutes=90; intensity='moderate'; description='Progressive pace long run'; is_active=$true },
  @{ name='LONG_RUN-Endurance-120'; protocol_id=$protocolMap.LONG_RUN; zone_requirement=3; aisri_minimum=65; duration_minutes=120; intensity='moderate'; description='Extended aerobic endurance run'; is_active=$true },
  @{ name='LONG_RUN-Marathon-150'; protocol_id=$protocolMap.LONG_RUN; zone_requirement=3; aisri_minimum=70; duration_minutes=150; intensity='hard'; description='Marathon-specific long run'; is_active=$true }
)

Invoke-RestMethod -Uri "$base/rest/v1/power_cell_types" -Method POST -Headers $headers -Body ($rows | ConvertTo-Json -Depth 6) | Out-Null

$count = Invoke-RestMethod -Uri "$base/rest/v1/power_cell_types?select=id" -Method GET -Headers $headers
Write-Output ('Seeded power_cell_types=' + $count.Count)
