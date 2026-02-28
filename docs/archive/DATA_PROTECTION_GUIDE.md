#  SafeStride - Complete Backup & Data Protection Strategy

##  Why Data Was Lost

**Supabase Free Tier Limitations:**
- Projects **pause after 7 days** of inactivity
- Paused projects **delete data after 1 week**
- No automatic backups on free tier
- No point-in-time recovery

##  SOLUTION: 3-Layer Protection

### 1.  PRIMARY: Use Local Docker Supabase (RECOMMENDED)
**Status:**  Already running at http://127.0.0.1:54321

**Benefits:**
-  100% data ownership - never deleted
-  Works offline
-  Free forever
-  Fast development
-  Full control

**Your app is currently configured for PRODUCTION.**
**Switch to LOCAL for development:**

\\\powershell
# Edit lib/main.dart - comment out PRODUCTION, uncomment LOCAL
# Then restart app
flutter run
\\\

### 2.  Daily Automated Backups

**Run backup anytime:**
\\\powershell
.\backup-database.ps1
\\\

**Set up daily backups (Windows Task Scheduler):**
\\\powershell
# Create scheduled task to run daily at 2 AM
\ schtasks /create /tn "SafeStride Backup" /tr "powershell.exe -File C:\safestride\backup-database.ps1" /sc daily /st 02:00
\\\

**Backups saved to:** \database/backups/\
- Keeps last 7 days
- Schema + Data + Full backup
- Ready to restore anytime

### 3.  Git-Based Backups

**Export schema to git (after changes):**
\\\powershell
# Export current local schema
docker exec supabase_db_safestride pg_dump -U postgres -d postgres --schema-only > database/schema_latest.sql

# Commit to git
git add database/schema_latest.sql
git commit -m "Backup: Updated schema"
git push
\\\

##  How to Restore Data

### Restore to Local:
\\\powershell
.\restore-database.ps1 -BackupFile "database/backups/full_backup_2026-02-12_081449.sql" -Target local
\\\

### Restore to Production (careful!):
\\\powershell
.\restore-database.ps1 -BackupFile "database/backups/full_backup_2026-02-12_081449.sql" -Target production
\\\

##  Daily Workflow (RECOMMENDED)

### For Development:
1. **Use LOCAL Supabase** (already running)
   - Start: \
px supabase start\
   - Stop: \
px supabase stop\
   - Studio: http://127.0.0.1:54323

2. **Run app with local database:**
   \\\dart
   // In lib/main.dart - use LOCAL config:
   await Supabase.initialize(
     url: 'http://127.0.0.1:54321',
     anonKey: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
   );
   \\\

3. **Apply migrations to local:**
   \\\powershell
   Get-Content database/fix_missing_columns.sql | docker exec -i supabase_db_safestride psql -U postgres -d postgres
   \\\

### For Production Deploy:
1. **Backup production first:**
   \\\powershell
   .\backup-database.ps1
   \\\

2. **Test locally, then push to production**

3. **Keep production active** (login once per week to prevent pause)

##  Emergency Recovery

**If Supabase deletes data again:**

1. **Restore from latest backup:**
   \\\powershell
   # List backups
   Get-ChildItem database/backups -Filter "full_backup_*.sql" | Sort-Object LastWriteTime -Descending

   # Restore to production
   .\restore-database.ps1 -BackupFile "database/backups/full_backup_LATEST.sql" -Target production
   \\\

2. **Or apply all migrations fresh:**
   \\\powershell
   # In Supabase SQL Editor, run:
   Get-Content database/MASTER_UNIFIED_MIGRATION.sql
   Get-Content database/fix_missing_columns.sql
   Get-Content database/fix_signup_trigger.sql
   \\\

##  Best Practices

 **DO:**
- Use local Docker for daily development
- Run backups before major changes
- Commit schema changes to git
- Keep production database active (login weekly)

 **DON'T:**
- Rely solely on Supabase free tier for important data
- Go more than 7 days without accessing production
- Skip backups before big changes

##  Current Status

-  Local Supabase: **RUNNING**
-  Backup script: **READY**
-  Restore script: **READY**  
-  App config: **Using PRODUCTION** (switch to LOCAL recommended)
-  First backup: **COMPLETE** (database/backups/)

##  Quick Commands

\\\powershell
# Start local Supabase
npx supabase start

# Backup production
.\backup-database.ps1

# Open local Studio
Start-Process http://127.0.0.1:54323

# Switch app to local (edit main.dart, then):
flutter run

# Apply migration to local
Get-Content database/MIGRATION_FILE.sql | docker exec -i supabase_db_safestride psql -U postgres -d postgres
\\\

---

** RECOMMENDED NEXT STEP:**
Switch your app to use LOCAL Supabase for development. This prevents data loss and gives you full control!
