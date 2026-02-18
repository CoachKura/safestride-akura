# Create organized database folder structure
Write-Host "`n CLEANING UP DATABASE FOLDER..." -ForegroundColor Cyan
Write-Host ("=" * 50)

# Create archive folders
New-Item -Path "database\archive" -ItemType Directory -Force | Out-Null
New-Item -Path "database\migrations_old" -ItemType Directory -Force | Out-Null
New-Item -Path "database\fixes_history" -ItemType Directory -Force | Out-Null

# Move legacy migrations
$migrations = Get-ChildItem "database\migration_*.sql"
if ($migrations) {
    Write-Host "`n Archiving $($migrations.Count) legacy migration files..."
    $migrations | Move-Item -Destination "database\migrations_old\" -Force
    Write-Host "    Moved to: database\migrations_old\" -ForegroundColor Green
}

# Move fix files
$fixes = Get-ChildItem "database\fix_*.sql", "database\QUICK_FIX_*.sql"
if ($fixes) {
    Write-Host "`n Archiving $($fixes.Count) fix/patch files..."
    $fixes | Move-Item -Destination "database\fixes_history\" -Force
    Write-Host "    Moved to: database\fixes_history\" -ForegroundColor Green
}

# Move old schema files
$oldSchema = Get-ChildItem "database\schema-fixed.sql", "database\schema_athlete_calendar.sql"
if ($oldSchema) {
    Write-Host "`n Archiving old schema variants..."
    $oldSchema | Move-Item -Destination "database\archive\" -Force
    Write-Host "    Moved to: database\archive\" -ForegroundColor Green
}

Write-Host "`n CLEANUP COMPLETE!" -ForegroundColor Green
Write-Host "`n NEW STRUCTURE:"
Write-Host "   database/"
Write-Host "    schema.sql                    (Master schema)"
Write-Host "    MASTER_UNIFIED_MIGRATION.sql  (Backup)"
Write-Host "    verify_schema.sql             (Verification)"
Write-Host "    check_workouts_schema.sql     (Quick checks)"
Write-Host "    verify_garmin_tables.sql      (Garmin checks)"
Write-Host "    archive/                      (Old versions)"
Write-Host "    migrations_old/               ($($migrations.Count) old migrations)"
Write-Host "    fixes_history/                ($($fixes.Count) old fixes)"
Write-Host ""
Write-Host " TIP: Keep only essential files in database/ root" -ForegroundColor Yellow
Write-Host ""
