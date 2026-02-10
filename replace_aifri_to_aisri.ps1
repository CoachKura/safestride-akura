# PowerShell script to replace all AISRI variants with AISRI across the SafeStride codebase
# Date: 2026-02-10

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  AISRI -> AISRI Replacement Script" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Define file extensions to process
$extensions = @('*.dart', '*.sql', '*.md', '*.txt', '*.yaml', '*.json', '*.ps1', '*.py')

# Define directories to exclude
$excludeDirs = @('build', '.dart_tool', '.git', 'node_modules', '.idea', 'windows', 'linux', 'macos', 'ios', 'android')

# Get all files to process
$files = Get-ChildItem -Path "c:\safestride" -Recurse -File -Include $extensions -ErrorAction SilentlyContinue | 
    Where-Object { 
        $path = $_.FullName
        -not ($excludeDirs | Where-Object { $path -match "\\$_\\" })
    }

Write-Host "Found $($files.Count) files to scan..." -ForegroundColor Yellow

$processedFiles = @()
$skippedFiles = @()
$errorFiles = @()

foreach ($file in $files) {
    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
        
        # Check if file contains any AISRI variant
        if ($content -match 'AISRI|AISRI|AISRI') {
            $originalContent = $content
            
            # Replace all variants (case-sensitive)
            $content = $content -creplace 'AISRI', 'AISRI'
            $content = $content -creplace 'AISRI', 'aisri'
            $content = $content -creplace 'AISRI', 'Aisri'
            
            # Only save if changes were made
            if ($content -ne $originalContent) {
                [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::UTF8)
                $processedFiles += $file.FullName
                Write-Host "  [OK] Updated: $($file.Name)" -ForegroundColor Green
            } else {
                $skippedFiles += $file.FullName
            }
        }
    }
    catch {
        Write-Host "  [ERROR] Error processing: $($file.Name) - $_" -ForegroundColor Red
        $errorFiles += $file.FullName
    }
}

# Rename files with 'AISRI' in their names
Write-Host "`nRenaming files with 'AISRI' in their names..." -ForegroundColor Yellow

$filesToRename = Get-ChildItem -Path "c:\safestride" -Recurse -File -ErrorAction SilentlyContinue | 
    Where-Object { 
        $path = $_.FullName
        $_.Name -match 'AISRI' -and -not ($excludeDirs | Where-Object { $path -match "\\$_\\" })
    }

foreach ($file in $filesToRename) {
    $newName = $file.Name -replace 'AISRI', 'aisri'
    $newPath = Join-Path $file.DirectoryName $newName
    
    if (Test-Path $newPath) {
        Write-Host "  [SKIP] Skipped rename (target exists): $($file.Name)" -ForegroundColor Yellow
    } else {
        try {
            Move-Item -Path $file.FullName -Destination $newPath -ErrorAction Stop
            Write-Host "  [OK] Renamed: $($file.Name) -> $newName" -ForegroundColor Green
        } catch {
            Write-Host "  [ERROR] Error renaming: $($file.Name) - $_" -ForegroundColor Red
        }
    }
}

# Print summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  REPLACEMENT SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Files updated: $($processedFiles.Count)" -ForegroundColor Green
Write-Host "Files skipped: $($skippedFiles.Count)" -ForegroundColor Yellow
Write-Host "Errors: $($errorFiles.Count)" -ForegroundColor Red

if ($processedFiles.Count -gt 0) {
    Write-Host "`nUpdated files:" -ForegroundColor Green
    $processedFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
}

Write-Host "`nReplacement complete!`n" -ForegroundColor Green
