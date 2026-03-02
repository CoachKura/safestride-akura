# 🚨 CRITICAL FIX GUIDE - Deploy Today

**Date**: March 2, 2026  
**Status**: 3 Blockers Identified - Clear Fix Path

---

## 🎯 CURRENT SITUATION

### ✅ What's Working
- Edge Functions deployed with correct client secret (`ca2a2ef68680c324e0ba4db3ed6e6006a9dc7626`)
- All Supabase secrets configured (STRAVA_CLIENT_ID, STRAVA_CLIENT_SECRET, etc.)
- Frontend code fixed and committed (21 commits ahead)
- Functions responding (401/400 = deployed, just config issues)

### ❌ 3 Blockers to Fix

#### **Blocker 1: Strava OAuth `redirect_uri` Mismatch**
```
Error: { "field": "redirect_uri", "code": "invalid" }
```

**Cause**: Strava app settings don't match code

**Code is sending**: `https://www.akura.in/training-plan-builder.html`  
**Strava app expects**: Currently set to something different

**Fix** (2 minutes):
1. Go to: https://www.strava.com/settings/api
2. Find your app (Client ID: 162971)
3. Change **"Authorization Callback Domain"** to: `www.akura.in`
4. In the full redirect URI field, ensure it allows: `https://www.akura.in/training-plan-builder.html`
5. Save changes

---

#### **Blocker 2: Database Schema - Missing `user_id` Column**
```
Error: ERROR: 42703: column "user_id" does not exist
```

**Cause**: Database tables need to be created with correct schema

**Fix** (5 minutes):
1. Go to: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/editor
2. Run this SQL:

```sql
-- Create profiles table with correct schema
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

-- Policies for profiles
CREATE POLICY "Users can view own profile" 
  ON public.profiles FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" 
  ON public.profiles FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" 
  ON public.profiles FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Policies for relationships
CREATE POLICY "Athletes can view their coaches" 
  ON public.athlete_coach_relationships FOR SELECT 
  USING (auth.uid() = athlete_id OR auth.uid() = coach_id);

CREATE POLICY "Coaches can view their athletes" 
  ON public.athlete_coach_relationships FOR SELECT 
  USING (auth.uid() = coach_id);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON public.profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_relationships_athlete ON public.athlete_coach_relationships(athlete_id);
CREATE INDEX IF NOT EXISTS idx_relationships_coach ON public.athlete_coach_relationships(coach_id);
```

3. Click **"Run"** (Ctrl+Enter)
4. Verify with:
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_name IN ('profiles', 'athlete_coach_relationships');
```

Expected result: Both tables listed

---

#### **Blocker 3: Config.js Still Has Placeholder URLs**

**Current config.js**:
```javascript
supabase: {
    url: 'https://your-project.supabase.co',  // ❌ PLACEHOLDER
    anonKey: 'your-anon-key-here',             // ❌ PLACEHOLDER
```

**Should be**:
```javascript
supabase: {
    url: 'https://bdisppaxbvygsspcuymb.supabase.co',  // ✅ REAL
    anonKey: 'YOUR_ACTUAL_ANON_KEY',                   // ✅ FROM DASHBOARD
```

**Fix** (3 minutes):
1. Go to: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/settings/api
2. Copy your **anon/public** key (it's safe to use in frontend)
3. Update `/home/user/webapp/public/config.js`:

```javascript
const SAFESTRIDE_CONFIG = {
    supabase: {
        url: 'https://bdisppaxbvygsspcuymb.supabase.co',
        anonKey: 'YOUR_ACTUAL_ANON_KEY_FROM_DASHBOARD',
        functionsUrl: 'https://bdisppaxbvygsspcuymb.supabase.co/functions/v1'
    },
    // ... rest stays the same
};
```

---

## 🚀 DEPLOYMENT SEQUENCE (Total: 15 minutes)

### **Step 1: Fix Strava App Settings** (2 min)
```
□ Open https://www.strava.com/settings/api
□ Set Authorization Callback Domain: www.akura.in
□ Save
```

### **Step 2: Create Database Tables** (5 min)
```
□ Open Supabase SQL Editor
□ Paste the SQL above
□ Run (Ctrl+Enter)
□ Verify both tables created
```

### **Step 3: Update Config.js** (3 min)
```
□ Get anon key from Supabase dashboard
□ Update config.js with real URLs
□ Save file
```

### **Step 4: Deploy Frontend** (5 min)
```bash
cd /home/user/webapp
git add public/config.js
git commit -m "Fix: Update config with real Supabase credentials"
git push origin production
```

---

## ✅ VERIFICATION TESTS

### **Test 1: Database Schema**
```sql
-- In Supabase SQL Editor
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND column_name = 'user_id';
```
**Expected**: Returns 1 row showing `user_id | uuid`

### **Test 2: Strava OAuth Flow**
1. Open: https://www.akura.in/training-plan-builder.html
2. Click "Connect Strava"
3. Authorize on Strava
4. Should redirect back WITHOUT "invalid redirect_uri" error
5. Check browser console for success message

### **Test 3: Edge Function**
```bash
curl -X POST https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/strava-oauth \
  -H "Content-Type: application/json" \
  -H "apikey: YOUR_ANON_KEY" \
  -d '{"code":"test123","athleteId":"test-athlete"}'
```
**Expected**: Should return Strava error (not 401), proving function works

---

## 📊 DEPLOYMENT CHECKLIST

### Before Starting
- [ ] VS Code open to `C:\safestride` (or `/home/user/webapp`)
- [ ] Strava settings page open
- [ ] Supabase dashboard open
- [ ] Git authentication working

### During Deployment
- [ ] Blocker 1 fixed (Strava redirect_uri)
- [ ] Blocker 2 fixed (Database tables created)
- [ ] Blocker 3 fixed (Config.js updated)
- [ ] Code committed and pushed

### After Deployment
- [ ] Test 1 passed (Database schema)
- [ ] Test 2 passed (OAuth flow)
- [ ] Test 3 passed (Edge Function)
- [ ] No console errors on login page

---

## 🎯 EXPECTED RESULT

After completing all 3 fixes:

1. ✅ Athletes can connect Strava successfully
2. ✅ OAuth tokens saved to database
3. ✅ Activities sync from Strava
4. ✅ AISRI scores calculate
5. ✅ Training zones unlock based on scores
6. ✅ Dashboard shows all data

**Total Time**: ~15 minutes  
**Deployment**: Automatic via Vercel (on git push)

---

## 🆘 IF SOMETHING FAILS

### "Still getting redirect_uri error"
- Double-check Authorization Callback Domain is exactly: `www.akura.in`
- No `https://`, no trailing slash
- Try clicking "Update Application" again

### "Column still doesn't exist"
- Run `DROP TABLE IF EXISTS profiles CASCADE;` then re-run CREATE TABLE
- Check you're in the right Supabase project (bdisppaxbvygsspcuymb)

### "Config not updating"
- Clear browser cache (Ctrl+Shift+R)
- Check file saved correctly
- Verify git push succeeded

---

## 📞 NEXT STEPS AFTER DEPLOYMENT

1. Test athlete signup flow
2. Test coach signup flow
3. Test Strava connection
4. Verify AISRI score calculation
5. Test training zone unlocks
6. Deploy backend to Render (if needed)

---

**Last Updated**: March 2, 2026  
**By**: AISRi Deployment Assistant
