# 🐳 Local Supabase - Quick Reference

## Current Setup: LOCAL DEVELOPMENT MODE ✅

Your app is now connected to **local Supabase running in Docker**.

---

## 🚀 Quick Commands

### Start/Stop Local Supabase
```powershell
# Start all services
npx supabase start

# Stop services (keeps data)
npx supabase stop

# Stop and delete all data
npx supabase stop --no-backup

# Check status
npx supabase status
```

### Access Services
- **Studio Dashboard:** http://127.0.0.1:54323
- **API URL:** http://127.0.0.1:54321
- **Database:** postgresql://postgres:postgres@127.0.0.1:54322/postgres

### Apply Database Migrations
```powershell
# Apply a specific migration
Get-Content database/migration_name.sql | docker exec -i supabase_db_safestride psql -U postgres -d postgres

# Apply all migrations in database/ folder
Get-ChildItem database\migration_*.sql | ForEach-Object {
    Write-Host "Applying $($_.Name)..." -ForegroundColor Cyan
    Get-Content $_.FullName | docker exec -i supabase_db_safestride psql -U postgres -d postgres
}
```

### Check Database Tables
```powershell
# Run query from file
Get-Content database/check_strava_columns.sql | docker exec -i supabase_db_safestride psql -U postgres -d postgres

# Interactive psql shell
docker exec -it supabase_db_safestride psql -U postgres -d postgres
```

---

## 🔄 Switch Between Local and Production

### Currently Using: LOCAL 🐳

**To switch to PRODUCTION:**
1. Open `lib/main.dart`
2. Comment out the LOCAL section
3. Uncomment the PRODUCTION section
4. Hot restart your app

```dart
// Comment these lines (LOCAL):
// await Supabase.initialize(
//   url: 'http://127.0.0.1:54321',
//   anonKey: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
// );

// Uncomment these lines (PRODUCTION):
await Supabase.initialize(
  url: 'https://yawxlwcniqfspcgefuro.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
);
```

---

## 📊 View Your Data

### Option 1: Supabase Studio (Easiest)
```powershell
Start-Process "http://127.0.0.1:54323"
```
Click "Table Editor" → View all tables

### Option 2: SQL Editor in Studio
```powershell
Start-Process "http://127.0.0.1:54323"
```
Click "SQL Editor" → Run custom queries

### Option 3: psql Command Line
```powershell
docker exec -it supabase_db_safestride psql -U postgres -d postgres
```

Then run SQL:
```sql
-- List all tables
\dt

-- Check Strava columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name LIKE '%strava%';

-- View profile data
SELECT id, email, strava_athlete_id, strava_connected_at FROM profiles;
```

---

## ✅ Testing Strava Integration Locally

1. **Start Supabase:**
   ```powershell
   npx supabase start
   ```

2. **Run your Flutter app:**
   ```powershell
   flutter run
   ```

3. **Test Strava connection:**
   - Go to GPS/Strava screen
   - Click "Connect to Strava"
   - Authorize on Strava
   - Watch for green success notification

4. **Verify in database:**
   ```powershell
   Start-Process "http://127.0.0.1:54323"
   ```
   - Open "Table Editor"
   - Select "profiles" table
   - Check for populated Strava columns

---

## 🛠️ Troubleshooting

### "Connection refused" or "Cannot connect"
```powershell
# Restart Docker
npx supabase stop
docker ps  # Should show no supabase containers
npx supabase start
```

### Ports already in use
```powershell
# Check what's using the ports
netstat -ano | findstr "54321 54322 54323"

# Stop all Docker containers
docker stop $(docker ps -aq)

# Start Supabase again
npx supabase start
```

### Reset database to fresh state
```powershell
npx supabase db reset
```

### Apply latest migrations
```powershell
Get-ChildItem database\migration_*.sql | ForEach-Object {
    Write-Host "Applying $($_.Name)..." -ForegroundColor Cyan
    Get-Content $_.FullName | docker exec -i supabase_db_safestride psql -U postgres -d postgres
}
```

---

## 💡 Benefits You Now Have

✅ **Fast Development** - No network latency
✅ **Unlimited API Calls** - No rate limits
✅ **Offline Work** - No internet needed
✅ **Safe Testing** - Production data untouched
✅ **Easy Reset** - Fresh database anytime
✅ **Free Forever** - No cloud costs

---

## 📦 What's Running?

```powershell
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

You should see:
- `supabase_db_safestride` - PostgreSQL 15
- `supabase_studio_safestride` - Studio Dashboard
- `supabase_kong_safestride` - API Gateway
- `supabase_auth_safestride` - Authentication
- `supabase_rest_safestride` - REST API
- `supabase_realtime_safestride` - Realtime subscriptions
- `supabase_storage_safestride` - File storage
- `supabase_meta_safestride` - Migrations

---

**Need help?** Check [SUPABASE_LOCAL_DOCKER_GUIDE.md](./SUPABASE_LOCAL_DOCKER_GUIDE.md) for detailed documentation.
