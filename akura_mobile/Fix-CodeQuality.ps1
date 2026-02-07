<#
.SYNOPSIS
    SafeStride Code Quality Auto-Fixer (PowerShell Version)
    
.DESCRIPTION
    Fixes all warnings from flutter analyze:
    1. Replaces print() with developer.log()
    2. Replaces deprecated withOpacity() with withValues()
    3. Fixes form field value -> initialValue
    4. Removes unused imports
    5. Adds library directives for dangling doc comments
    
.PARAMETER ProjectRoot
    Path to SafeStride project root (defaults to current directory)
    
.EXAMPLE
    .\Fix-CodeQuality.ps1
    
.EXAMPLE
    .\Fix-CodeQuality.ps1 -ProjectRoot "E:\Akura Safe Stride\safestride\akura_mobile"
#>

param(
    [string]$ProjectRoot = $PWD
)

$ErrorActionPreference = "Stop"

# Statistics
$Stats = @{
    FilesProcessed = 0
    PrintFixed = 0
    WithOpacityFixed = 0
    FormValueFixed = 0
    ImportsRemoved = 0
    LibraryAdded = 0
}

function Write-Header {
    Write-Host ""
    Write-Host "🚀 SafeStride Code Quality Auto-Fixer" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host ""
}

function Write-Summary {
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Green
    Write-Host "📊 FIX SUMMARY" -ForegroundColor Green
    Write-Host ("=" * 60) -ForegroundColor Green
    Write-Host "Files processed:        $($Stats.FilesProcessed)"
    Write-Host "print -> log:           $($Stats.PrintFixed)"
    Write-Host "withOpacity -> withValues: $($Stats.WithOpacityFixed)"
    Write-Host "value -> initialValue:  $($Stats.FormValueFixed)"
    Write-Host "Unused imports removed: $($Stats.ImportsRemoved)"
    Write-Host "Library directives added: $($Stats.LibraryAdded)"
    Write-Host ("=" * 60) -ForegroundColor Green
    Write-Host ""
    Write-Host "✨ All fixes applied!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📝 Next steps:" -ForegroundColor Yellow
    Write-Host "1. Run: flutter analyze"
    Write-Host "2. Verify no errors"
    Write-Host "3. Test build: flutter build apk --debug"
    Write-Host "4. Commit: git add . && git commit -m 'Fix: Code quality improvements'"
    Write-Host ""
}

function Fix-PrintStatements {
    param([string]$Content, [string]$FilePath)
    
    # Check if file already has developer import
    $hasDeveloperImport = $Content -match "dart:developer"
    
    # Find all print() statements
    $printMatches = [regex]::Matches($Content, "\bprint\s*\(")
    
    if ($printMatches.Count -eq 0) {
        return $Content
    }
    
    # Add developer import if needed
    if (-not $hasDeveloperImport) {
        # Find the last import line
        $importMatches = [regex]::Matches($Content, "^import\s+[^;]+;$", [System.Text.RegularExpressions.RegexOptions]::Multiline)
        
        if ($importMatches.Count -gt 0) {
            $lastImportEnd = $importMatches[-1].Index + $importMatches[-1].Length
            $Content = $Content.Substring(0, $lastImportEnd) + "`nimport 'dart:developer' as developer;" + $Content.Substring($lastImportEnd)
        }
        else {
            # No imports, add at beginning
            $Content = "import 'dart:developer' as developer;`n" + $Content
        }
    }
    
    # Replace print() with developer.log()
    $Stats.PrintFixed += $printMatches.Count
    $Content = $Content -replace "\bprint\s*\(", "developer.log("
    
    return $Content
}

function Fix-WithOpacity {
    param([string]$Content)
    
    $pattern = "\.withOpacity\(([^)]+)\)"
    $matches = [regex]::Matches($Content, $pattern)
    
    if ($matches.Count -eq 0) {
        return $Content
    }
    
    $Stats.WithOpacityFixed += $matches.Count
    $Content = $Content -replace $pattern, ".withValues(alpha: `$1)"
    
    return $Content
}

function Fix-FormValueParameter {
    param([string]$Content)
    
    $pattern = "(TextFormField\s*\([^)]*)\bvalue:\s*"
    $matches = [regex]::Matches($Content, $pattern)
    
    if ($matches.Count -eq 0) {
        return $Content
    }
    
    $Stats.FormValueFixed += $matches.Count
    $Content = $Content -replace $pattern, "`$1initialValue: "
    
    return $Content
}

function Add-LibraryDirective {
    param([string]$Content, [string]$FileName)
    
    # Generate library name from file name first
    $libName = [System.IO.Path]::GetFileNameWithoutExtension($FileName) -replace '-', '_' -replace ' ', '_'
    
    # Check if library directive already exists anywhere in the file
    if ($Content -match "library\s+$libName\s*;") {
        return $Content
    }
    
    $lines = $Content -split "`n"
    
    # Only add library directive if doc comment is at the START of the file (before imports)
    $hasDocCommentAtStart = $false
    $docCommentEnd = -1
    $seenNonCommentCode = $false
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $stripped = $lines[$i].Trim()
        
        # Skip empty lines at start
        if (-not $stripped) {
            continue
        }
        
        # Check if this is a doc comment
        if ($stripped.StartsWith('///')) {
            if (-not $seenNonCommentCode) {
                $hasDocCommentAtStart = $true
            }
        }
        # If we hit a non-doc-comment, non-empty line
        elseif ($hasDocCommentAtStart -and -not $seenNonCommentCode) {
            $docCommentEnd = $i
            break
        }
        # If this is an import or other code, we're past the start
        elseif ($stripped.StartsWith('import ') -or $stripped.StartsWith('library ') -or $stripped.StartsWith('class ')) {
            $seenNonCommentCode = $true
            break
        }
    }
    
    if (-not $hasDocCommentAtStart -or $docCommentEnd -le 0) {
        return $Content
    }
    
    # Check if library directive already exists at expected position
    $nextLine = $lines[$docCommentEnd].Trim()
    if ($nextLine.StartsWith('library ')) {
        return $Content
    }
    
   # Add library directive
    $lines = @($lines[0..($docCommentEnd-1)]) + "library $libName;" + "" + @($lines[$docCommentEnd..($lines.Count-1)])
    $Stats.LibraryAdded++
    return ($lines -join "`n")
}

function Remove-UnusedImports {
    param([string]$Content, [string]$FileName)
    
    # Known unused imports from analysis
    $unusedMap = @{
        'evaluation_form_screen.dart' = @('dashboard_screen.dart')
        'assessment_report_generator.dart' = @('package:flutter/foundation.dart')
    }
    
    if (-not $unusedMap.ContainsKey($FileName)) {
        return $Content
    }
    
    foreach ($unusedImport in $unusedMap[$FileName]) {
        $pattern = "^import\s+['\`"].*$([regex]::Escape($unusedImport))['\`"];?\s*$"
        $matches = [regex]::Matches($Content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
        if ($matches.Count -gt 0) {
            $Content = $Content -replace $pattern, ''
            $Stats.ImportsRemoved += $matches.Count
        }
    }
    
    return $Content
}

function Fix-DartFile {
    param([string]$FilePath)
    
    try {
        $originalContent = Get-Content -Path $FilePath -Raw -Encoding UTF8
        $content = $originalContent
        
        $fileName = Split-Path -Leaf $FilePath
        
        # Apply fixes in order
        $content = Fix-PrintStatements -Content $content -FilePath $FilePath
        $content = Fix-WithOpacity -Content $content
        $content = Fix-FormValueParameter -Content $content
        $content = Add-LibraryDirective -Content $content -FileName $fileName
        $content = Remove-UnusedImports -Content $content -FileName $fileName
        
        # Only write if changed
        if ($content -ne $originalContent) {
            Set-Content -Path $FilePath -Value $content -Encoding UTF8 -NoNewline
            $Stats.FilesProcessed++
            $relativePath = Resolve-Path -Relative $FilePath
            Write-Host "✅ Fixed: $relativePath" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "❌ Error fixing $FilePath : $_" -ForegroundColor Red
    }
}

# Main execution
Write-Header

$libDir = Join-Path $ProjectRoot "lib"

if (-not (Test-Path $libDir)) {
    Write-Host "❌ Error: lib directory not found at $libDir" -ForegroundColor Red
    Write-Host "Please run this script from the SafeStride project root directory." -ForegroundColor Yellow
    exit 1
}

$dartFiles = Get-ChildItem -Path $libDir -Filter "*.dart" -Recurse
Write-Host "Found $($dartFiles.Count) Dart files" -ForegroundColor Cyan
Write-Host ""

foreach ($file in $dartFiles) {
    Fix-DartFile -FilePath $file.FullName
}

Write-Summary
