# 🌐 Production Supabase Configuration

## Current Active Configuration

**✅ Your app is now connected to PRODUCTION Supabase**

---

## 🔑 Production Credentials

**Project Reference:** `xzxnnswggwqtctcgpocr`

**API Configuration:**
- **URL:** https://xzxnnswggwqtctcgpocr.supabase.co
- **Anon Key:** sb_publishable_Zyucm83AmvswhLn5nIWLTw_wQQxpEVz

**Database Connection:**
- **Host:** db.xzxnnswggwqtctcgpocr.supabase.co
- **Port:** 5432
- **Database:** postgres
- **User:** postgres
- **Password:** Akura@2026$

---

## 🚀 Next Steps

### 1. Apply Strava Migration to Production

**Option A: Supabase Dashboard (Easiest)**
1. Migration SQL is already copied above
2. Supabase SQL Editor should be open in your browser
3. Paste the SQL
4. Click "Run"
5. Verify: "Success. No rows returned" ✅

**Option B: Connect via psql**
```powershell
.\connect-db.ps1
# Then paste the migration SQL
```

### 2. Restart Your Flutter App

After migration is applied:
```powershell
# In Flutter terminal, press 'R' for hot restart
# Or stop and restart:
flutter run
```

### 3. Test Strava Connection

1. Open app in browser/emulator
2. Go to GPS/Strava connection screen
3. Click "Connect to Strava"
4. Authorize on Strava
5. Watch for green notification: "✅ Strava connected successfully!"

### 4. Verify in Production Database

**Check Strava columns exist:**
```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name LIKE '%strava%';
```

**Check your profile has Strava data:**
```sql
SELECT id, email, strava_athlete_id, strava_connected_at 
FROM profiles 
WHERE strava_athlete_id IS NOT NULL;
```

---

## 🔄 Switch Between Production and Local

### Currently Using: PRODUCTION 🌐

**To switch to LOCAL development:**
1. Start local Supabase: `npx supabase start`
2. Edit `lib/main.dart`
3. Comment out PRODUCTION section
4. Uncomment LOCAL section (http://127.0.0.1:54321)
5. Hot restart app

---

## 📊 Access Production Dashboard

```powershell
# Open Supabase Dashboard
Start-Process "https://supabase.com/dashboard/project/xzxnnswggwqtctcgpocr"

# Open SQL Editor
Start-Process "https://supabase.com/dashboard/project/xzxnnswggwqtctcgpocr/sql/new"

# Open Table Editor
Start-Process "https://supabase.com/dashboard/project/xzxnnswggwqtctcgpocr/editor"
```

---

## 🗄️ Connect to Production Database

### Via PowerShell Script
```powershell
.\connect-db.ps1
```

### Via Docker (manual)
```powershell
docker run -it --rm -e PGPASSWORD="Akura@2026$" postgres:16-alpine psql -h db.xzxnnswggwqtctcgpocr.supabase.co -p 5432 -U postgres -d postgres
```

---

## 📝 Migration Status

**Strava Integration Migration:**
- ✅ Applied to LOCAL database (127.0.0.1)
- ⏳ **NEEDS TO BE APPLIED to PRODUCTION** (do this now!)

**File:** `database/migration_strava_integration.sql`

**What it adds:**
- `profiles.strava_access_token` - OAuth access token
- `profiles.strava_refresh_token` - OAuth refresh token
- `profiles.strava_athlete_id` - Strava athlete ID
- `profiles.strava_connected_at` - Connection timestamp
- `profiles.strava_expires_at` - Token expiration
- `workouts.strava_activity_id` - Link workouts to Strava activities

---

## ⚠️ Important Notes

1. **Apply migration BEFORE testing Strava connection**
   - Without the migration, you'll get database errors
   - The Supabase SQL Editor should already be open

2. **Keep credentials secure**
   - Don't commit `.env` files to git
   - Don't share anon keys publicly

3. **Local vs Production**
   - Local: Free, unlimited, offline development
   - Production: Real user data, backed up, requires internet

---

## 🔧 Troubleshooting

**"Column does not exist" error:**
- Migration not applied yet
- Apply migration via SQL Editor

**"Failed to save Strava connection":**
- Check app logs
- Verify user is logged in
- Confirm migration is applied

**Connection timeout:**
- Check internet connection
- Verify Supabase project is active
- Try restarting app

---

**Ready to test!** Apply the migration in the SQL Editor (already open), then restart your Flutter app and connect to Strava. 🚀
