# ==============================================
# SAFESTRIDE - FINAL DEPLOYMENT SCRIPT
# Launch Date: January 27, 2026
# ==============================================

Write-Host "`n🚀 SafeStride by AKURA - Final Deployment" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Commit deployment files
Write-Host "📝 Step 1: Committing deployment files..." -ForegroundColor Yellow
cd "E:\Akura Safe Stride\safestride"
git add .
git commit -m "Add deployment files and pre-launch checklist for January 27 launch"
git push origin main
Write-Host "✅ Deployment files committed to GitHub`n" -ForegroundColor Green

# Step 2: Backend health check
Write-Host "🏥 Step 2: Checking backend health..." -ForegroundColor Yellow
$backendUrl = "https://safestride-backend-cave.onrender.com/api/health"
try {
    $response = Invoke-WebRequest -Uri $backendUrl -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    Write-Host "✅ Backend Status: $($data.status)" -ForegroundColor Green
    Write-Host "   Service: $($data.service)" -ForegroundColor Gray
    Write-Host "   Version: $($data.version)`n" -ForegroundColor Gray
} catch {
    Write-Host "❌ Backend health check failed!" -ForegroundColor Red
    Write-Host "   Error: $_`n" -ForegroundColor Red
    exit 1
}

# Step 3: Run integration tests
Write-Host "🧪 Step 3: Running integration tests..." -ForegroundColor Yellow
Write-Host "   Opening test page in browser..." -ForegroundColor Gray
Start-Process "E:\Akura Safe Stride\safestride\frontend\test-integration.html"
Write-Host "   ⏳ Please review test results in browser`n" -ForegroundColor Yellow

# Step 4: Deployment instructions
Write-Host "📦 Step 4: Ready to deploy frontend!" -ForegroundColor Yellow
Write-Host "`n=== DEPLOYMENT OPTIONS ===" -ForegroundColor Cyan

Write-Host "`n🎯 OPTION 1: Render Dashboard (Recommended)" -ForegroundColor White
Write-Host "   1. Open: https://dashboard.render.com" -ForegroundColor Gray
Write-Host "   2. Click: New + → Static Site" -ForegroundColor Gray
Write-Host "   3. Repo: CoachKura/safestride-akura" -ForegroundColor Gray
Write-Host "   4. Root Directory: frontend" -ForegroundColor Gray
Write-Host "   5. Build Command: (leave empty)" -ForegroundColor Gray
Write-Host "   6. Publish Directory: ." -ForegroundColor Gray
Write-Host "   7. Click: Create Static Site`n" -ForegroundColor Gray

Write-Host "🎯 OPTION 2: Vercel CLI" -ForegroundColor White
Write-Host "   Run these commands:" -ForegroundColor Gray
Write-Host "   cd `"E:\Akura Safe Stride\safestride\frontend`"" -ForegroundColor Cyan
Write-Host "   vercel --name safestride_frontend --prod`n" -ForegroundColor Cyan

# Step 5: Post-deployment checklist
Write-Host "📋 Step 5: Post-Deployment Checklist" -ForegroundColor Yellow
Write-Host "   [ ] Verify frontend URL works" -ForegroundColor White
Write-Host "   [ ] Test login/signup flow" -ForegroundColor White
Write-Host "   [ ] Update Strava OAuth redirect URI" -ForegroundColor White
Write-Host "   [ ] Test on mobile device" -ForegroundColor White
Write-Host "   [ ] Run Lighthouse audit" -ForegroundColor White
Write-Host "   [ ] Send invites to 10 Chennai athletes`n" -ForegroundColor White

# Step 6: Documentation
Write-Host "📚 Step 6: Documentation Created" -ForegroundColor Yellow
Write-Host "   ✅ FINAL_DEPLOYMENT_PLAN.md" -ForegroundColor Green
Write-Host "   ✅ PRE_LAUNCH_CHECKLIST.md" -ForegroundColor Green
Write-Host "   ✅ frontend/DEPLOYMENT_INSTRUCTIONS.md" -ForegroundColor Green
Write-Host "   ✅ frontend/render.yaml" -ForegroundColor Green
Write-Host "   ✅ frontend/test-integration.html`n" -ForegroundColor Green

# Summary
Write-Host "🎉 DEPLOYMENT READY!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Backend: ✅ LIVE" -ForegroundColor Green
Write-Host "Frontend: ⏳ READY TO DEPLOY" -ForegroundColor Yellow
Write-Host "Launch: January 27, 2026 (48 hours)" -ForegroundColor Cyan
Write-Host "`nNext: Deploy frontend using Option 1 or 2 above" -ForegroundColor White
Write-Host "Time Estimate: 5-10 minutes`n" -ForegroundColor Gray

# Open key documents
Write-Host "📖 Opening key documents..." -ForegroundColor Yellow
Start-Process "E:\Akura Safe Stride\safestride\FINAL_DEPLOYMENT_PLAN.md"
Start-Process "E:\Akura Safe Stride\safestride\PRE_LAUNCH_CHECKLIST.md"
Start-Process "E:\Akura Safe Stride\safestride\frontend\DEPLOYMENT_INSTRUCTIONS.md"

Write-Host "`nGood luck with the launch!" -ForegroundColor Cyan
