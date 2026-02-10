# Simple AISRI fix script for Dart files
$files = Get-ChildItem -Path "C:\safestride\lib" -Filter "*.dart" -Recurse
$count = 0

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    
    if ($content -match 'AISRI|AISRI|AISRI') {
        # Replace all variations
        $newContent = $content -replace 'AISRI', 'AISRI'
        $newContent = $newContent -creplace 'AISRI', 'aisri'
        $newContent = $newContent -replace 'AISRI', 'Aisri'
        
        # Save the file
        [System.IO.File]::WriteAllText($file.FullName, $newContent, [System.Text.Encoding]::UTF8)
        
        $count++
        Write-Host "[OK] $($file.Name)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Fixed $count Dart files" -ForegroundColor Cyan
