# SafeStride - Automated Database Backup Script
# Backs up production Supabase database to local files

param(
    [string]$BackupFolder = "database/backups"
)

$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$ProjectRef = "xzxnnswggwqtctcgpocr"
$DbPassword = "Akura@2026`$"

# Create backup folder
New-Item -ItemType Directory -Force -Path $BackupFolder | Out-Null

Write-Host "`n Starting database backup...`n" -ForegroundColor Cyan

# Backup schema
Write-Host "Backing up database schema..." -ForegroundColor Yellow
docker run --rm -e PGPASSWORD=$DbPassword postgres:16-alpine pg_dump `
    -h db.$ProjectRef.supabase.co `
    -p 5432 `
    -U postgres `
    -d postgres `
    --schema-only `
    --no-owner `
    --no-acl `
    -f "$BackupFolder/schema_$timestamp.sql" 2>&1 | Out-Null

# Backup data
Write-Host "Backing up database data..." -ForegroundColor Yellow
docker run --rm -e PGPASSWORD=$DbPassword postgres:16-alpine pg_dump `
    -h db.$ProjectRef.supabase.co `
    -p 5432 `
    -U postgres `
    -d postgres `
    --data-only `
    --no-owner `
    --no-acl `
    -f "$BackupFolder/data_$timestamp.sql" 2>&1 | Out-Null

# Full backup
Write-Host "Creating full backup..." -ForegroundColor Yellow
docker run --rm -e PGPASSWORD=$DbPassword postgres:16-alpine pg_dump `
    -h db.$ProjectRef.supabase.co `
    -p 5432 `
    -U postgres `
    -d postgres `
    --no-owner `
    --no-acl `
    > "$BackupFolder/full_backup_$timestamp.sql"

Write-Host "`n Backup complete!" -ForegroundColor Green
Write-Host "Files saved to: $BackupFolder" -ForegroundColor White
Write-Host "- schema_$timestamp.sql" -ForegroundColor Gray
Write-Host "- data_$timestamp.sql" -ForegroundColor Gray
Write-Host "- full_backup_$timestamp.sql" -ForegroundColor Gray

# Keep only last 7 backups
Write-Host "`nCleaning old backups (keeping last 7)..." -ForegroundColor Yellow
Get-ChildItem $BackupFolder -Filter "*.sql" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -Skip 21 | 
    Remove-Item -Force

Write-Host "`n Done!" -ForegroundColor Green
