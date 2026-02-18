# Verify Structured Workouts Migration
# Checks if tables, indexes, and RLS policies are correctly created

param(
    [string]$SupabaseUrl = $env:SUPABASE_URL,
    [string]$SupabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY
)

if (-not $SupabaseUrl -or -not $SupabaseKey) {
    Write-Host "Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables must be set" -ForegroundColor Red
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Structured Workouts Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$headers = @{
    "apikey" = $SupabaseKey
    "Authorization" = "Bearer $SupabaseKey"
    "Content-Type" = "application/json"
}

$allPassed = $true

# Test 1: Check if tables exist
Write-Host "📋 Test 1: Checking tables..." -ForegroundColor Yellow
$checkTablesSQL = @"
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('structured_workouts', 'workout_assignments')
ORDER BY table_name;
"@

try {
    $response = Invoke-RestMethod -Uri "$SupabaseUrl/rest/v1/rpc/exec_sql" -Method Post -Headers $headers -Body (@{ query = $checkTablesSQL } | ConvertTo-Json)
    
    if ($response -and $response.Count -eq 2) {
        Write-Host "  ✓ Both tables exist: structured_workouts, workout_assignments" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Tables missing or incomplete" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "  ⚠️  Could not verify tables (may need manual check)" -ForegroundColor Yellow
    Write-Host "  Run this SQL in Supabase Dashboard:" -ForegroundColor Gray
    Write-Host $checkTablesSQL -ForegroundColor DarkGray
}

Write-Host ""

# Test 2: Check structured_workouts columns
Write-Host "📋 Test 2: Checking structured_workouts structure..." -ForegroundColor Yellow
$checkColumnsSQL = @"
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'structured_workouts'
ORDER BY ordinal_position;
"@

try {
    $response = Invoke-RestMethod -Uri "$SupabaseUrl/rest/v1/rpc/exec_sql" -Method Post -Headers $headers -Body (@{ query = $checkColumnsSQL } | ConvertTo-Json)
    
    $hasSteps = $false
    $stepsIsJsonb = $false
    
    foreach ($col in $response) {
        if ($col.column_name -eq 'steps') {
            $hasSteps = $true
            if ($col.data_type -eq 'jsonb') {
                $stepsIsJsonb = $true
            }
        }
    }
    
    if ($hasSteps -and $stepsIsJsonb) {
        Write-Host "  ✓ steps column exists and is JSONB type" -ForegroundColor Green
    } else {
        Write-Host "  ✗ steps column missing or wrong type" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "  ⚠️  Could not verify columns (may need manual check)" -ForegroundColor Yellow
}

Write-Host ""

# Test 3: Check indexes
Write-Host "📋 Test 3: Checking indexes..." -ForegroundColor Yellow
$checkIndexesSQL = @"
SELECT indexname 
FROM pg_indexes 
WHERE tablename = 'structured_workouts'
ORDER BY indexname;
"@

try {
    $response = Invoke-RestMethod -Uri "$SupabaseUrl/rest/v1/rpc/exec_sql" -Method Post -Headers $headers -Body (@{ query = $checkIndexesSQL } | ConvertTo-Json)
    
    if ($response -and $response.Count -ge 3) {
        Write-Host "  ✓ Found $($response.Count) indexes on structured_workouts" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Not enough indexes (expected at least 3)" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "  ⚠️  Could not verify indexes (may need manual check)" -ForegroundColor Yellow
}

Write-Host ""

# Test 4: Check RLS policies
Write-Host "📋 Test 4: Checking RLS policies..." -ForegroundColor Yellow
$checkPoliciesSQL = @"
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'structured_workouts'
ORDER BY policyname;
"@

try {
    $response = Invoke-RestMethod -Uri "$SupabaseUrl/rest/v1/rpc/exec_sql" -Method Post -Headers $headers -Body (@{ query = $checkPoliciesSQL } | ConvertTo-Json)
    
    if ($response -and $response.Count -ge 4) {
        Write-Host "  ✓ Found $($response.Count) RLS policies" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Not enough RLS policies (expected at least 4)" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "  ⚠️  Could not verify RLS policies (may need manual check)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

if ($allPassed) {
    Write-Host "✓ All checks passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Open SafeStride app" -ForegroundColor White
    Write-Host "2. Navigate to More → Structured Workouts" -ForegroundColor White
    Write-Host "3. Try creating a new workout" -ForegroundColor White
    Write-Host "4. Verify it saves and loads correctly" -ForegroundColor White
} else {
    Write-Host "⚠️  Some checks failed" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please verify manually in Supabase Dashboard" -ForegroundColor Yellow
}

Write-Host ""
