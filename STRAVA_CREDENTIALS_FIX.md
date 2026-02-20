# 🔧 CRITICAL FIX: Strava "invalid_client_id" Error

**Error**: `invalid_client_id` from Strava API
**Status**: ❌ BLOCKING OAuth flow

---

## 📋 Current Situation

### What We Know:
1. **Error Message**: Strava API returns "invalid_client_id"
2. **Current Credentials in Code**:
   - Client ID: `162971`
   - Client Secret: `6554eb9bb83f222a585e312c17420221313f85c1`

### What This Means:
The credentials in the Edge Function **don't match** your actual Strava app credentials.

---

## 🔍 Step-by-Step Diagnosis

### Step 1: Check Your Strava App Credentials

1. **Go to Strava API Settings**:
   ```
   https://www.strava.com/settings/api
   ```

2. **Find YOUR application** (should be named something like "SafeStride" or "Akura")

3. **Copy these values**:
   - **Client ID**: `_________________` (should be a number like 162971)
   - **Client Secret**: Click "show" → `_________________________________`
   - **Authorization Callback Domain**: `_________________` (should be `www.akura.in`)

4. **⚠️ IMPORTANT**: The callback domain should be EXACTLY:
   - ✅ Correct: `www.akura.in` (no https://, no trailing slash)
   - ❌ Wrong: `https://www.akura.in`
   - ❌ Wrong: `akura.in`
   - ❌ Wrong: `www.akura.in/`

---

### Step 2: Check Supabase Vault (if using environment variables)

1. **Go to Supabase Vault**:
   ```
   https://app.supabase.com/project/bdisppaxbvygsspcuymb/settings/vault/secrets
   ```

2. **Check if these secrets exist**:
   - `STRAVA_CLIENT_ID` → Click 👁️ to view value
   - `STRAVA_CLIENT_SECRET` → Click 👁️ to view value

3. **If they exist**: Note their values
4. **If they don't exist**: That's OK, we'll update the Edge Function directly

---

### Step 3: Compare Values

Fill in this table:

| Location | Client ID | Client Secret | Match? |
|----------|-----------|---------------|--------|
| **Strava App** | __________ | ________________ | - |
| **Edge Function** | 162971 | 6554eb9bb83... | - |
| **Supabase Vault** | __________ | ________________ | - |
| **config.js** | 162971 | 6554eb9bb83... | - |

**They should ALL be the same!**

---

## 🛠️ Fix Options

### Option A: Update Edge Function with Correct Credentials (FASTEST)

If your Strava app has **different** credentials than `162971`:

1. **Tell me your real credentials**:
   - Real Client ID: `__________`
   - Real Client Secret: `__________`

2. **I will update**:
   - `supabase/functions/strava-oauth/index.ts`
   - `supabase/functions/strava-sync-activities/index.ts`
   - `public/config.js`

3. **Redeploy Edge Functions**:
   ```bash
   supabase functions deploy strava-oauth
   supabase functions deploy strava-sync-activities
   ```

---

### Option B: Use Environment Variables (RECOMMENDED for production)

Move credentials to Supabase Vault for better security:

1. **Update Edge Function to use env vars**:
   ```typescript
   const STRAVA_CLIENT_ID = Deno.env.get('STRAVA_CLIENT_ID') ?? ''
   const STRAVA_CLIENT_SECRET = Deno.env.get('STRAVA_CLIENT_SECRET') ?? ''
   ```

2. **Set secrets in Supabase**:
   ```bash
   supabase secrets set STRAVA_CLIENT_ID=YOUR_REAL_CLIENT_ID
   supabase secrets set STRAVA_CLIENT_SECRET=YOUR_REAL_CLIENT_SECRET
   ```

3. **Redeploy functions**

---

### Option C: Create New Strava App (if credentials are lost)

If you don't have access to the original Strava app:

1. **Go to**: https://www.strava.com/settings/api
2. **Click**: "Create & Manage Your App"
3. **Fill in**:
   - Application Name: `SafeStride`
   - Category: `Training`
   - Club: (leave empty)
   - Website: `https://www.akura.in`
   - Authorization Callback Domain: `www.akura.in`
   - Description: `AI-powered athlete management and injury prevention`
4. **Click**: "Create"
5. **Copy new credentials** and use Option A or B above

---

## 🎯 What I Need From You

Please check and tell me:

### 1. Strava App Information:
```
Client ID: _______________
Client Secret: _______________
Callback Domain: _______________
```

### 2. Which fix option do you want?
- [ ] Option A: Update hardcoded credentials (fastest)
- [ ] Option B: Use Supabase Vault (more secure)
- [ ] Option C: Create new Strava app

### 3. Additional Info:
- [ ] Are the Edge Functions already deployed?
- [ ] Do you have access to the Strava app settings?
- [ ] Should I check any other files for credential mismatches?

---

## 🚀 Quick Commands to Check Everything

Run these in VS Code terminal:

```bash
# Check all files with Strava credentials
cd /home/user/webapp
grep -r "162971" . --include="*.ts" --include="*.js" --include="*.json"

# Check if .env or .dev.vars exists
ls -la | grep -E "\.env|\.dev\.vars"

# Check Supabase function status
supabase functions list 2>/dev/null || echo "Supabase CLI not configured"
```

---

## 🔥 Most Likely Issues

Based on "invalid_client_id" error, the problem is usually:

1. **Wrong Client ID** (90% chance)
   - The hardcoded `162971` doesn't match your Strava app
   - Fix: Update with correct Client ID

2. **Wrong Client Secret** (5% chance)
   - Client ID is right, but secret is wrong
   - Fix: Update with correct Client Secret

3. **Callback Domain Mismatch** (5% chance)
   - Your Strava app has different callback domain
   - Fix: Update Strava app settings to `www.akura.in`

---

## ⏱️ Time to Fix

- **If you have credentials**: 5 minutes
- **If need to find credentials**: 10 minutes
- **If need new Strava app**: 15 minutes

---

**Let's get this fixed now! Please share:**
1. Your real Strava Client ID and Secret
2. Which fix option you prefer
3. Any error messages from the commands above

I'll update all the files immediately! 🚀
