#!/bin/bash
# Apply modern SafeStride schema migration

SUPABASE_URL="https://bdisppaxbvygsspcuymb.supabase.co"
SUPABASE_DB_PASSWORD="YourPassword123!"  # You'll need to provide this

# Apply migration using Supabase CLI
npx supabase db push --db-url "postgresql://postgres:${SUPABASE_DB_PASSWORD}@db.bdisppaxbvygsspcuymb.supabase.co:5432/postgres" --file migrations/003_modern_safestride_schema.sql

echo "✅ Migration applied successfully!"
