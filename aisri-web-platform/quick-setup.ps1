# AISRi Web Platform - Quick Setup Script
# Run this to automate the setup process

Write-Host "`n╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   🚀 AISRi Web Platform - Quick Setup              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Check if Node.js is installed
Write-Host "📦 Checking prerequisites..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js installed: $nodeVersion" -ForegroundColor Green
}
catch {
    Write-Host "❌ Node.js not found! Please install Node.js 18+ first." -ForegroundColor Red
    Write-Host "   Download from: https://nodejs.org" -ForegroundColor Yellow
    exit 1
}

# Navigate to project directory
$projectPath = "c:\safestride\aisri-web-platform"
if (Test-Path $projectPath) {
    Set-Location $projectPath
    Write-Host "✅ Project directory found" -ForegroundColor Green
}
else {
    Write-Host "❌ Project directory not found at: $projectPath" -ForegroundColor Red
    exit 1
}

# Install dependencies
Write-Host "`n📦 Installing dependencies..." -ForegroundColor Yellow
npm install

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ npm install failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dependencies installed" -ForegroundColor Green

# Check for .env.local
Write-Host "`n🔐 Checking environment configuration..." -ForegroundColor Yellow
if (Test-Path ".env.local") {
    Write-Host "✅ .env.local file exists" -ForegroundColor Green
}
else {
    Write-Host "⚠️  .env.local not found" -ForegroundColor Yellow
    Write-Host "   Creating from example..." -ForegroundColor Gray
    
    if (Test-Path ".env.local.example") {
        Copy-Item ".env.local.example" ".env.local"
        Write-Host "✅ Created .env.local" -ForegroundColor Green
        Write-Host "⚠️  ACTION REQUIRED: Edit .env.local with your Supabase keys" -ForegroundColor Yellow
        Write-Host "   Get keys from: https://app.supabase.com/project/bdisppaxbvygsspcuymb/settings/api" -ForegroundColor Gray
    }
    else {
        Write-Host "❌ .env.local.example not found!" -ForegroundColor Red
        exit 1
    }
}

# Summary
Write-Host "`n╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅ Setup Complete!                                 ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1️⃣  Edit .env.local with your Supabase keys" -ForegroundColor White
Write-Host "   - Get keys from: https://app.supabase.com/project/bdisppaxbvygsspcuymb/settings/api" -ForegroundColor Gray
Write-Host ""
Write-Host "2️⃣  Run database migration" -ForegroundColor White
Write-Host "   - Open: https://app.supabase.com/project/bdisppaxbvygsspcuymb/sql" -ForegroundColor Gray
Write-Host "   - Copy & run: database/migrations/01_evaluation_responses.sql" -ForegroundColor Gray
Write-Host ""
Write-Host "3️⃣  Install shadcn/ui components (optional)" -ForegroundColor White
Write-Host "   - Run: npx shadcn-ui@latest init" -ForegroundColor Gray
Write-Host "   - Then: npx shadcn-ui@latest add button card form input" -ForegroundColor Gray
Write-Host ""
Write-Host "4️⃣  Start development server" -ForegroundColor White
Write-Host "   - Run: npm run dev" -ForegroundColor Gray
Write-Host "   - Open: http://localhost:3000" -ForegroundColor Gray
Write-Host ""
Write-Host "📖 Full guide: See SETUP_GUIDE.md" -ForegroundColor Cyan
Write-Host ""
