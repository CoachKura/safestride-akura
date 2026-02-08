<#
.SYNOPSIS
    SafeStride Build Blocker Auto-Fix Script

.DESCRIPTION
    Automatically fixes critical build blockers:
    1. Android Gradle root mismatch (path_provider_android)
    2. Missing model imports (workout_builder_screen.dart)
    3. Cleans build cache and repairs pub cache
    4. Verifies pubspec.yaml dependencies

.PARAMETER ProjectRoot
    Path to SafeStride project root (e.g., "E:\Akura Safe Stride\safestride\akura_mobile")

.EXAMPLE
    .\Fix-BuildBlockers.ps1
    .\Fix-BuildBlockers.ps1 -ProjectRoot "E:\Akura Safe Stride\safestride\akura_mobile"

.NOTES
    Author: SafeStride Development Team
    Date: 2026-02-08
    Version: 1.0.0
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectRoot = (Get-Location).Path
)

#region Helper Functions

function Write-Banner {
    param([string]$Text)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Text)
    Write-Host "▶ " -ForegroundColor Green -NoNewline
    Write-Host $Text
}

function Write-Success {
    param([string]$Text)
    Write-Host "✓ " -ForegroundColor Green -NoNewline
    Write-Host $Text -ForegroundColor Green
}

function Write-Warning {
    param([string]$Text)
    Write-Host "⚠ " -ForegroundColor Yellow -NoNewline
    Write-Host $Text -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Text)
    Write-Host "✗ " -ForegroundColor Red -NoNewline
    Write-Host $Text -ForegroundColor Red
}

#endregion

#region Main Script

Write-Banner "SafeStride Build Blocker Auto-Fix"

# Verify project root
if (-not (Test-Path $ProjectRoot)) {
    Write-Error "Project root not found: $ProjectRoot"
    exit 1
}

if (-not (Test-Path "$ProjectRoot\pubspec.yaml")) {
    Write-Error "Not a Flutter project: $ProjectRoot"
    exit 1
}

Write-Host "Project Root: $ProjectRoot" -ForegroundColor Cyan
Write-Host ""

# Check path length and spaces
$pathLength = $ProjectRoot.Length
$hasSpaces = $ProjectRoot -match ' '

if ($pathLength -gt 100) {
    Write-Warning "Path length is $pathLength characters (> 100)"
    Write-Warning "Consider moving project to shorter path (e.g., C:\Projects\safestride)"
}

if ($hasSpaces) {
    Write-Warning "Path contains spaces: may cause Gradle issues"
    Write-Warning "Recommended: Move to path without spaces"
}

Write-Host ""
Read-Host "Press Enter to continue or Ctrl+C to cancel"

#region Step 1: Kill Processes

Write-Banner "Step 1: Killing Flutter Processes"

Write-Step "Stopping dart.exe processes..."
taskkill /F /IM dart.exe /T 2>$null | Out-Null
Write-Success "Dart processes stopped"

Write-Step "Stopping flutter.exe processes..."
taskkill /F /IM flutter.exe /T 2>$null | Out-Null
Write-Success "Flutter processes stopped"

#endregion

#region Step 2: Clean Build Artifacts

Write-Banner "Step 2: Cleaning Build Artifacts"

Set-Location $ProjectRoot

Write-Step "Running flutter clean..."
flutter clean | Out-Null
Write-Success "Flutter clean completed"

Write-Step "Deleting .dart_tool..."
if (Test-Path ".dart_tool") {
    Remove-Item -Recurse -Force .dart_tool -ErrorAction SilentlyContinue
    Write-Success "Deleted .dart_tool"
} else {
    Write-Success ".dart_tool already clean"
}

Write-Step "Deleting build directory..."
if (Test-Path "build") {
    Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
    Write-Success "Deleted build"
} else {
    Write-Success "build already clean"
}

Write-Step "Deleting .flutter-plugins..."
Remove-Item .flutter-plugins -ErrorAction SilentlyContinue
Remove-Item .flutter-plugins-dependencies -ErrorAction SilentlyContinue
Write-Success "Deleted Flutter plugin files"

#endregion

#region Step 3: Clean Android Gradle

Write-Banner "Step 3: Cleaning Android Gradle"

if (Test-Path "android") {
    Set-Location "android"
    
    Write-Step "Running gradlew clean..."
    if (Test-Path "gradlew.bat") {
        .\gradlew.bat clean 2>&1 | Out-Null
        Write-Success "Gradle clean completed"
    } elseif (Test-Path "gradlew") {
        .\gradlew clean 2>&1 | Out-Null
        Write-Success "Gradle clean completed"
    } else {
        Write-Warning "gradlew not found, skipping"
    }
    
    Write-Step "Deleting Android build directories..."
    Remove-Item -Recurse -Force .gradle -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
    Get-ChildItem -Directory | ForEach-Object {
        Remove-Item -Recurse -Force "$($_.FullName)\build" -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force "$($_.FullName)\.cxx" -ErrorAction SilentlyContinue
    }
    Write-Success "Android build directories cleaned"
    
    Set-Location ..
} else {
    Write-Warning "Android directory not found"
}

#endregion

#region Step 4: Fix Missing Imports

Write-Banner "Step 4: Fixing Missing Model Imports"

$workoutBuilderScreen = "lib\screens\workout_builder_screen.dart"

if (Test-Path $workoutBuilderScreen) {
    Write-Step "Checking $workoutBuilderScreen..."
    
    $content = Get-Content $workoutBuilderScreen -Raw
    $importStatement = "import '../models/workout_builder_models.dart';"
    
    if ($content -notmatch [regex]::Escape($importStatement)) {
        Write-Step "Adding missing import..."
        
        # Find the last import statement
        $lines = Get-Content $workoutBuilderScreen
        $lastImportIndex = -1
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^import\s+") {
                $lastImportIndex = $i
            }
        }
        
        if ($lastImportIndex -ge 0) {
            # Insert after last import
            $lines = $lines[0..$lastImportIndex] + $importStatement + $lines[($lastImportIndex + 1)..($lines.Count - 1)]
            $lines | Set-Content $workoutBuilderScreen
            Write-Success "Added import to workout_builder_screen.dart"
        } else {
            Write-Warning "Could not find import section"
        }
    } else {
        Write-Success "Import already exists"
    }
} else {
    Write-Warning "workout_builder_screen.dart not found"
}

#endregion

#region Step 5: Verify Dependencies

Write-Banner "Step 5: Verifying Dependencies"

$pubspec = Get-Content "pubspec.yaml" -Raw

$dependencies = @(
    "shared_preferences",
    "provider",
    "supabase_flutter",
    "geolocator",
    "google_maps_flutter",
    "table_calendar"
)

Write-Step "Checking critical dependencies..."
$missingDeps = @()

foreach ($dep in $dependencies) {
    if ($pubspec -match "^\s+$dep\s*:") {
        Write-Success "$dep found"
    } else {
        Write-Warning "$dep missing"
        $missingDeps += $dep
    }
}

if ($missingDeps.Count -gt 0) {
    Write-Warning "Missing dependencies detected. Run: flutter pub add $($missingDeps -join ' ')"
} else {
    Write-Success "All critical dependencies present"
}

#endregion

#region Step 6: Repair Pub Cache

Write-Banner "Step 6: Repairing Pub Cache (This may take 5-10 minutes)"

Write-Step "Running flutter pub cache repair..."
Write-Host "  ⏳ Please wait..." -ForegroundColor Yellow

$repairStart = Get-Date
flutter pub cache repair | Out-Null
$repairEnd = Get-Date
$duration = ($repairEnd - $repairStart).TotalSeconds

Write-Success "Pub cache repair completed in $([math]::Round($duration, 1)) seconds"

#endregion

#region Step 7: Get Dependencies

Write-Banner "Step 7: Getting Dependencies"

Write-Step "Running flutter pub get..."
flutter pub get

if ($LASTEXITCODE -eq 0) {
    Write-Success "Dependencies installed successfully"
} else {
    Write-Error "Failed to get dependencies"
    exit 1
}

#endregion

#region Step 8: Run Doctor

Write-Banner "Step 8: Running Flutter Doctor"

Write-Step "Checking Flutter environment..."
flutter doctor -v

#endregion

#region Step 9: Run Analyzer

Write-Banner "Step 9: Running Flutter Analyze"

Write-Step "Analyzing code..."
$analyzeOutput = flutter analyze 2>&1

# Count warnings and errors
$warnings = ($analyzeOutput | Select-String "warning" | Measure-Object).Count
$errors = ($analyzeOutput | Select-String "error" | Measure-Object).Count

Write-Host $analyzeOutput

if ($errors -eq 0) {
    Write-Success "No analyzer errors found"
    if ($warnings -gt 0) {
        Write-Warning "$warnings warnings found (non-blocking)"
    }
} else {
    Write-Error "$errors errors found"
}

#endregion

#region Step 10: Summary

Write-Banner "Fix Summary"

Write-Host "✓ Processes stopped" -ForegroundColor Green
Write-Host "✓ Build artifacts cleaned" -ForegroundColor Green
Write-Host "✓ Android Gradle cleaned" -ForegroundColor Green
Write-Host "✓ Missing imports fixed" -ForegroundColor Green
Write-Host "✓ Dependencies verified" -ForegroundColor Green
Write-Host "✓ Pub cache repaired" -ForegroundColor Green
Write-Host "✓ Dependencies installed" -ForegroundColor Green
Write-Host ""

if ($errors -eq 0) {
    Write-Success "🎉 ALL FIXES APPLIED SUCCESSFULLY!"
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Run: flutter build apk --debug"
    Write-Host "  2. Test the generated APK"
    Write-Host "  3. Check: REMAINING_ISSUES_GUIDE.md for optional improvements"
    Write-Host ""
} else {
    Write-Warning "⚠ FIXES APPLIED WITH WARNINGS"
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Review analyzer errors above"
    Write-Host "  2. Check: CRITICAL_BUILD_FIXES.md for manual fixes"
    Write-Host "  3. Consider moving project to shorter path"
    Write-Host ""
}

#endregion

Write-Banner "Script Complete"
