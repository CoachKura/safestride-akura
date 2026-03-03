# 🚨 CRITICAL DEPLOYMENT GUIDE - READ THIS FIRST

## 📌 **CURRENT STATUS**

### ✅ **What's DONE:**
- ✅ Code pushed to GitHub (commit `6ef99da`)
- ✅ Vercel deployment live at https://www.akura.in
- ✅ Strava session persistence code created
- ✅ All three Edge Function files ready:
  - `supabase/functions/strava-oauth/index.ts` ✅
  - `supabase/functions/strava-sync-activities/index.ts` ✅
  - `supabase/functions/strava-refresh-token/index.ts` ✅

### ❌ **What's BLOCKING:**
- ❌ **Supabase Dashboard showing 404 errors** (cannot deploy via web UI)
- ❌ **Edge Functions NOT deployed** (causing 401 OAuth errors)
- ❌ **Environment secrets NOT set** (functions need credentials)

---

## 🎯 **THE FIX: DEPLOY VIA CLI (10 MINUTES)**

### **OPTION 1: AUTOMATED DEPLOYMENT (FASTEST)** ⚡

**Copy and paste this ONE command into VS Code PowerShell terminal:**

```powershell
cd C:\safestride && .\deploy-supabase-functions.ps1
```

**This script will automatically:**
1. ✅ Install Supabase CLI (if needed)
2. ✅ Login to Supabase
3. ✅ Link your project
4. ✅ Deploy all 3 Edge Functions
5. ✅ Set both environment secrets
6. ✅ Verify deployment

**Expected output:**
```
🚀 SUPABASE EDGE FUNCTIONS DEPLOYMENT
======================================

✅ Supabase CLI found
✅ Project directory: C:\safestride
✅ Authenticated with Supabase
✅ Project linked successfully

📦 DEPLOYING EDGE FUNCTIONS
✅ strava-oauth deployed
✅ strava-sync-activities deployed
✅ strava-refresh-token deployed

🔐 SETTING ENVIRONMENT SECRETS
✅ STRAVA_CLIENT_ID set
✅ STRAVA_CLIENT_SECRET set

🎉 DEPLOYMENT COMPLETE!
```

---

### **OPTION 2: MANUAL STEP-BY-STEP** 📝

If the script doesn't work, follow these steps:

#### **Step 1: Install Supabase CLI**
```powershell
npm install -g supabase
```

#### **Step 2: Login**
```powershell
supabase login
```
*(Opens browser for authentication)*

#### **Step 3: Link Project**
```powershell
cd C:\safestride
supabase link --project-ref bdisppaxbvygsspcuymb
```
*(May ask for database password - get it from [Database Settings](https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/settings/database))*

#### **Step 4: Deploy Functions**
```powershell
supabase functions deploy strava-oauth
supabase functions deploy strava-sync-activities
supabase functions deploy strava-refresh-token
```

#### **Step 5: Set Secrets**
```powershell
supabase secrets set STRAVA_CLIENT_ID=162971 --project-ref bdisppaxbvygsspcuymb
supabase secrets set STRAVA_CLIENT_SECRET=ca2a2ef68680c324e0ba4db3ed6e6006a9dc7626 --project-ref bdisppaxbvygsspcuymb
```

#### **Step 6: Verify**
```powershell
supabase functions list --project-ref bdisppaxbvygsspcuymb
supabase secrets list --project-ref bdisppaxbvygsspcuymb
```

---

## 🧪 **TESTING AFTER DEPLOYMENT**

### **Test 1: Check Function URLs**

Visit these URLs (should return `ok` for OPTIONS):
- https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/strava-oauth
- https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/strava-refresh-token

### **Test 2: Test Full OAuth Flow**

1. **Open:** https://www.akura.in/training-plan-builder.html
2. **Open DevTools Console:** Press F12
3. **Click:** "Connect Strava" button
4. **Authorize** on Strava
5. **Check console for:**
   - ✅ `"OAuth exchange successful"`
   - ✅ `"Found existing Strava connection"`
   - ✅ `"Loaded 908 activities from database"`
   - ✅ Green "Strava Connected ✓" button
   - ❌ NO 401 errors

### **Test 3: Test Session Persistence**

1. **Logout** from the app
2. **Login again**
3. **Expected:**
   - ✅ Green "Strava Connected" button appears immediately
   - ✅ Activities auto-load (no manual reconnection)
   - ✅ Console shows: `"Found existing Strava connection"`

---

## 🔧 **TROUBLESHOOTING**

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
3. Paste when prompted during `supabase link`

### **Error: "401 Unauthorized" still appearing**
```powershell
# Secrets might not be loaded - redeploy functions after setting secrets
supabase functions deploy strava-oauth --project-ref bdisppaxbvygsspcuymb
supabase functions deploy strava-sync-activities --project-ref bdisppaxbvygsspcuymb
supabase functions deploy strava-refresh-token --project-ref bdisppaxbvygsspcuymb
```

### **Supabase Dashboard 404 Error**
- This is a known Supabase dashboard bug
- **Use CLI instead** (that's why we created the scripts)
- Dashboard will work again after functions are deployed

---

## 📊 **DEPLOYMENT CHECKLIST**

Before testing, verify all these are ✅:

- [ ] Supabase CLI installed (`supabase --version`)
- [ ] Logged into Supabase (`supabase login`)
- [ ] Project linked (`supabase link --project-ref bdisppaxbvygsspcuymb`)
- [ ] `strava-oauth` deployed
- [ ] `strava-sync-activities` deployed
- [ ] `strava-refresh-token` deployed
- [ ] `STRAVA_CLIENT_ID` secret set
- [ ] `STRAVA_CLIENT_SECRET` secret set
- [ ] Functions list shows all 3 functions
- [ ] Secrets list shows both secrets

---

## 🚀 **EXPECTED RESULTS**

### **Before Deployment:**
❌ 401 Unauthorized errors  
❌ OAuth fails  
❌ Manual reconnection required every login  
❌ Button says "Connect Strava" on every page load  

### **After Deployment:**
✅ OAuth completes successfully  
✅ Green "Strava Connected ✓" button  
✅ 908 activities auto-loaded  
✅ No reconnection needed after logout/login  
✅ Token auto-refreshes every 6 hours  
✅ Session persists across logins  

---

## 📞 **NEXT STEPS**

**Reply with ONE of these:**

**A.** "Script ran successfully, testing now..."  
**B.** "Functions deployed, but getting error: [paste error]"  
**C.** "CLI not working, need alternative solution"  
**D.** "All working! 🎉"  

---

## 📁 **FILES CREATED**

| File | Purpose |
|------|---------|
| `deploy-supabase-functions.ps1` | **Automated deployment script** (run this!) |
| `SUPABASE_DEPLOY_FIX.md` | Manual deployment guide |
| `README_DEPLOYMENT_CRITICAL.md` | **This file** - main deployment guide |
| `public/strava-session-persistence.js` | Session persistence module |
| `supabase/functions/strava-oauth/index.ts` | OAuth Edge Function |
| `supabase/functions/strava-sync-activities/index.ts` | Activity sync Edge Function |
| `supabase/functions/strava-refresh-token/index.ts` | Token refresh Edge Function |

---

## 🔗 **IMPORTANT LINKS**

- **Your Website:** https://www.akura.in/training-plan-builder.html
- **Supabase Dashboard:** https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb
- **Edge Functions:** https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/functions
- **Database Settings:** https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/settings/database
- **Supabase CLI Docs:** https://supabase.com/docs/guides/cli

---

## ⏱️ **TIME ESTIMATE**

| Method | Time |
|--------|------|
| **Automated script** | 5-10 minutes |
| **Manual steps** | 10-15 minutes |
| **Troubleshooting** | 5-10 minutes |
| **Total** | **15-25 minutes** |

---

## 🎯 **SUCCESS CRITERIA**

You'll know it's working when:

1. ✅ `supabase functions list` shows 3 functions
2. ✅ `supabase secrets list` shows 2 secrets
3. ✅ https://www.akura.in/training-plan-builder.html loads
4. ✅ "Connect Strava" button works (no 401 error)
5. ✅ After OAuth, button turns green
6. ✅ Activities load automatically (908 total)
7. ✅ After logout and login, connection persists

---

**🚀 START HERE: Run the automated script!**

```powershell
cd C:\safestride && .\deploy-supabase-functions.ps1
```

---

*Last updated: 2026-03-03*  
*Git commit: 6ef99da*
