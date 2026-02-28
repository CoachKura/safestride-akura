# SafeStride - Database Restore Script
# Restores from backup file

param(
    [Parameter(Mandatory=$true)]
    [string]$BackupFile,
    [string]$Target = "local"  # "local" or "production"
)

Write-Host "`n Restoring database from backup...`n" -ForegroundColor Cyan

if ($Target -eq "local") {
    Write-Host "Restoring to LOCAL database..." -ForegroundColor Yellow
    Get-Content $BackupFile | docker exec -i supabase_db_safestride psql -U postgres -d postgres
} else {
    Write-Host "Restoring to PRODUCTION database..." -ForegroundColor Red
    Write-Host "  This will overwrite production data!" -ForegroundColor Yellow
    $confirm = Read-Host "Type YES to continue"
    if ($confirm -eq "YES") {
        $DbPassword = "Akura@2026`$"
        $ProjectRef = "xzxnnswggwqtctcgpocr"
        Get-Content $BackupFile | docker run --rm -i -e PGPASSWORD=$DbPassword postgres:16-alpine psql -h db.$ProjectRef.supabase.co -p 5432 -U postgres -d postgres
    } else {
        Write-Host "Restore cancelled." -ForegroundColor Gray
        exit
    }
}

Write-Host "`n Restore complete!" -ForegroundColor Green
