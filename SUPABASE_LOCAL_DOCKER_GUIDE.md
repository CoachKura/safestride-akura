# Supabase Local Development with Docker

This guide helps you run Supabase locally using Docker for development.

## Prerequisites
- Docker Desktop installed and running
- At least 4GB RAM available for Docker

## Quick Start

### 1. Initialize Supabase locally
```powershell
# Initialize Supabase in your project
npx supabase init

# Start local Supabase (all services)
npx supabase start
```

This will start:
- PostgreSQL Database (port 54322)
- Studio Dashboard (port 54323) - http://localhost:54323
- API Gateway (port 54321)
- Auth service
- Storage service
- Realtime service

### 2. Access Local Supabase

After `supabase start` completes, you'll see:
```
API URL: http://localhost:54321
DB URL: postgresql://postgres:postgres@localhost:54322/postgres
Studio URL: http://localhost:54323
```

**Studio Dashboard:** http://localhost:54323
**API URL:** http://localhost:54321
**Database:** localhost:54322

### 3. Update Flutter App Configuration

Update your `.env` file:
```env
# Local Supabase (Development)
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=<anon-key-from-supabase-start-output>

# Production (Comment out during local dev)
# SUPABASE_URL=https://yawxlwcniqfspcgefuro.supabase.co
# SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Or update `lib/main.dart`:
```dart
await Supabase.initialize(
  url: 'http://localhost:54321',  // Local Supabase
  anonKey: 'your-local-anon-key',
);
```

### 4. Run Database Migrations

```powershell
# Apply all migrations to local database
npx supabase db push

# Or apply specific migration file
npx supabase db execute -f database/migration_strava_integration.sql
```

### 5. View Local Database

**Option A: Supabase Studio**
- Open http://localhost:54323
- Click "Table Editor"
- View/edit your tables

**Option B: psql (from your connect-db.ps1)**
```powershell
docker run --rm -it postgres:16-alpine psql -h host.docker.internal -p 54322 -U postgres -d postgres
# Password: postgres
```

**Option C: DBeaver / pgAdmin**
- Host: localhost
- Port: 54322
- Database: postgres
- User: postgres
- Password: postgres

## Common Commands

```powershell
# Start Supabase
npx supabase start

# Stop Supabase (keeps data)
npx supabase stop

# Stop and reset all data
npx supabase stop --no-backup
npx supabase db reset

# View status
npx supabase status

# View logs
npx supabase logs

# Access database
npx supabase db shell
```

## Seed Data (Optional)

Create `supabase/seed.sql`:
```sql
-- Insert test user
INSERT INTO auth.users (id, email) VALUES 
  ('00000000-0000-0000-0000-000000000001', 'test@example.com');

-- Insert test profile
INSERT INTO profiles (id, email) VALUES 
  ('00000000-0000-0000-0000-000000000001', 'test@example.com');
```

Reset with seed:
```powershell
npx supabase db reset
```

## Switching Between Local and Production

### For Local Development:
```powershell
npx supabase start
# Update .env to use localhost:54321
flutter run
```

### For Production Testing:
```powershell
npx supabase stop
# Update .env to use yawxlwcniqfspcgefuro.supabase.co
flutter run
```

## Troubleshooting

**Port Already in Use:**
```powershell
npx supabase stop
docker ps  # Check for running containers
docker stop $(docker ps -aq)  # Stop all containers
npx supabase start
```

**Database Connection Issues:**
- Ensure Docker Desktop is running
- Check ports: 54321, 54322, 54323 are not in use
- Restart Docker Desktop

**Apply Migrations:**
```powershell
# Apply all files in supabase/migrations/
npx supabase db push

# Or manually execute
Get-ChildItem database\*.sql | ForEach-Object {
  npx supabase db execute -f $_.FullName
}
```

## Architecture

Local Supabase runs these Docker containers:
- `supabase-db` - PostgreSQL 15
- `supabase-studio` - Dashboard UI
- `supabase-kong` - API Gateway
- `supabase-auth` - GoTrue auth service
- `supabase-rest` - PostgREST API
- `supabase-realtime` - Realtime subscriptions
- `supabase-storage` - File storage
- `supabase-imgproxy` - Image transformations
- `supabase-meta` - Metadata service
- `supabase-vector` - pgvector for embeddings

## Benefits of Local Development

✅ **Faster:** No network latency
✅ **Free:** No API limits or quotas
✅ **Offline:** Work without internet
✅ **Safe:** Test migrations without affecting production
✅ **Reset:** Easy to reset and start fresh

## Production Deployment

When ready to deploy migrations to production:
```powershell
# Link to production project
npx supabase link --project-ref yawxlwcniqfspcgefuro

# Push migrations to production
npx supabase db push --linked
```
