# ⚠️ CRITICAL: Supabase Service Role Key Issue

## Problem
The SUPABASE_SERVICE_ROLE_KEY in .env is currently set to the ANON key.

Current value (decoded JWT payload):
`
{
  'iss': 'supabase',
  'ref': 'bdisppaxbvygsspcuymb',
  'role': 'anon',  ❌ WRONG - Should be 'service_role'
  'iat': 1771246844,
  'exp': 2086822844
}
`

## Required Fix
1. Go to Supabase Dashboard: https://app.supabase.com/project/bdisppaxbvygsspcuymb/settings/api
2. Copy the 'service_role' key (not the 'anon' key)
3. Update ai_agents/.env:
   `
   SUPABASE_SERVICE_ROLE_KEY=<actual_service_role_key>
   `

## Security Note
- Service role key bypasses RLS (Row Level Security)
- Only use server-side, never expose to client
- Grants admin access to all tables

## Verification
Run: python ai_agents/env_validator.py
Should show: ✅ SUPABASE_SERVICE_ROLE_KEY doesn't match ANON_KEY
