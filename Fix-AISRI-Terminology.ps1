# AISRI Terminology Correction Script
# Replaces all instances of AISRI with AISRI
# Date: 2026-02-10

param(
    [string]$ProjectRoot = "C:\safestride"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AISRI Terminology Correction Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Project: $ProjectRoot" -ForegroundColor Yellow
Write-Host ""
Write-Host "WARNING: This will replace:" -ForegroundColor Yellow
Write-Host "  AISRI -> AISRI" -ForegroundColor White
Write-Host "  AISRI -> aisri" -ForegroundColor White
Write-Host "  AISRI -> Aisri" -ForegroundColor White
Write-Host ""
Write-Host "Press Enter to continue or Ctrl+C to cancel..."
Read-Host

# File extensions to search
$extensions = @("*.dart", "*.sql", "*.md", "*.yaml", "*.json", "*.txt", "*.ps1")

# Directories to exclude
$excludeDirs = @(".dart_tool", "build", ".git", "node_modules", ".idea", "android", "ios", "windows", "linux", "macos", "web")

$totalFiles = 0
$totalReplacements = 0
$modifiedFiles = @()

Write-Host "Scanning files..." -ForegroundColor Cyan
Write-Host ""

foreach ($ext in $extensions) {
    $files = Get-ChildItem -Path $ProjectRoot -Filter $ext -Recurse -File -ErrorAction SilentlyContinue | 
        Where-Object { 
            $exclude = $false
            foreach ($dir in $excludeDirs) {
                if ($_.FullName -like "*\$dir\*") {
                    $exclude = $true
                    break
                }
            }
            -not $exclude
        }
    
    foreach ($file in $files) {
        try {
            $content = Get-Content $file.FullName -Raw -ErrorAction Stop
            
            if ($content -match "AISRI|AISRI|AISRI") {
                $originalContent = $content
                
                # Replace all variations (case-sensitive)
                $content = $content -replace "AISRI", "AISRI"
                $content = $content -creplace "AISRI", "aisri"
                $content = $content -replace "AISRI", "Aisri"
                
                # Count replacements
                $replacements = ([regex]::Matches($originalContent, "AISRI|AISRI|AISRI")).Count
                
                if ($content -ne $originalContent) {
                    Set-Content -Path $file.FullName -Value $content -NoNewline -Force
                    
                    $relativePath = $file.FullName.Replace($ProjectRoot, "").TrimStart('\')
                    Write-Host "  [OK] $relativePath" -ForegroundColor Green
                    Write-Host "       ($replacements replacements)" -ForegroundColor Gray
                    
                    $totalFiles++
                    $totalReplacements += $replacements
                    $modifiedFiles += $relativePath
                }
            }
        }
        catch {
            Write-Host "  [WARNING] Could not process: $($file.Name)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Correction Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Statistics:" -ForegroundColor Cyan
Write-Host "  Files modified: $totalFiles" -ForegroundColor White
Write-Host "  Total replacements: $totalReplacements" -ForegroundColor White
Write-Host ""

if ($totalFiles -gt 0) {
    Write-Host "Modified files:" -ForegroundColor Cyan
    foreach ($file in $modifiedFiles) {
        Write-Host "  - $file" -ForegroundColor Gray
    }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  IMPORTANT NEXT STEPS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Review changes:" -ForegroundColor White
Write-Host "   flutter analyze" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Manually rename service file:" -ForegroundColor White
Write-Host "   lib\services\AISRI_calculator_service.dart" -ForegroundColor Gray
Write-Host "   -> lib\services\aisri_calculator_service.dart" -ForegroundColor Green
Write-Host ""
Write-Host "3. Deploy database migration:" -ForegroundColor White
Write-Host "   .\database\migration_fix_aisri_terminology.sql" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Test app thoroughly:" -ForegroundColor White
Write-Host "   flutter run" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Commit changes:" -ForegroundColor White
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "   git commit -m 'Fix: Correct AISRI to AISRI terminology'" -ForegroundColor Gray
Write-Host ""

# Check if service file exists and needs renaming
$serviceFile = Join-Path $ProjectRoot "lib\services\AISRI_calculator_service.dart"
if (Test-Path $serviceFile) {
    Write-Host "Action Required:" -ForegroundColor Yellow
    Write-Host "  The file 'AISRI_calculator_service.dart' still needs to be renamed manually" -ForegroundColor White
    Write-Host "  Use VS Code or File Explorer to rename it to 'aisri_calculator_service.dart'" -ForegroundColor White
    Write-Host ""
}

Write-Host "[SUCCESS] Script completed successfully!" -ForegroundColor Green
Write-Host ""
