# SafeStride Strava Signup - Complete Implementation Guide

## 🎯 Overview

Complete Strava OAuth signup system for both web dashboard and mobile app that automatically:

- ✅ Fetches athlete profile (name, age, gender, weight, photo)
- ✅ Calculates Personal Bests (5K, 10K, Half Marathon, Marathon)
- ✅ Aggregates total mileage and activity stats
- ✅ Creates Supabase account with pre-filled data
- ✅ Syncs all activities in background (up to 1000)

## 📁 Files Created

### 1. Mobile App (Flutter)

```
lib/screens/strava_signup_screen.dart      - Main signup screen with Strava OAuth
lib/screens/athlete_dashboard.dart         - Post-signup dashboard showing all data
lib/services/strava_complete_sync_service.dart - Core service handling OAuth & sync
```

### 2. Web Dashboard

```
web/signup.html                            - Web signup page with Strava button
```

### 3. Backend API

```
ai_agents/strava_signup_api.py            - FastAPI endpoint for OAuth callback
```

### 4. Database

```
supabase/migrations/20240115_strava_signup_stats.sql - Database schema for PBs & stats
```

## 🚀 Setup Instructions

### Step 1: Database Migration

Run the migration to add new columns for Strava data:

```bash
# Option 1: Using Supabase CLI
cd c:\safestride
npx supabase db push

# Option 2: Manual SQL execution
# Go to Supabase Dashboard → SQL Editor
# Copy and execute: supabase/migrations/20240115_strava_signup_stats.sql
```

**New columns added:**

- `strava_athlete_id` - Unique Strava athlete ID
- `strava_access_token`, `strava_refresh_token` - OAuth tokens
- `pb_5k`, `pb_10k`, `pb_half_marathon`, `pb_marathon` - Personal Bests (seconds)
- `total_runs`, `total_distance_km`, `total_time_hours` - Activity stats
- `avg_pace_min_per_km`, `longest_run_km` - Performance metrics
- `profile_photo_url`, `gender`, `weight`, `height` - Profile data

### Step 2: Environment Variables

Add to `.env` file:

```bash
# Strava OAuth Credentials
STRAVA_CLIENT_ID=162971
STRAVA_CLIENT_SECRET=<your_client_secret>
STRAVA_REDIRECT_URI_WEB=https://akura.in/strava-callback
STRAVA_REDIRECT_URI_APP=safestride://strava-callback

# Supabase Credentials (already configured)
SUPABASE_URL=https://bdisppaxbvygsspcuymb.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<your_service_role_key>
```

### Step 3: Start Backend API

```bash
cd c:\safestride\ai_agents
pip install fastapi uvicorn httpx python-dotenv supabase

# Start the API server
python strava_signup_api.py

# Server runs on: http://localhost:8000
# Health check: http://localhost:8000/health
# Signup endpoint: POST http://localhost:8000/api/strava-signup
```

### Step 4: Update Web Dashboard

The web signup page (`web/signup.html`) needs to call the backend API.

**Update the JavaScript in signup.html (line ~200):**

```javascript
async function completeSignup(code) {
    try {
        // Call backend API (update URL to your deployed API)
        const response = await fetch('http://localhost:8000/api/strava-signup', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ code }),
        });

        // ... rest of the code
    }
}
```

### Step 5: Update Mobile App Routes

Add new routes to your Flutter app:

**lib/main.dart:**

```dart
import 'package:safestride/screens/strava_signup_screen.dart';
import 'package:safestride/screens/athlete_dashboard.dart';

// In MaterialApp routes:
routes: {
  '/': (context) => const StravaSignupScreen(),
  '/dashboard': (context) => const AthleteDashboard(),
  // ... other routes
},
```

## 📱 Mobile App Usage

### User Flow:

1. **Launch App** → Shows `StravaSignupScreen`
2. **Click "Sign Up with Strava"** → Opens WebView OAuth
3. **Authorize Strava** → Returns authorization code
4. **Background Processing:**
   - Exchange code for token ✓
   - Fetch athlete profile ✓
   - Create Supabase account ✓
   - Start activity sync in background ✓
5. **Navigate to Dashboard** → Shows all auto-populated data

### Code Example:

```dart
// Navigate to signup
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const StravaSignupScreen(),
  ),
);
```

## 🌐 Web Dashboard Usage

### User Flow:

1. **Visit** `https://akura.in/signup`
2. **Click "Sign Up with Strava"** → Redirects to Strava OAuth
3. **Authorize** → Redirects back with code
4. **JavaScript calls API** → `POST /api/strava-signup`
5. **Receive session token** → Store in localStorage
6. **Redirect to dashboard** → `https://akura.in/dashboard`

### Deployment:

```bash
# Deploy web/signup.html to your web server
# Make sure to update API endpoint URL in JavaScript
# Update Strava redirect URI in .env and Strava app settings
```

## 🔧 API Endpoints

### POST /api/strava-signup

**Request:**

```json
{
  "code": "authorization_code_from_strava"
}
```

**Response:**

```json
{
  "user_id": "uuid-here",
  "access_token": "supabase_session_token",
  "refresh_token": "supabase_refresh_token",
  "athlete": {
    "id": 123456789,
    "firstname": "John",
    "lastname": "Doe",
    "sex": "M",
    "profile": "https://...",
    "weight": 70
  },
  "message": "Signup successful! Background sync started."
}
```

### GET /health

**Response:**

```json
{
  "status": "healthy",
  "service": "SafeStride Strava Signup API"
}
```

## 📊 Data Synced from Strava

### Profile Data:

- ✅ First Name
- ✅ Last Name
- ✅ Gender (M/F)
- ✅ Weight (kg)
- ✅ Profile Photo URL
- ✅ City, State, Country

### Personal Bests (PBs):

- ✅ 5K (4.8-5.2 km range)
- ✅ 10K (9.8-10.2 km range)
- ✅ Half Marathon (20-22 km)
- ✅ Marathon (42-43 km)

### Activity Statistics:

- ✅ Total Runs Count
- ✅ Total Distance (km)
- ✅ Total Time (hours)
- ✅ Average Pace (min/km)
- ✅ Longest Run (km)

### Individual Activities:

All running activities stored in `strava_activities` table with:

- Activity ID, Name, Date
- Distance, Time, Elevation
- Heart Rate, Cadence, Speed

## 🔄 Background Sync Process

The sync happens asynchronously and doesn't block signup:

```
User authorizes → Account created immediately
                ↓
              Dashboard displayed (empty stats)
                ↓
              Background sync starts
                ↓
              Fetches 200 activities per page
                ↓
              Calculates PBs and stats
                ↓
              Updates database
                ↓
              Dashboard refreshes automatically
```

**Sync Duration:**

- 100 activities: ~30 seconds
- 500 activities: ~2 minutes
- 1000 activities: ~5 minutes

## 🧪 Testing

### Test Signup Flow:

```bash
# 1. Start backend API
cd c:\safestride\ai_agents
python strava_signup_api.py

# 2. Open web signup page
# Navigate to: http://localhost:8000/signup.html
# Or use Flutter app

# 3. Click "Sign Up with Strava"

# 4. Authorize with Strava test account

# 5. Check database:
# - profiles table should have new user with strava_athlete_id
# - After sync: PBs, stats should be populated
# - strava_activities table should have all activities
```

### Test API Directly:

```bash
# Get authorization code from Strava OAuth
# Then test token exchange:

curl -X POST http://localhost:8000/api/strava-signup \
  -H "Content-Type: application/json" \
  -d '{"code": "your_authorization_code"}'
```

## 🐛 Troubleshooting

### Issue: Strava OAuth fails with "Invalid redirect URI"

**Solution:** Update redirect URI in:

1. Strava App Settings: https://www.strava.com/settings/api
2. `.env` file: `STRAVA_REDIRECT_URI_WEB`
3. `web/signup.html`: `REDIRECT_URI` constant

### Issue: Background sync not working

**Check:**

1. Strava API rate limits (100 requests per 15 minutes)
2. Access token validity (expires after 6 hours)
3. Backend API logs: `python strava_signup_api.py` (check console)

### Issue: Database columns missing

**Solution:**

```sql
-- Run migration manually:
-- Copy contents of: supabase/migrations/20240115_strava_signup_stats.sql
-- Execute in Supabase SQL Editor
```

### Issue: PBs not calculated correctly

**Check:**

1. Activity distances in correct range (5K = 4.8-5.2 km)
2. Activities have `moving_time` field
3. Activity type is "Run" (not "Ride", "Swim", etc.)

## 📈 Database Schema

### profiles table (new columns):

```sql
strava_athlete_id        BIGINT UNIQUE
strava_access_token      TEXT
strava_refresh_token     TEXT
strava_token_expires_at  TIMESTAMP
last_strava_sync         TIMESTAMP

profile_photo_url        TEXT
gender                   VARCHAR(10)
weight                   DECIMAL(5,2)

pb_5k                    INTEGER  -- seconds
pb_10k                   INTEGER  -- seconds
pb_half_marathon         INTEGER  -- seconds
pb_marathon              INTEGER  -- seconds

total_runs               INTEGER
total_distance_km        DECIMAL(10,2)
total_time_hours         DECIMAL(10,2)
avg_pace_min_per_km      DECIMAL(5,2)
longest_run_km           DECIMAL(6,2)
```

### strava_activities table (new):

```sql
id                      UUID PRIMARY KEY
user_id                 UUID (FK to auth.users)
strava_activity_id      BIGINT UNIQUE
name                    TEXT
distance_meters         DECIMAL(10,2)
moving_time_seconds     INTEGER
elapsed_time_seconds    INTEGER
total_elevation_gain    DECIMAL(8,2)
activity_type           VARCHAR(50)
start_date              TIMESTAMP
average_speed           DECIMAL(5,2)
max_speed               DECIMAL(5,2)
average_heartrate       INTEGER
max_heartrate           INTEGER
average_cadence         DECIMAL(5,2)
created_at              TIMESTAMP
```

## 🔐 Security Features

- ✅ OAuth 2.0 authorization
- ✅ CSRF protection (state parameter)
- ✅ Secure password generation for Strava users
- ✅ Row Level Security (RLS) on activities table
- ✅ Supabase JWT authentication
- ✅ Token refresh handling

## 📚 Related Documentation

- [SIGNUP_AND_DATA_SYNC_GUIDE.md](SIGNUP_AND_DATA_SYNC_GUIDE.md) - Full OAuth flow
- [GARMIN_DATA_FORMAT_GUIDE.md](GARMIN_DATA_FORMAT_GUIDE.md) - Garmin integration
- [AI_WORKOUT_TO_GARMIN_CALENDAR.md](AI_WORKOUT_TO_GARMIN_CALENDAR.md) - Workout generation

## 🎉 Success Metrics

After successful signup, users have:

- ✅ Profile with name, photo, stats
- ✅ Personal Bests for 5K, 10K, Half, Marathon
- ✅ Total mileage across all runs
- ✅ Average pace and longest run
- ✅ Complete activity history
- ✅ Ready to use AI features immediately

## 🚀 Next Steps

1. **Deploy backend API** to Railway/Render/Heroku
2. **Update web dashboard** with API endpoint URL
3. **Test with real Strava accounts**
4. **Add Garmin sync** after Strava signup
5. **Enable AISRI injury scoring** on activities
6. **Generate personalized timeline** based on current pace

## 📞 Support

For issues or questions:

- Check Strava API docs: https://developers.strava.com
- Check Supabase docs: https://supabase.com/docs
- Review backend API logs for errors
- Verify OAuth redirect URIs match exactly

---

**Ready to use!** 🎯 Users can now sign up with one click and get their complete running profile auto-populated from Strava.
