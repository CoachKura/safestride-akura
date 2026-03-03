# 🚀 Deploy SafeStride to GitHub Pages

## Current Status
- **Repository**: https://github.com/CoachKura/safestride-akura
- **Branch**: production (34 commits ahead)
- **New Files**: athlete-dashboard, training-calendar, evaluation form, migration scripts

## 📋 Quick Deploy Steps

### Step 1: Commit Your Changes
```bash
cd /home/user/webapp
git add .
git commit -m "Add modern SafeStride platform: dashboards, calendar, evaluation form"
```

### Step 2: Push to GitHub
```bash
git push origin production
```

### Step 3: Enable GitHub Pages
1. Go to https://github.com/CoachKura/safestride-akura/settings/pages
2. Under "Build and deployment":
   - **Source**: Deploy from a branch
   - **Branch**: `production`
   - **Folder**: `/public` (or `/ (root)` if public folder doesn't work)
3. Click **Save**
4. Wait 2-3 minutes for deployment

### Step 4: Access Your Site
Your site will be available at:
- **Primary URL**: https://coachkura.github.io/safestride-akura/
- **Custom domain** (if configured): www.akura.in

## 🌐 Connect Custom Domain (www.akura.in)

### GitHub Side:
1. Go to repository Settings → Pages
2. Under "Custom domain", enter: `www.akura.in`
3. Check "Enforce HTTPS"
4. Click Save

### DNS Side (Your Domain Provider):
Add these DNS records:

**For apex domain (akura.in):**
```
Type: A
Name: @
Value: 185.199.108.153
       185.199.109.153
       185.199.110.153
       185.199.111.153
```

**For www subdomain:**
```
Type: CNAME
Name: www
Value: coachkura.github.io
```

## ⚡ Alternative: Deploy to Cloudflare Pages (Faster + Free)

### Why Cloudflare Pages?
- ✅ Faster global CDN
- ✅ Unlimited bandwidth
- ✅ Better analytics
- ✅ Easier custom domain setup
- ✅ No repository size limits

### Cloudflare Pages Setup:
1. Visit https://dash.cloudflare.com/login
2. Go to **Workers & Pages** → **Create Application** → **Pages** → **Connect to Git**
3. Select GitHub → Authorize → Choose `safestride-akura`
4. Configure build:
   - **Project name**: safestride
   - **Production branch**: production
   - **Build command**: (leave empty)
   - **Build output directory**: `/public`
5. Click **Save and Deploy**
6. Done! Your site will be live at: `https://safestride.pages.dev`

### Add Custom Domain to Cloudflare:
1. In your Cloudflare Pages project → Settings → Domains → Add domain
2. Enter: `www.akura.in`
3. Cloudflare will automatically configure DNS if domain is in Cloudflare
4. If not, add CNAME:
   ```
   Type: CNAME
   Name: www
   Value: safestride.pages.dev
   ```

## 🔧 Troubleshooting

### Files Not Showing Up
If you set GitHub Pages root to `/`, your URLs will be:
- https://coachkura.github.io/safestride-akura/public/athlete-dashboard.html

If you set it to `/public`, URLs will be:
- https://coachkura.github.io/safestride-akura/athlete-dashboard.html

**Fix**: Update all links in your HTML files to match the selected folder.

### 404 Errors
1. Ensure `index.html` exists in the selected folder
2. Check that all file paths are relative or absolute from the selected folder
3. GitHub Pages is case-sensitive: `Dashboard.html` ≠ `dashboard.html`

### Supabase Connection Issues
Your Supabase credentials in the HTML files should work fine since they're client-side. But verify:
1. Supabase project is active
2. Row Level Security (RLS) policies allow public access where needed
3. CORS is enabled for your GitHub Pages domain

## 📦 What You're Deploying

### New Pages:
- ✅ `/public/athlete-dashboard.html` - Modern dashboard with AISRI score
- ✅ `/public/training-calendar.html` - 12-week training plan view
- ✅ `/public/athlete-evaluation.html` - 6-pillar assessment form
- ✅ `/public/generate-training-plan-ui.html` - Sample data generator
- ✅ `/public/home.html` - Landing page
- ✅ `/public/onboarding.html` - 4-step onboarding wizard

### Backend:
- ✅ Supabase database (already deployed)
- ✅ 8 new tables, 3 views, 2 functions
- ✅ Migration scripts ready

### Documentation:
- ✅ NAVIGATION_FLOW.md - Page connections
- ✅ TESTING_GUIDE.md - How to test features
- ✅ COMPLETE_PROJECT_STATUS.md - Project status

## 🎯 Recommended Deployment Path

**For Immediate Deployment** (5 minutes):
1. Run the git commands above (Step 1-2)
2. Use **Cloudflare Pages** (easier, faster, better)
3. Connect domain `www.akura.in`
4. Done! ✅

**Why Not GitHub Pages?**
- Slower global CDN
- Path complexity with `/public` folder
- More DNS configuration steps
- No built-in analytics

## 📞 Need Help?

If you encounter any issues:
1. Check git push output for errors
2. Verify Supabase credentials in HTML files
3. Test locally first: `python -m http.server 8000` then visit `http://localhost:8000/public/`
4. Check browser console for JavaScript errors

## ✅ Post-Deployment Checklist

After deployment:
- [ ] Visit your live URL
- [ ] Test signup/login flow
- [ ] Generate sample training data
- [ ] View athlete dashboard
- [ ] Check training calendar
- [ ] Complete evaluation form
- [ ] Verify Supabase data is saved
- [ ] Test on mobile device
- [ ] Check all links work

---

**Quick Command Reference:**
```bash
# Commit and push
git add .
git commit -m "Deploy SafeStride modern platform"
git push origin production

# Check remote
git remote -v

# View commit history
git log --oneline -10

# Check what will be pushed
git diff origin/production
```

**Your repository**: https://github.com/CoachKura/safestride-akura
**Ready to deploy**: ✅ Yes! All files are committed locally, just need to push.
