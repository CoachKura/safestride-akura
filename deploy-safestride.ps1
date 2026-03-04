# SafeStride Deployment Script
# Run this in PowerShell from your local Windows machine

Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          SafeStride Deployment Script                         ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the right directory
$currentPath = Get-Location
Write-Host "📂 Current directory: $currentPath" -ForegroundColor Yellow
Write-Host ""

# Ask user to confirm location
Write-Host "❓ Is this the correct safestride project directory?" -ForegroundColor Yellow
Write-Host "   Expected paths: C:\safestride\web or similar" -ForegroundColor Gray
Write-Host ""
$confirm = Read-Host "Continue? (Y/N)"

if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "❌ Deployment cancelled. Navigate to your project directory first." -ForegroundColor Red
    Write-Host "   Example: cd C:\safestride\web" -ForegroundColor Gray
    exit
}

Write-Host ""
Write-Host "🔍 Checking Git status..." -ForegroundColor Cyan
git status

Write-Host ""
Write-Host "📦 Adding all files..." -ForegroundColor Cyan
git add .

Write-Host ""
Write-Host "💾 Committing changes..." -ForegroundColor Cyan
git commit -m "Add modern SafeStride platform: athlete dashboard, training calendar, evaluation form, and migration scripts"

Write-Host ""
Write-Host "🚀 Pushing to GitHub..." -ForegroundColor Cyan
git push origin production

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                    ✅ PUSH SUCCESSFUL! ✅                      ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎯 NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "   1. Go to: https://github.com/CoachKura/safestride-akura/settings/pages" -ForegroundColor White
    Write-Host "   2. Set Source to: production branch, /public folder" -ForegroundColor White
    Write-Host "   3. Click Save" -ForegroundColor White
    Write-Host "   4. Wait 2-3 minutes" -ForegroundColor White
    Write-Host "   5. Visit: https://coachkura.github.io/safestride-akura/" -ForegroundColor White
    Write-Host ""
    Write-Host "📊 What was deployed:" -ForegroundColor Cyan
    Write-Host "   • Athlete Dashboard (with AISRI scoring)" -ForegroundColor Gray
    Write-Host "   • Training Calendar (12-week view)" -ForegroundColor Gray
    Write-Host "   • Athlete Evaluation Form (6 pillars)" -ForegroundColor Gray
    Write-Host "   • Sample Data Generator" -ForegroundColor Gray
    Write-Host "   • Home Page & Onboarding" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🎉 Congratulations! Your code is now on GitHub!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                     ❌ PUSH FAILED ❌                          ║" -ForegroundColor Red
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "   1. Check if you're logged in to GitHub" -ForegroundColor White
    Write-Host "      Test: git config user.name" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   2. Verify remote URL:" -ForegroundColor White
    Write-Host "      git remote -v" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   3. Try authenticating:" -ForegroundColor White
    Write-Host "      git push origin production" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   4. Or use a Personal Access Token:" -ForegroundColor White
    Write-Host "      https://github.com/settings/tokens/new" -ForegroundColor Gray
    Write-Host ""
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
