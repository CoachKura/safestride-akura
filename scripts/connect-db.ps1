# SafeStride - Connect to Supabase Database via Docker
param([string]$Password)

$ProjectRef = "xzxnnswggwqtctcgpocr"
$DbHost = "db.bdisppaxbvygsspcuymb.supabase.co"
$DbPort = "5432"
$Database = "postgres"
$DbUser = "postgres"
$DefaultPassword = "Akura@2026`$"

Write-Host "`nConnecting to Supabase Database via Docker..." -ForegroundColor Cyan
Write-Host "Project: $ProjectRef" -ForegroundColor Gray

if (-not $Password) {
    $Password = $DefaultPassword
    Write-Host "Using saved credentials..." -ForegroundColor Gray
}

Write-Host "Pulling PostgreSQL client image..." -ForegroundColor Gray
docker pull postgres:16-alpine 2>&1 | Out-Null

Write-Host "Connecting...`n" -ForegroundColor Green

docker run -it --rm -e PGPASSWORD=$Password postgres:16-alpine psql -h $DbHost -p $DbPort -U $DbUser -d $Database

Write-Host "`nDisconnected" -ForegroundColor Green
