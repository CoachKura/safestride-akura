# SafeStride Supabase CLI Quick Reference
# =======================================

# AUTHENTICATION (run once per session)
$env:SUPABASE_ACCESS_TOKEN = "sbp_68f9e6c4ee5e97d182e78b383244dc14a7ba3e59"

# DAILY COMMANDS
# --------------

# Create new migration
npx supabase migration new add_feature_name

# Push migrations to production
npx supabase db push

# Pull schema from production
npx supabase db pull

# Open SQL shell (interactive)
npx supabase db shell

# Run SQL query directly
npx supabase db execute --sql "SELECT COUNT(*) FROM profiles;"

# Run SQL file
npx supabase db execute --file database/query.sql

# MIGRATION MANAGEMENT
# --------------------

# List migrations
npx supabase migration list

# Repair migration history
npx supabase migration repair --status applied VERSION

# Check project status
npx supabase status

# DATABASE BACKUP (your existing script)
# --------------------------------------
.\backup-database.ps1

# VS CODE TASKS
# -------------
# Press: Ctrl+Shift+P  "Tasks: Run Task"  Choose task:
# - Supabase: Create Migration
# - Supabase: Push Migrations
# - Supabase: SQL Shell
# - Backup: Run Database Backup
