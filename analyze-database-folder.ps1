# Analysis of database folder
$files = Get-ChildItem -Path "database\*.sql" | Select-Object Name, Length, LastWriteTime

Write-Host "`n DATABASE FOLDER ANALYSIS:" -ForegroundColor Cyan
Write-Host ("=" * 70)
Write-Host ""

# Categorize files
$migrations = $files | Where-Object { $_.Name -like "migration_*" }
$fixes = $files | Where-Object { $_.Name -like "fix_*" }
$checks = $files | Where-Object { $_.Name -like "check_*" -or $_.Name -like "verify_*" }
$core = $files | Where-Object { $_.Name -eq "schema.sql" -or $_.Name -like "MASTER_*" }
$others = $files | Where-Object { $migrations -notcontains $_ -and $fixes -notcontains $_ -and $checks -notcontains $_ -and $core -notcontains $_ }

Write-Host " CORE SCHEMA FILES ($($core.Count)):" -ForegroundColor Blue
$core | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor Green }

Write-Host "`n VERIFICATION FILES ($($checks.Count)):" -ForegroundColor Green  
$checks | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor Green }

Write-Host "`n LEGACY MIGRATION FILES ($($migrations.Count)):" -ForegroundColor Yellow
$migrations | ForEach-Object { Write-Host "     $($_.Name)" -ForegroundColor Yellow }

Write-Host "`n FIX/PATCH FILES ($($fixes.Count)):" -ForegroundColor DarkYellow
$fixes | ForEach-Object { Write-Host "     $($_.Name)" -ForegroundColor DarkYellow }

Write-Host "`n OTHER FILES ($($others.Count)):" -ForegroundColor Red
$others | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor White }

Write-Host "`n" + ("=" * 70)
Write-Host "TOTAL: $($files.Count) SQL files" -ForegroundColor Cyan
Write-Host ""
