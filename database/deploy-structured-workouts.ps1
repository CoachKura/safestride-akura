# Deploy Structured Workouts Migration
# Run this script to create structured_workouts and workout_assignments tables

param(
    [string]$SupabaseUrl = $env:SUPABASE_URL,
    [string]$SupabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY
)

if (-not $SupabaseUrl -or -not $SupabaseKey) {
    Write-Host "Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables must be set" -ForegroundColor Red
    Write-Host ""
    Write-Host "Set them with:" -ForegroundColor Yellow
    Write-Host '$env:SUPABASE_URL = "https://your-project.supabase.co"'
    Write-Host '$env:SUPABASE_SERVICE_ROLE_KEY = "your-service-role-key"'
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Structured Workouts Migration Deploy" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$migrationFile = Join-Path $PSScriptRoot "migration_structured_workouts.sql"

if (-not (Test-Path $migrationFile)) {
    Write-Host "✗ Migration file not found: $migrationFile" -ForegroundColor Red
    exit 1
}

Write-Host "📖 Reading migration file..." -ForegroundColor Yellow
$sql = Get-Content $migrationFile -Raw

Write-Host "🚀 Deploying to Supabase..." -ForegroundColor Yellow

# Note: Supabase doesn't have a direct exec_sql RPC endpoint by default
# We'll need to run this through the SQL Editor in the dashboard
# But we'll create a helper to show what needs to be done

Write-Host ""
Write-Host "⚠️  MANUAL DEPLOYMENT REQUIRED" -ForegroundColor Yellow
Write-Host ""
Write-Host "This migration must be run through the Supabase Dashboard:"
Write-Host ""
Write-Host "1. Open Supabase Dashboard: https://app.supabase.com" -ForegroundColor Cyan
Write-Host "2. Select your project" -ForegroundColor Cyan
Write-Host "3. Go to SQL Editor (left sidebar)" -ForegroundColor Cyan
Write-Host "4. Click 'New Query'" -ForegroundColor Cyan
Write-Host "5. Copy and paste the contents of:" -ForegroundColor Cyan
Write-Host "   $migrationFile" -ForegroundColor Green
Write-Host "6. Click 'Run' (or press Ctrl+Enter)" -ForegroundColor Cyan
Write-Host "7. Verify success message" -ForegroundColor Cyan
Write-Host ""
Write-Host "After deployment, run:" -ForegroundColor Yellow
Write-Host "  .\verify-structured-workouts.ps1" -ForegroundColor Green
Write-Host ""
Write-Host "📋 What this migration creates:" -ForegroundColor Cyan
Write-Host "  ✓ structured_workouts table (with JSONB steps column)" -ForegroundColor Green
Write-Host "  ✓ workout_assignments table (links workouts to athletes)" -ForegroundColor Green
Write-Host "  ✓ Indexes for performance" -ForegroundColor Green
Write-Host "  ✓ RLS policies for security" -ForegroundColor Green
Write-Host "  ✓ Triggers for updated_at timestamps" -ForegroundColor Green
Write-Host ""

# Copy SQL to clipboard if possible
if (Get-Command Set-Clipboard -ErrorAction SilentlyContinue) {
    try {
        Set-Clipboard -Value $sql
        Write-Host "✓ Migration SQL copied to clipboard!" -ForegroundColor Green
        Write-Host "  Just paste it into the Supabase SQL Editor" -ForegroundColor Gray
        Write-Host ""
    } catch {
        Write-Host "ℹ️  Could not copy to clipboard" -ForegroundColor DarkGray
    }
}

# Open the SQL file in VS Code if available
if (Get-Command code -ErrorAction SilentlyContinue) {
    try {
        Write-Host "📝 Opening migration file in VS Code..." -ForegroundColor Yellow
        & code $migrationFile
    } catch {
        # Silent fail
    }
}

Write-Host "Press any key to exit..."
Read-Host
