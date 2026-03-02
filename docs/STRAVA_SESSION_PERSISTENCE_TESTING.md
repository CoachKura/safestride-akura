# 🧪 STRAVA SESSION PERSISTENCE - TESTING GUIDE

**Date**: March 2, 2026
**Feature**: Auto-reconnect to Strava without repeated OAuth

---

## ✅ **BEFORE YOU TEST**

### 1. Verify Database Table Exists
Run this in Supabase SQL Editor:
```sql
SELECT * FROM strava_connections LIMIT 5;
```

Expected: Your existing connection record with 908 activities

### 2. Check Edge Functions Deployed
- ✅ strava-oauth
- ✅ strava-sync-activities  
- ✅ strava-callback
- ✅ strava-refresh-token (NEW)

---

## 🧪 **TEST SCENARIOS**

### **Test 1: First-Time Connection** (Baseline)
**Purpose**: Verify new users still connect normally

1. Open browser in **Incognito/Private mode**
2. Go to: https://www.akura.in/training-plan-builder.html
3. Click **"Connect Strava"** (orange button)
4. Authorize on Strava
5. Redirect back → Activities sync starts
6. **PASS if**: Button turns GREEN "Strava Connected", activities load

---

### **Test 2: Session Persistence** (THE FIX)
**Purpose**: Verify existing connections persist across logins

**Setup**: Use your real account (already connected with 908 activities)

1. Go to: https://www.akura.in/training-plan-builder.html
2. Open browser DevTools (F12) → Console tab
3. Look for log messages:
   - 🔍 Checking for existing Strava connection...
   - ✅ Found existing Strava connection: {athlete_id: ...}
   - 📊 Loading activities from database...
   - ✅ Loaded 908 activities from database

4. Check button state:
   - **SHOULD BE**: GREEN "Strava Connected" ✅
   - **NOT**: Orange "Connect Strava" ❌

5. Check status message below button:
   - **SHOULD SHOW**: "Last synced: [date]" or "908 activities loaded"

6. **Click the green button**:
   - Should say "Syncing..." briefly
   - Then refresh activity count
   - **NO** OAuth redirect

**PASS CRITERIA**:
- ✅ Button is GREEN on page load (no manual connection needed)
- ✅ Activities auto-load from database  
- ✅ Click button = sync, NOT reconnect
- ✅ Console shows "Found existing Strava connection"

**FAIL if**:
- ❌ Button stays ORANGE (means not detecting connection)
- ❌ User must click "Connect Strava" every time
- ❌ OAuth redirect happens when clicking green button

---

### **Test 3: Token Expiration Handling**
**Purpose**: Verify automatic token refresh works

**Setup**: Manually expire the token in database (testing only)

1. Run in Supabase SQL Editor:
```sql
UPDATE strava_connections 
SET expires_at = NOW() - INTERVAL '1 hour'
WHERE athlete_id = 'YOUR_ATHLETE_ID';
```

2. Reload page
3. Look for console log:
   - ⚠️ Strava token expired, attempting refresh...
   - 🔄 Refreshing Strava token...
   - ✅ Token refreshed successfully

4. Check database:
```sql
SELECT expires_at FROM strava_connections WHERE athlete_id = 'YOUR_ATHLETE_ID';
```

**PASS if**: expires_at is now ~6 hours in the future (token refreshed)

---

### **Test 4: Disconnected User**
**Purpose**: Verify users without connections see connect button

1. Create new test account OR clear your connection:
```sql
DELETE FROM strava_connections WHERE athlete_id = 'test_user';
```

2. Go to training-plan-builder.html
3. **SHOULD SEE**: Orange "Connect Strava" button
4. Console log: "❌ No Strava connection found"

**PASS if**: Button is ORANGE, onclick triggers OAuth

---

### **Test 5: Logout/Login Cycle**
**Purpose**: The main bug fix - verify persistence after logout

1. **Connect Strava** (if not already)
2. Verify activities loaded (908 activities)
3. **Logout** from SafeStride
4. Close browser completely
5. Open browser again
6. **Login** to SafeStride
7. Go to training-plan-builder.html

**PASS if**:
- ✅ Button is GREEN immediately (no orange "Connect" button)
- ✅ Activities auto-load without user clicking anything
- ✅ Previous connection is remembered

**FAIL if**:
- ❌ Button is ORANGE (user must reconnect)
- ❌ No activities shown until user clicks "Connect Strava"

---

## 📊 **SUCCESS METRICS**

### Expected Console Output (Successful Connection)
```
🚀 Page loaded, checking Strava connection...
🔍 Checking for existing Strava connection...
✅ Found existing Strava connection: {athlete_id: "user_xxx", strava_athlete_id: 123456}
📊 Loading activities from database for athlete: user_xxx
✅ Loaded 908 activities from database
📊 Stats calculated: {totalDistance: 1234.5, recentActivityCount: 45}
✅ User already connected, no OAuth needed
```

### Expected Console Output (New User)
```
🚀 Page loaded, checking Strava connection...
🔍 Checking for existing Strava connection...
❌ No Strava connection found: "No rows found"
⚠️ No Strava connection found, user must connect
```

---

## 🐛 **KNOWN ISSUES & TROUBLESHOOTING**

### Issue: Button stays orange even though connected
**Cause**: checkExistingStravaConnection() returning null
**Fix**: Check console for error messages, verify strava_connections table exists

### Issue: "Failed to fetch" error on token refresh
**Cause**: strava-refresh-token Edge Function not deployed or missing secrets
**Fix**: Deploy function, set SUPABASE_SERVICE_ROLE_KEY in secrets

### Issue: Activities not loading
**Cause**: strava_activities table empty or wrong athlete_id
**Fix**: Check database with:
```sql
SELECT COUNT(*) FROM strava_activities WHERE athlete_id = 'YOUR_ID';
```

---

## 📝 **REPORTING RESULTS**

After testing, report:
1. ✅ / ❌ Test 1 (First-time connection)
2. ✅ / ❌ Test 2 (Session persistence) - **MOST IMPORTANT**
3. ✅ / ❌ Test 5 (Logout/login cycle) - **MAIN BUG FIX**

Include:
- Browser console screenshot
- Button color (GREEN or ORANGE)
- Activity count displayed

---

**Expected Result**: Test 2 and Test 5 should PASS (button stays green, no reconnection needed)

