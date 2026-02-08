# ✅ Quick Testing Checklist - Strava OAuth with Supabase

## Before Testing

### Supabase Dashboard Configuration:
- [ ] Opened Supabase Dashboard: https://app.supabase.com
- [ ] Selected project: **akura-safestride**
- [ ] Went to: **Authentication** → **Providers**
- [ ] Found **Strava** provider
- [ ] Enabled Strava (toggle switch ON)
- [ ] Added Client ID: `162971`
- [ ] Added Client Secret: `6554eb9bb83f222a585e312c17420221313f85c1`
- [ ] Copied the redirect URL shown (e.g., `https://akura-safestride.supabase.co/auth/v1/callback`)
- [ ] Clicked **Save**

### Strava App Settings:
- [ ] Opened: https://www.strava.com/settings/api
- [ ] Found: **Authorization Callback Domain**
- [ ] Removed any old entries (like `localhost`)
- [ ] Added: `akura-safestride.supabase.co` (domain only, not full URL)
- [ ] Clicked **Update**

---

## Testing the OAuth Flow

### 1. Start the App:
```powershell
cd "e:\Akura Safe Stride\safestride\akura_mobile"
flutter run -d chrome
```

### 2. Navigate to Connection Screen:
- [ ] App opened in Chrome
- [ ] Clicked: **Profile** (bottom navigation)
- [ ] Saw **GPS Watch Connection** card
- [ ] Clicked: **Manage GPS Connections** button
- [ ] GPS Connection screen appeared

### 3. Connect to Strava:
- [ ] Clicked: **Connect Strava** button
- [ ] New browser tab opened automatically
- [ ] Saw Strava authorization page
- [ ] (If not logged in) Entered Strava credentials
- [ ] Clicked: **Authorize** button on Strava page
- [ ] Browser tab closed automatically
- [ ] Back in SafeStride app

### 4. Verify Connection:
- [ ] Saw success message: ✅ "Successfully connected to Strava!"
- [ ] Strava card now shows **"Connected"** status
- [ ] Athlete profile appears (name, username, photo)
- [ ] Three buttons visible: **Test Connection**, **Sync Activities**, **Disconnect**

### 5. Test Connection:
- [ ] Clicked: **Test Connection** button
- [ ] Saw loading spinner
- [ ] Success message appeared: "Connection is valid"
- [ ] Athlete profile data displayed

### 6. Sync Activities:
- [ ] Clicked: **Sync Activities** button
- [ ] Saw loading spinner
- [ ] Success message: "Synced X activities"
- [ ] (Check database to verify - see below)

---

## Verification Steps

### Check Supabase Authentication:
1. Go to: Supabase Dashboard → **Authentication** → **Users**
2. Look for: New user entry with provider = **strava**
3. Check: Metadata shows Strava athlete info

### Check Database - gps_connections:
1. Go to: Supabase Dashboard → **Table Editor** → **gps_connections**
2. Verify row exists with:
   - ✅ `platform` = 'strava'
   - ✅ `access_token` = (long string, starts with token characters)
   - ✅ `refresh_token` = (long string)
   - ✅ `expires_at` = (future timestamp)
   - ✅ `athlete_id` = (your Strava athlete ID)
   - ✅ `created_at` = (today's timestamp)

### Check Database - gps_activities:
1. Go to: Supabase Dashboard → **Table Editor** → **gps_activities**
2. After sync, verify activities appear:
   - ✅ `platform` = 'strava'
   - ✅ `activity_type` = 'Run', 'Ride', etc.
   - ✅ `start_date` = (activity dates)
   - ✅ `distance` > 0
   - ✅ `moving_time` > 0
   - ✅ Raw data in `raw_data` column

---

## Expected Results

### ✅ Success Indicators:
1. **UI Level:**
   - Connection screen shows "Connected" status
   - Athlete profile visible with name and photo
   - Test button returns valid connection
   - Sync button successfully fetches activities

2. **Database Level:**
   - `gps_connections` table has new Strava entry
   - `gps_activities` table populated with recent activities
   - Tokens stored securely

3. **No Errors:**
   - No "redirect_uri invalid" errors
   - No popup blocker issues
   - Browser tab closes cleanly after authorization

### ❌ If Something Goes Wrong:

**Error: "OAuth provider is not enabled"**
- Go back to Supabase Dashboard
- Verify Strava provider toggle is ON (green)
- Check Client ID and Secret are saved correctly
- Wait 30 seconds and try again

**Error: "Failed to open OAuth URL"**
- Check browser popup blocker
- Allow popups for localhost
- Try again

**Connection succeeds but Test fails:**
- Check Strava API rate limits (might be reached)
- Verify scopes include: `read,activity:read_all`
- Check Strava app settings haven't changed

**Activities don't sync:**
- Make sure you have activities in Strava account
- Activity dates must be within last 30 days (Strava API default)
- Check console for API errors (F12 → Console)

---

## Quick Commands Reference

### Start Flutter Web App:
```powershell
cd "e:\Akura Safe Stride\safestride\akura_mobile"
flutter run -d chrome
```

### Check Supabase Logs:
```powershell
# Open in browser:
# https://app.supabase.com/project/YOUR_PROJECT_ID/logs/auth-logs
```

### Reset Connection (if needed):
1. In app: Click **Disconnect** button
2. In Supabase: Delete row from `gps_connections` table
3. Try connecting again

---

## Timeline

**Expected completion time:**
- [ ] Supabase setup: 5 minutes
- [ ] Strava app update: 2 minutes
- [ ] Testing OAuth: 2 minutes
- [ ] Verify database: 1 minute
- **Total: ~10 minutes**

---

## Next Steps After Success

1. **Generate Protocols from Real GPS Data:**
   - Protocols will now use your actual Strava activities
   - More accurate cadence, pace, distance data

2. **Test Different Activity Types:**
   - Try running activities
   - Long runs vs. speed workouts
   - See how protocol generation adapts

3. **Add More GPS Platforms (Future):**
   - Garmin Connect
   - Coros (similar to Strava setup)

---

## 🎉 Success Criteria

You'll know it's working when:
- ✅ No redirect URI errors
- ✅ OAuth completes in ~10 seconds
- ✅ Athlete profile shows in app
- ✅ Test connection succeeds
- ✅ Activities appear in database
- ✅ No browser errors or popups

**If all checkboxes above are checked: You're done! 🚀**

---

*Pro tip: Keep browser console open (F12) during testing to see detailed logs*
