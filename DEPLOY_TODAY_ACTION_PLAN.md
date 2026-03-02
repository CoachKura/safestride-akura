# 🎯 DEPLOY TODAY - CLEAR ACTION PLAN

**Date**: March 2, 2026  
**Status**: Code Ready | 3 Manual Fixes Required | 15 Minutes to Deploy  
**Last Commit**: 4917f26 - "Add critical fix guide and deployment script"

---

## 🚨 YOU NEED TO DO 3 THINGS (I CAN'T DO THESE)

### ✅ **Action 1: Fix Strava App Settings** (2 minutes)

**Why**: Code sends `https://www.akura.in/training-plan-builder.html` but Strava app expects different URL

**Steps**:
1. Open: **https://www.strava.com/settings/api**
2. Find app with Client ID: **162971**
3. Change **"Authorization Callback Domain"** to: `www.akura.in`
4. Click **"Update Application"**

**Verification**: Setting should show `www.akura.in` (no https, no trailing slash)

---

### ✅ **Action 2: Create Database Tables** (5 minutes)

**Why**: SQL trying to insert into `profiles.user_id` but column doesn't exist

**Steps**:
1. Open: **https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/editor**
2. Click **"New Query"**
3. Copy this EXACT SQL:

```sql
-- Create profiles table with user_id column
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  role TEXT CHECK (role IN ('athlete','coach','admin')) NOT NULL DEFAULT 'athlete',
  full_name TEXT,
  email TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create athlete-coach relationships
CREATE TABLE IF NOT EXISTS public.athlete_coach_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  athlete_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  coach_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  status TEXT CHECK (status IN ('active','inactive','pending')) DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(athlete_id, coach_id)
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.athlete_coach_relationships ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "View relationships" ON public.athlete_coach_relationships FOR SELECT USING (auth.uid() = athlete_id OR auth.uid() = coach_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON public.profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_relationships_athlete ON public.athlete_coach_relationships(athlete_id);
CREATE INDEX IF NOT EXISTS idx_relationships_coach ON public.athlete_coach_relationships(coach_id);
```

4. Press **Ctrl+Enter** or click **"Run"**
5. Verify success message appears

**Verification**: Run this to confirm:
```sql
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name = 'user_id';
```
Should return 1 row.

---

### ✅ **Action 3: Get Supabase Anon Key and Update Config** (3 minutes)

**Why**: config.js has placeholder key, frontend can't connect to database

**Steps**:
1. Open: **https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/settings/api**
2. Copy the **"anon public"** key (long string starting with `eyJ...`)
3. Open file: `C:\safestride\public\config.js` (or `/home/user/webapp/public/config.js`)
4. Find line 11: `anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...YOUR_ACTUAL_KEY_HERE',`
5. Replace `YOUR_ACTUAL_KEY_HERE` with the key you copied (keep the `eyJ...` part before it)
6. Save the file

**Verification**: File should look like:
```javascript
supabase: {
    url: 'https://bdisppaxbvygsspcuymb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkaXNwcGF4YnZ5Z3NzcGN1eW1iIiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODI0NDQ4MDAsImV4cCI6MTk5ODAyMDgwMH0.REAL_KEY_HERE',
    functionsUrl: 'https://bdisppaxbvygsspcuymb.supabase.co/functions/v1'
},
```

---

## 🚀 AFTER YOU DO THOSE 3 THINGS, RUN THIS:

### Option A: Automatic Deployment Script (Recommended)
```bash
cd /home/user/webapp
./deploy-quick.sh
```
The script will:
- Check config is updated
- Commit changes
- Push to GitHub
- Trigger Vercel deployment

### Option B: Manual Deployment
```bash
cd /home/user/webapp
git add public/config.js
git commit -m "Fix: Add real Supabase anon key to config"
git push origin production
```

---

## ✅ VERIFICATION (After Deployment)

### Test 1: Homepage Loads
```
Open: https://www.akura.in
Expected: Page loads without errors
```

### Test 2: OAuth Flow Works
```
1. Open: https://www.akura.in/training-plan-builder.html
2. Click "Connect Strava"
3. Authorize on Strava
4. Should redirect back successfully (no "invalid redirect_uri" error)
```

### Test 3: Database Works
```sql
-- In Supabase SQL Editor
SELECT COUNT(*) FROM profiles;
```
Expected: Returns 0 (table exists, just empty)

### Test 4: Edge Functions Work
```bash
curl -X POST https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/strava-oauth \
  -H "Content-Type: application/json" \
  -H "apikey: YOUR_ANON_KEY" \
  -d '{"code":"test","athleteId":"test"}'
```
Expected: Should return Strava error (proving function is working, just code is invalid)

---

## 📊 WHAT GETS FIXED

| Problem | Fix | Result |
|---------|-----|--------|
| `invalid redirect_uri` | Strava app settings updated | OAuth flow works |
| `column "user_id" does not exist` | SQL creates tables | Database queries work |
| `your-project.supabase.co` in config | Real URL + key added | Frontend connects to backend |
| Edge Functions have wrong credentials | Already fixed in code | Token exchange works |

---

## 🎯 TIMELINE

- **Action 1**: 2 minutes (Strava settings)
- **Action 2**: 5 minutes (SQL execution)
- **Action 3**: 3 minutes (Config update)
- **Deploy**: 2 minutes (Git push)
- **Vercel Build**: 3 minutes (automatic)

**Total**: ~15 minutes from start to live site

---

## 🆘 IF YOU GET STUCK

### "I can't find my Strava app settings"
- Go to https://www.strava.com/settings/api
- If no app exists, create new one:
  - Application Name: SafeStride
  - Website: https://www.akura.in
  - Authorization Callback Domain: www.akura.in
  - Client ID will be: 162971 (must match code)

### "SQL throws error about duplicate table"
```sql
-- Run this first to clean up
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.athlete_coach_relationships CASCADE;

-- Then run the CREATE TABLE commands again
```

### "Can't find anon key in Supabase"
1. Go to: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/settings/api
2. Look for section "Project API keys"
3. Copy the key labeled "anon" or "public"
4. It's safe to use in frontend code (not the service_role key!)

### "Git push fails"
```bash
# Setup GitHub authentication first
cd /home/user/webapp
git config --global user.email "coach@akura.in"
git config --global user.name "Coach Kura"

# If push still fails, you might need to setup GitHub auth in sandbox
# The system should prompt for this
```

---

## 📞 WHAT TO TELL ME AFTER

Just say one of these:

1. **"Actions 1, 2, 3 done. Ready to deploy."** → I'll help push to GitHub
2. **"Stuck on Action X"** → I'll provide more specific help
3. **"All done and deployed!"** → I'll help verify everything works
4. **"Getting error: [paste error]"** → I'll diagnose the issue

---

## 🎉 SUCCESS LOOKS LIKE

After completing all steps:

1. ✅ https://www.akura.in loads without errors
2. ✅ Athletes can click "Connect Strava" and authorize successfully
3. ✅ OAuth redirects back to your site (not Strava error page)
4. ✅ No console errors about "invalid redirect_uri" or "user_id"
5. ✅ Strava activities sync to database
6. ✅ AISRI scores calculate
7. ✅ Dashboard displays data

**You'll have a working MVP deployed and accessible to athletes/coaches.**

---

**Current Status**: Waiting for you to complete Actions 1, 2, 3  
**Documentation**: See CRITICAL_FIX_GUIDE.md for detailed technical info  
**Quick Deploy**: Run `./deploy-quick.sh` after fixes

**Let me know when Actions 1, 2, 3 are done!** 🚀
