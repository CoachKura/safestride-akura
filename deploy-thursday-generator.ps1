# Quick deploy Thursday Workout Generator to GitHub Pages
# For Coach Kura - Windows PowerShell Version

Write-Host "🚀 Deploying Thursday Workout Generator..." -ForegroundColor Cyan

# Create temporary deployment directory
$deployPath = "$env:TEMP\thursday-workouts"
if (Test-Path $deployPath) {
    Remove-Item $deployPath -Recurse -Force
}
New-Item -ItemType Directory -Path $deployPath | Out-Null
Set-Location $deployPath

Write-Host "📁 Created deployment directory: $deployPath" -ForegroundColor Green

# Copy the HTML file
$sourcePath = "$PSScriptRoot\thursday-workout-generator.html"
Copy-Item $sourcePath -Destination "$deployPath\index.html"
Write-Host "✅ Copied HTML file as index.html" -ForegroundColor Green

# Initialize git
git init
git branch -M main

# Create README
@"
# Thursday Workout Generator - AKURA AISRI

Instant workout generator for all athletes based on 6-pillar AISRI scores.

## Access
Open ``index.html`` in any browser (works offline)

## Features
- Auto-calculates AISRI score
- Generates personalized workouts
- Print-ready format
- No internet required

Created by Coach Kura | AKURA System
"@ | Out-File -FilePath "$deployPath\README.md" -Encoding UTF8

Write-Host "✅ Created README.md" -ForegroundColor Green

# Commit
git add .
git commit -m "Deploy Thursday Workout Generator"

Write-Host ""
Write-Host "✅ Git repository created at: $deployPath" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Create a new GitHub repository (e.g., thursday-workouts)" -ForegroundColor White
Write-Host "2. Run these commands in PowerShell:" -ForegroundColor White
Write-Host ""
Write-Host "   cd $deployPath" -ForegroundColor Cyan
Write-Host "   git remote add origin https://github.com/CoachKura/thursday-workouts.git" -ForegroundColor Cyan
Write-Host "   git push -u origin main" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Enable GitHub Pages:" -ForegroundColor White
Write-Host "   - Go to Settings → Pages" -ForegroundColor Gray
Write-Host "   - Source: Deploy from branch 'main'" -ForegroundColor Gray
Write-Host "   - Folder: / (root)" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Access your generator at:" -ForegroundColor White
Write-Host "   https://CoachKura.github.io/thursday-workouts" -ForegroundColor Green
Write-Host ""
Write-Host "⏱️ Total time: ~5 minutes" -ForegroundColor Yellow
Write-Host ""
Write-Host "💡 Tip: The deployment folder will remain at $deployPath" -ForegroundColor Cyan
Write-Host "    You can return there anytime to update and push changes." -ForegroundColor Cyan
