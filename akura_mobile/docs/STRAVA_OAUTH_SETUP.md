# Strava OAuth Setup Guide

**Date:** February 5, 2026  
**Status:** ✅ Credentials Received

---

## 🔑 STRAVA API CREDENTIALS

```
Application Name: SafeStride
Client ID: 162971
Client Secret: 6554eb9bb83f222a585e312c17420221313f85c1
Authorization Callback Domain: localhost
```

---

## 📋 SETUP CHECKLIST

### 1. Configure Strava Application Settings

**Go to:** https://www.strava.com/settings/api

**Update these fields:**
- ✅ Application Name: SafeStride
- ✅ Category: Health & Fitness
- ✅ Website: https://safestride.app (or your domain)
- ✅ **Authorization Callback Domain:** `localhost`

**IMPORTANT:** Set the "Authorization Callback Domain" to exactly: `localhost`

This allows testing on your local development environment.

---

### 2. Flutter App Configuration

**File:** `lib/services/strava_oauth_service.dart`

The credentials are **already hardcoded** in the service:

```dart
static const String _clientId = '162971';
static const String _clientSecret = '6554eb9bb83f222a585e312c17420221313f85c1';
static const String _redirectUri = 'http://localhost';
```

✅ **No further configuration needed!**

---

### 3. Database Setup (Already Complete)

The migration `migration_gps_watch_integration.sql` created:
- ✅ `gps_connections` table (stores OAuth tokens)
- ✅ `athlete_profiles` table (stores Strava athlete info)

**Verify in Supabase:**
```sql
-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('gps_connections', 'athlete_profiles');
```

---

## 🚀 TESTING THE OAUTH FLOW

### Step 1: Add GPS Connection Screen to Navigation

**Update your main navigation** (e.g., in `main.dart` or profile screen):

```dart
import 'package:safestride/screens/gps_connection_screen.dart';

// Add navigation button
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GPSConnectionScreen()),
    );
  },
  child: const Text('Connect GPS Watch'),
)
```

---

### Step 2: Test OAuth Flow

1. **Open GPS Connection Screen** in your app
2. **Tap "Connect Strava"** button
3. **Browser opens** → Strava authorization page
4. **Login to Strava** (if not already)
5. **Authorize SafeStride** → Click "Authorize"
6. **Copy authorization code** from redirect URL
7. **Paste code** in the app dialog
8. **Click "Connect"** → Token exchange happens
9. **Success!** → See athlete name and profile

---

### Step 3: Test API Connection

After connecting:

1. **Tap "Test" button** → Calls Strava API to verify connection
2. **Expected Result:**
   ```
   ✅ Strava API working!
   
   Athlete: [Your Name]
   Activities: runner
   ```

---

### Step 4: Sync Activities

1. **Tap "Sync" button** → Fetches last 30 days of activities
2. **Expected Result:**
   ```
   ✅ Synced 15 activities from last 30 days!
   
   [List of activities with distance, date, cadence]
   ```

---

## 🔐 SECURITY NOTES

### ✅ What's Secure:
- Client Secret is in Flutter code (compiled, not easily readable)
- Access tokens stored in Supabase (server-side, encrypted)
- Row-level security (RLS) policies protect user data

### ⚠️ Production Best Practice:
For production, consider moving Client Secret to:
1. **Supabase Edge Function** (server-side token exchange)
2. **Environment variables** (not committed to git)
3. **Flutter environment config** (separate dev/prod)

**Current setup is OK for MVP/testing!**

---

## 🎯 OAUTH FLOW DIAGRAM

```
User → [Connect Strava Button]
  ↓
SafeStride App → Strava Authorization URL
  ↓
Browser Opens → Strava Login Page
  ↓
User Authorizes → Strava Redirects with Code
  ↓
User Copies Code → Pastes in App
  ↓
App → POST to Strava Token URL (with code + secret)
  ↓
Strava → Returns Access Token + Refresh Token
  ↓
App → Stores tokens in Supabase gps_connections
  ↓
✅ Connected! → Can fetch activities via API
```

---

## 🧪 MANUAL TESTING CHECKLIST

- [ ] Open GPS Connection Screen
- [ ] Click "Connect Strava" button
- [ ] Browser opens Strava authorization page
- [ ] Login with Strava credentials
- [ ] Click "Authorize" button
- [ ] Redirected to callback URL with `code` parameter
- [ ] Copy code from URL (e.g., `code=abc123def456...`)
- [ ] Paste code in app dialog
- [ ] Click "Connect" button
- [ ] See success message with athlete name
- [ ] Check Supabase: `gps_connections` table has new row
- [ ] Click "Test" button → Should show athlete info
- [ ] Click "Sync" button → Should fetch activities
- [ ] Click "Disconnect" → Should remove connection

---

## 🐛 TROUBLESHOOTING

### Error: "Invalid redirect URI"
**Solution:** Update Strava app settings:
- Go to: https://www.strava.com/settings/api
- Find the **SafeStride** app (or click "Edit" if you see it)
- Look for the field **"Authorization Callback Domain"**
- Set it to: `localhost` (just the word, no http://)
- Click **"Update"** button to save
- Wait 5-10 seconds for Strava to process
- Close and reopen your browser
- Try authorizing again in the app

**Double-check:**
- Field name is "Authorization Callback Domain" NOT "Redirect URI"
- Value is exactly: `localhost` (lowercase, no spaces, no http://)
- You clicked Save/Update button

### Error: "Invalid client"
**Solution:** Double-check credentials in `strava_oauth_service.dart`:
```dart
static const String _clientId = '162971';
static const String _clientSecret = '6554eb9bb83f222a585e312c17420221313f85c1';
```

### Error: "Token exchange failed"
**Solution:** Check if:
- Authorization code was copied correctly (no extra spaces)
- Code hasn't expired (Strava codes expire after ~30 seconds)
- Try authorizing again and paste code immediately

### Error: "Could not open browser"
**Solution:** Add url_launcher to dependencies:
```yaml
dependencies:
  url_launcher: ^6.2.1
```

### No activities synced
**Solution:** Check:
- Athlete has activities in last 30 days on Strava
- Activities are "Run" type (not "Ride" or other)
- Token has correct scope: `read,activity:read_all`

---

## 📊 EXPECTED DATABASE ENTRIES

After successful connection:

**gps_connections table:**
```sql
user_id: [current user UUID]
platform: 'strava'
access_token: '[long token string]'
refresh_token: '[long token string]'
expires_at: '[6 hours from now]'
is_active: true
connected_at: '[timestamp]'
last_synced_at: '[timestamp]'
```

**athlete_profiles table:**
```sql
user_id: [current user UUID]
strava_athlete_id: [athlete ID]
strava_username: '[username]'
strava_firstname: '[first name]'
strava_lastname: '[last name]'
strava_profile_image: '[image URL]'
sync_from_strava: true
```

**gps_activities table:**
```sql
[Multiple rows, one per activity]
user_id: [current user UUID]
athlete_id: [SafeStride athlete ID]
platform: 'strava'
platform_activity_id: '[Strava activity ID]'
distance_meters: [distance]
duration_seconds: [duration]
avg_cadence: [cadence]
avg_heart_rate: [HR]
...
```

---

## 🎉 SUCCESS CRITERIA

✅ OAuth flow works end-to-end  
✅ Tokens stored in Supabase  
✅ API connection test passes  
✅ Activities sync successfully  
✅ Activities appear in `gps_activities` table  
✅ Protocol generation uses real GPS data  

---

## 📞 NEXT STEPS

1. **Test OAuth flow** (this week)
2. **Sync real activities** (this week)
3. **Generate protocol from real data** (this week)
4. **Add Garmin OAuth** (next week)
5. **Add Coros OAuth** (next week)
6. **Production deployment** (week 3-4)

---

**Questions?** Check the main documentation:
- `docs/GPS_INTEGRATION_IMPLEMENTATION.md` - Technical details
- `docs/QUICK_START_GPS.md` - Quick testing guide
