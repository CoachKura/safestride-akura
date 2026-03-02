#!/bin/bash

# Quick Action Script - Deploy AISRi Today
# Run this after fixing the 3 blockers manually

echo "🚀 AISRi Quick Deploy Script"
echo "================================"
echo ""

# Check current directory
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in git repository"
    echo "   Run: cd /home/user/webapp"
    exit 1
fi

echo "📦 Current directory: $(pwd)"
echo "📊 Git status:"
git status --short

echo ""
echo "🔍 Checking config.js..."
if grep -q "your-project.supabase.co" public/config.js; then
    echo "⚠️  WARNING: config.js still has placeholder URLs!"
    echo "   Please update with real Supabase URL and anon key"
    echo "   Get key from: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/settings/api"
    exit 1
else
    echo "✅ Config.js looks updated"
fi

echo ""
echo "📝 Committing changes..."
git add -A
git commit -m "Deploy: Fix config.js, update documentation" || echo "No changes to commit"

echo ""
echo "🔐 Checking GitHub authentication..."
if git remote -v | grep -q "github.com"; then
    echo "✅ GitHub remote configured"
else
    echo "❌ GitHub remote not configured"
    exit 1
fi

echo ""
echo "🚀 Ready to push to GitHub?"
echo "   This will trigger Vercel deployment"
echo ""
read -p "Push now? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📤 Pushing to GitHub..."
    git push origin production
    
    echo ""
    echo "✅ DEPLOYMENT INITIATED!"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Monitor Vercel deployment: https://vercel.com/dashboard"
    echo "2. Test OAuth flow: https://www.akura.in/training-plan-builder.html"
    echo "3. Check Edge Function logs: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/logs"
    echo ""
    echo "🎯 Verification URLs:"
    echo "   - Homepage: https://www.akura.in"
    echo "   - Login: https://www.akura.in/public/login.html"
    echo "   - Dashboard: https://www.akura.in/public/strava-dashboard.html"
    echo ""
else
    echo "❌ Deployment cancelled"
    echo "   Run this script again when ready"
fi
