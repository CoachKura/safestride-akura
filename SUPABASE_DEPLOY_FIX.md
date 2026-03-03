# 🚀 SUPABASE EDGE FUNCTIONS - DEPLOYMENT FIX

## ⚠️ PROBLEM
- Supabase Dashboard showing 404 errors
- Cannot access Functions page
- Edge Functions not deployed = 401 OAuth errors

## ✅ SOLUTION: Deploy via Supabase CLI

---

## 📋 STEP-BY-STEP DEPLOYMENT (10 minutes)

### **Step 1: Install Supabase CLI** (if not installed)

Open VS Code terminal and run:

```powershell
# Install via npm (recommended)
npm install -g supabase

# OR via Scoop (if you use Scoop)
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

Verify installation:
```powershell
supabase --version
```

---

### **Step 2: Login to Supabase**

```powershell
supabase login
```

This will:
1. Open your browser
2. Ask you to authorize the CLI
3. Save your credentials

---

### **Step 3: Link Your Project**

```powershell
cd C:\safestride

# Link to your Supabase project
supabase link --project-ref bdisppaxbvygsspcuymb
```

**If asked for database password:**
- Go to: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/settings/database
- Copy the database password
- Paste it when prompted

---

### **Step 4: Deploy All Three Functions**

```powershell
# Deploy strava-oauth
supabase functions deploy strava-oauth

# Deploy strava-sync-activities
supabase functions deploy strava-sync-activities

# Deploy strava-refresh-token (NEW)
supabase functions deploy strava-refresh-token
```

Expected output for each:
```
✓ Deployed function strava-oauth
✓ Function URL: https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/strava-oauth
```

---

### **Step 5: Set Environment Secrets**

```powershell
# Set Strava Client ID
supabase secrets set STRAVA_CLIENT_ID=162971 --project-ref bdisppaxbvygsspcuymb

# Set Strava Client Secret
supabase secrets set STRAVA_CLIENT_SECRET=ca2a2ef68680c324e0ba4db3ed6e6006a9dc7626 --project-ref bdisppaxbvygsspcuymb
```

Expected output:
```
✓ Set secret STRAVA_CLIENT_ID
✓ Set secret STRAVA_CLIENT_SECRET
```

---

### **Step 6: Verify Deployment**

```powershell
# List all deployed functions
supabase functions list --project-ref bdisppaxbvygsspcuymb

# List all secrets
supabase secrets list --project-ref bdisppaxbvygsspcuymb
```

You should see:
```
Functions:
  - strava-oauth
  - strava-sync-activities
  - strava-refresh-token

Secrets:
  - STRAVA_CLIENT_ID
  - STRAVA_CLIENT_SECRET
```

---

## 🧪 TEST YOUR DEPLOYMENT

### **Test 1: Edge Function Health Check**

```powershell
# Test strava-oauth endpoint
Invoke-RestMethod -Uri "https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/strava-oauth" -Method OPTIONS

# Should return: ok (with CORS headers)
```

### **Test 2: Web Application**

1. Open: https://www.akura.in/training-plan-builder.html
2. Open DevTools Console (F12)
3. Click "Connect Strava"
4. Authorize on Strava
5. Check console for:
   - ✅ "OAuth exchange successful"
   - ✅ "Found existing Strava connection"
   - ✅ "Loaded 908 activities from database"
   - ❌ NO 401 errors

---

## 🔧 TROUBLESHOOTING

### **Error: "supabase: command not found"**
```powershell
# Install via npm
npm install -g supabase

# Verify
supabase --version
```

### **Error: "Project not linked"**
```powershell
cd C:\safestride
supabase link --project-ref bdisppaxbvygsspcuymb
```

### **Error: "Database password required"**
1. Go to: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/settings/database
2. Copy the password
3. Run: `supabase link --project-ref bdisppaxbvygsspcuymb`
4. Paste password when prompted

### **Error: "Function already exists"**
```powershell
# Force redeploy
supabase functions deploy strava-oauth --no-verify-jwt
```

### **Error: "Secrets not found in function"**
After setting secrets, you MUST redeploy functions:
```powershell
supabase functions deploy strava-oauth
supabase functions deploy strava-sync-activities
supabase functions deploy strava-refresh-token
```

---

## 📊 QUICK DEPLOYMENT SCRIPT

Copy and paste this entire block into VS Code terminal:

```powershell
# Navigate to project
cd C:\safestride

# Deploy all three functions
Write-Host "🚀 Deploying Edge Functions..." -ForegroundColor Cyan
supabase functions deploy strava-oauth
supabase functions deploy strava-sync-activities
supabase functions deploy strava-refresh-token

# Set secrets
Write-Host "🔐 Setting environment secrets..." -ForegroundColor Cyan
supabase secrets set STRAVA_CLIENT_ID=162971 --project-ref bdisppaxbvygsspcuymb
supabase secrets set STRAVA_CLIENT_SECRET=ca2a2ef68680c324e0ba4db3ed6e6006a9dc7626 --project-ref bdisppaxbvygsspcuymb

# Verify
Write-Host "✅ Verifying deployment..." -ForegroundColor Green
supabase functions list --project-ref bdisppaxbvygsspcuymb
supabase secrets list --project-ref bdisppaxbvygsspcuymb

Write-Host ""
Write-Host "✅ DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "Test at: https://www.akura.in/training-plan-builder.html" -ForegroundColor Yellow
```

---

## 🎯 EXPECTED RESULTS

### **Before Deployment:**
- ❌ 401 Unauthorized errors
- ❌ OAuth fails with "redirect_uri invalid"
- ❌ Dashboard requires reconnection every login

### **After Deployment:**
- ✅ OAuth completes successfully
- ✅ Green "Strava Connected ✓" button
- ✅ 908 activities auto-loaded
- ✅ No reconnection required after logout/login
- ✅ Token auto-refreshes every 6 hours

---

## 📞 NEXT STEPS

**Reply with ONE of these:**

**A.** "CLI installed, ready to deploy"
**B.** "Deployed! Testing now..."
**C.** "Functions deployed but getting error: [paste error]"
**D.** "Need help with step X"
**E.** "All working! 🎉"

---

## 🔗 USEFUL LINKS

- **Supabase Dashboard:** https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb
- **Edge Functions:** https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/functions
- **Database Password:** https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/settings/database
- **Supabase CLI Docs:** https://supabase.com/docs/guides/cli
- **Your Website:** https://www.akura.in/training-plan-builder.html

---

**Deployment time: ~10 minutes total** ⏱️
