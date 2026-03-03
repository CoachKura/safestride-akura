# 🚀 SafeStride Deployment Guide

## 📋 **What You're Deploying**

**Project**: SafeStride Athlete Management Platform
**Type**: Static HTML/CSS/JavaScript website
**Files**: 22 HTML pages + CSS + JavaScript
**Database**: Supabase (already configured)
**Domain Goal**: www.akura.in or safestride.akura.in

---

## ✅ **Pre-Deployment Checklist**

Before deploying, verify these are set:

### **1. Supabase Configuration**
- ✅ Database migrated (8 tables, 3 views, 2 functions)
- ✅ Anon key configured in files
- ⚠️ **ACTION NEEDED**: Update Supabase URL in ALL HTML files

### **2. Files Ready**
- ✅ 22 HTML pages in `/public/` folder
- ✅ CSS files (safestride-design-system.css)
- ✅ JavaScript files
- ⚠️ **ACTION NEEDED**: Remove any test/demo files

### **3. Git Repository**
- ✅ Git initialized (.git folder exists)
- ⚠️ **ACTION NEEDED**: Commit all files
- ⚠️ **ACTION NEEDED**: Push to GitHub

---

## 🎯 **Deployment Method 1: Cloudflare Pages** ⭐ RECOMMENDED

### **Why Cloudflare Pages?**
- ✅ **FREE** unlimited sites
- ✅ **Fast** global CDN (180+ cities)
- ✅ **Simple** direct upload or Git integration
- ✅ **Custom domains** included
- ✅ **Automatic HTTPS**

### **Steps to Deploy:**

#### **Step 1: Get Cloudflare API Token**

1. Go to: https://dash.cloudflare.com/profile/api-tokens
2. Click "Create Token"
3. Use template: "Edit Cloudflare Workers"
4. Or create custom with permissions:
   - Account > Cloudflare Pages > Edit
   - User > User Details > Read
5. Click "Continue to summary" → "Create Token"
6. **SAVE THE TOKEN** (you'll need it once)

#### **Step 2: Deploy via Wrangler CLI**

Open terminal/command prompt:

```bash
# Install Wrangler (Cloudflare CLI)
npm install -g wrangler

# Login to Cloudflare
wrangler login

# Navigate to project
cd C:\safestride\web  # Your Windows path

# Deploy to Cloudflare Pages
wrangler pages deploy . --project-name safestride

# Or specify the public folder
wrangler pages deploy public --project-name safestride
```

#### **Step 3: Configure Custom Domain**

1. Go to Cloudflare Dashboard
2. Select your Pages project "safestride"
3. Go to "Custom domains"
4. Click "Set up a custom domain"
5. Enter: `www.akura.in` or `safestride.akura.in`
6. Follow DNS setup instructions

**Your site will be live at:**
- Default: `https://safestride.pages.dev`
- Custom: `https://www.akura.in` (after DNS setup)

---

## 🎯 **Deployment Method 2: Vercel** 

### **Why Vercel?**
- ✅ Also FREE
- ✅ Excellent performance
- ✅ Simple Git integration
- ✅ Good for static sites

### **Steps to Deploy:**

#### **Step 1: Install Vercel CLI**

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login
```

#### **Step 2: Deploy**

```bash
# Navigate to project
cd C:\safestride\web

# Deploy
vercel

# Follow prompts:
# - Set up and deploy? Yes
# - Which scope? Your account
# - Link to existing project? No
# - Project name? safestride
# - Directory? ./ (or ./public if files are there)
```

#### **Step 3: Production Deployment**

```bash
# Deploy to production
vercel --prod
```

**Your site will be live at:**
- Default: `https://safestride.vercel.app`
- Custom: Add domain in Vercel dashboard

---

## 🎯 **Deployment Method 3: GitHub Pages**

### **Steps:**

#### **Step 1: Push to GitHub**

```bash
cd C:\safestride\web

# Initialize git (if not done)
git init

# Add all files
git add .

# Commit
git commit -m "Initial deployment"

# Create GitHub repo and push
git remote add origin https://github.com/YOUR_USERNAME/safestride.git
git branch -M main
git push -u origin main
```

#### **Step 2: Enable GitHub Pages**

1. Go to your GitHub repo
2. Settings → Pages
3. Source: Deploy from branch
4. Branch: `main`, Folder: `/public` (or `/root`)
5. Save

**Your site will be live at:**
`https://YOUR_USERNAME.github.io/safestride/`

---

## 🔧 **Quick Deploy Script** (Windows PowerShell)

Save this as `deploy.ps1`:

```powershell
# SafeStride Quick Deploy Script

Write-Host "🚀 SafeStride Deployment Script" -ForegroundColor Cyan
Write-Host ""

# Check if in correct directory
if (!(Test-Path ".\public")) {
    Write-Host "❌ Error: public folder not found" -ForegroundColor Red
    Write-Host "Run this from C:\safestride\web\" -ForegroundColor Yellow
    exit
}

# Option menu
Write-Host "Select deployment method:" -ForegroundColor Yellow
Write-Host "1. Cloudflare Pages (Recommended)"
Write-Host "2. Vercel"
Write-Host "3. GitHub Pages"
Write-Host ""
$choice = Read-Host "Enter choice (1-3)"

switch ($choice) {
    "1" {
        Write-Host "📦 Deploying to Cloudflare Pages..." -ForegroundColor Green
        wrangler pages deploy public --project-name safestride
    }
    "2" {
        Write-Host "📦 Deploying to Vercel..." -ForegroundColor Green
        vercel --prod
    }
    "3" {
        Write-Host "📦 Pushing to GitHub..." -ForegroundColor Green
        git add .
        git commit -m "Deploy to GitHub Pages"
        git push origin main
        Write-Host "✅ Pushed! Now enable GitHub Pages in repo settings" -ForegroundColor Green
    }
    default {
        Write-Host "❌ Invalid choice" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "✅ Deployment initiated!" -ForegroundColor Green
```

**Run with:**
```powershell
cd C:\safestride\web
.\deploy.ps1
```

---

## 🔍 **After Deployment - Verify**

### **Checklist:**

1. ✅ **Site loads**: Open your deployment URL
2. ✅ **Pages work**: Test navigation between pages
3. ✅ **Supabase connects**: Login and check data loads
4. ✅ **Forms work**: Test training plan generator
5. ✅ **Images load**: Check all assets appear
6. ✅ **Mobile responsive**: Test on phone

### **Common Issues:**

**Issue 1: 404 on pages**
- Solution: Check file paths are correct
- Ensure all files uploaded

**Issue 2: Supabase connection fails**
- Solution: Verify anon key is correct
- Check CORS settings in Supabase

**Issue 3: Styles not loading**
- Solution: Check CSS file paths
- Ensure safestride-design-system.css deployed

---

## 📝 **Environment Variables** (If Using Cloudflare/Vercel)

For sensitive data, use environment variables:

### **Cloudflare Pages:**
```bash
# Set secrets
wrangler pages secret put SUPABASE_ANON_KEY
# Paste your key when prompted
```

### **Vercel:**
```bash
# Set environment variables
vercel env add SUPABASE_ANON_KEY
# Paste your key when prompted
```

Then update your JavaScript to use:
```javascript
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'fallback-key';
```

---

## 🎯 **Custom Domain Setup** (www.akura.in)

### **If domain is at Cloudflare:**

1. Go to Cloudflare Dashboard
2. Select your domain `akura.in`
3. DNS → Add records:
   ```
   Type: CNAME
   Name: www (or safestride)
   Target: safestride.pages.dev
   Proxy: Enabled (orange cloud)
   ```

4. Go to Pages project → Custom domains
5. Add `www.akura.in` or `safestride.akura.in`
6. Verify DNS records

### **If domain is elsewhere:**

1. Add CNAME record at your DNS provider:
   ```
   www → safestride.pages.dev
   ```
2. Wait for DNS propagation (up to 48 hours)
3. Add custom domain in Cloudflare/Vercel dashboard

---

## ✅ **Recommended: Cloudflare Pages**

**My suggestion:** Use Cloudflare Pages because:
- ✅ Easiest for static sites
- ✅ Best performance (CDN)
- ✅ Free SSL/HTTPS
- ✅ Great for your use case
- ✅ Easy custom domain setup

---

## 🚀 **Quick Start Command**

If you're ready RIGHT NOW:

```bash
# Install Wrangler
npm install -g wrangler

# Login
wrangler login

# Deploy
cd C:\safestride\web
wrangler pages deploy public --project-name safestride
```

**Done in 5 minutes!** 🎉

---

## 📞 **Need Help?**

**Issue with deployment?** Tell me:
1. Which method you chose (Cloudflare/Vercel/GitHub)
2. What error you got
3. At which step you're stuck

I'll help debug! 💪

---

**Status**: Ready to deploy ✅
**Recommendation**: Cloudflare Pages
**Time**: ~5-10 minutes
**Cost**: $0 (FREE)
