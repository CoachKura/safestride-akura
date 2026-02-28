# Strava Signup - Quick Reference Card

## 🚀 Quick Start (30 seconds)

```bash
# 1. Run migration
npx supabase db push

# 2. Start API
cd ai_agents
python strava_signup_api.py

# 3. Test
.\test-strava-signup.ps1
```

## 📋 File Locations

```
Mobile App:
├── lib/screens/strava_signup_screen.dart      ← Main signup UI
├── lib/screens/athlete_dashboard.dart         ← Post-signup dashboard
└── lib/services/strava_complete_sync_service.dart  ← Core service

Web Dashboard:
└── web/signup.html                            ← Web signup page

Backend API:
└── ai_agents/strava_signup_api.py            ← FastAPI server

Database:
└── supabase/migrations/20240115_strava_signup_stats.sql
```

## 🔑 Environment Variables

```bash
# .env file
STRAVA_CLIENT_ID=162971
STRAVA_CLIENT_SECRET=<your_secret>
STRAVA_REDIRECT_URI_WEB=https://akura.in/strava-callback
STRAVA_REDIRECT_URI_APP=safestride://strava-callback
SUPABASE_URL=https://bdisppaxbvygsspcuymb.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<your_key>
```

## 🌐 API Endpoints

```bash
# Health Check
GET http://localhost:8000/health

# Signup
POST http://localhost:8000/api/strava-signup
Body: {"code": "authorization_code"}
```

## 📊 Database Tables

### profiles (new columns)

```sql
strava_athlete_id        BIGINT
strava_access_token      TEXT
pb_5k                    INTEGER  -- seconds
pb_10k                   INTEGER  -- seconds
pb_half_marathon         INTEGER  -- seconds
pb_marathon              INTEGER  -- seconds
total_runs               INTEGER
total_distance_km        DECIMAL(10,2)
avg_pace_min_per_km      DECIMAL(5,2)
```

### strava_activities (new table)

```sql
id                       UUID
user_id                  UUID
strava_activity_id       BIGINT
distance_meters          DECIMAL(10,2)
moving_time_seconds      INTEGER
start_date               TIMESTAMP
```

## 🧪 Test Commands

```powershell
# Full integration test
.\test-strava-signup.ps1

# Start API
.\start-strava-signup-api.ps1

# Manual test
curl -X POST http://localhost:8000/api/strava-signup \
  -H "Content-Type: application/json" \
  -d '{"code": "your_code"}'
```

## 🎯 User Flow

```
1. Click "Sign Up with Strava"
2. Authorize on Strava
3. Redirect with code
4. Backend creates account
5. Background sync starts
6. Dashboard shows data
```

## 📦 Dependencies

```bash
# Python
pip install fastapi uvicorn httpx python-dotenv supabase

# Flutter (in pubspec.yaml)
supabase_flutter: ^2.0.0
http: ^1.1.0
flutter_dotenv: ^5.1.0
```

## 🔧 Common Issues

### OAuth Redirect Mismatch

```bash
# Fix: Update Strava app settings
https://www.strava.com/settings/api
Callback Domain: akura.in
Authorization Callback Domain: https://akura.in/strava-callback
```

### Missing Database Columns

```bash
# Fix: Run migration
npx supabase db push
# Or manually execute SQL from:
# supabase/migrations/20240115_strava_signup_stats.sql
```

### API Connection Failed

```bash
# Fix: Check if API is running
curl http://localhost:8000/health
# If not, start it:
python ai_agents/strava_signup_api.py
```

## 📈 Data Synced

### Profile Data

- ✅ Name (first, last)
- ✅ Gender (M/F)
- ✅ Weight (kg)
- ✅ Profile photo URL

### Performance Data

- ✅ 5K PB (e.g., 21:30 → 1290 seconds)
- ✅ 10K PB
- ✅ Half Marathon PB
- ✅ Marathon PB

### Statistics

- ✅ Total runs count
- ✅ Total distance (km)
- ✅ Average pace (min/km)
- ✅ Longest run (km)

## 🔄 Background Sync

```
Sync Timing:
- 100 activities: ~30 seconds
- 500 activities: ~2 minutes
- 1000 activities: ~5 minutes

Rate Limits:
- Strava: 100 requests / 15 minutes
- Batching: 200 activities per request
```

## 📱 Flutter Usage

```dart
// Navigate to signup
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const StravaSignupScreen(),
  ),
);

// After signup, navigate to dashboard
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => const AthleteDashboard(),
  ),
);
```

## 🌐 Web Usage

```html
<!-- Add to your web app -->
<script src="signup.html"></script>

<!-- Redirect to signup -->
<a href="/signup.html">Sign Up with Strava</a>
```

## 🔐 Security Checklist

- ✅ OAuth 2.0 authorization
- ✅ CSRF protection (state parameter)
- ✅ Secure password generation
- ✅ Row Level Security (RLS) enabled
- ✅ JWT token authentication
- ✅ Token refresh handling

## 📞 Debug Commands

```powershell
# Check environment
Get-Content .env | Select-String "STRAVA"

# Check database
psql $env:DATABASE_URL -c "SELECT COUNT(*) FROM profiles WHERE strava_athlete_id IS NOT NULL"

# Check API logs
python ai_agents/strava_signup_api.py  # Watch console output

# Test OAuth URL
echo "https://www.strava.com/oauth/authorize?client_id=$env:STRAVA_CLIENT_ID&redirect_uri=$env:STRAVA_REDIRECT_URI_WEB&response_type=code&scope=read,activity:read_all,profile:read_all"
```

## 🎨 UI Customization

```dart
// Change signup button color
ElevatedButton.styleFrom(
  backgroundColor: Color(0xFFFC4C02), // Strava orange
)

// Change logo
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.orange.shade700, Colors.deepOrange.shade900],
    ),
  ),
)
```

## 📊 Monitoring

```sql
-- Check signup activity
SELECT
  COUNT(*) as total_signups,
  COUNT(CASE WHEN strava_athlete_id IS NOT NULL THEN 1 END) as strava_signups,
  AVG(total_runs) as avg_runs
FROM profiles
WHERE created_at > NOW() - INTERVAL '7 days';

-- Check sync status
SELECT
  id,
  first_name,
  last_name,
  last_strava_sync,
  total_runs
FROM profiles
WHERE strava_athlete_id IS NOT NULL
ORDER BY last_strava_sync DESC
LIMIT 10;
```

## 🎯 Success Metrics

After successful signup:

- ✅ User has profile with name & photo
- ✅ PBs are populated (if available)
- ✅ Total mileage is calculated
- ✅ Dashboard displays all data
- ✅ Ready for AI features

## 🚀 Deployment

```bash
# Deploy API to Railway
railway login
railway up

# Update web dashboard API URL
# In web/signup.html line ~200:
const API_URL = 'https://your-api.railway.app';

# Deploy web to hosting (Vercel, Netlify, etc.)
vercel deploy

# Build Flutter app
flutter build apk  # Android
flutter build ios  # iOS
```

## 📚 Related Docs

- [STRAVA_SIGNUP_COMPLETE_GUIDE.md](STRAVA_SIGNUP_COMPLETE_GUIDE.md) - Full guide
- [STRAVA_SIGNUP_ARCHITECTURE.md](STRAVA_SIGNUP_ARCHITECTURE.md) - Architecture diagrams
- [SIGNUP_AND_DATA_SYNC_GUIDE.md](SIGNUP_AND_DATA_SYNC_GUIDE.md) - OAuth flow details

---

**Need help?** Check the full guide or review architecture diagrams.
