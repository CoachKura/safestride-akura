# Genspark Coordination Status (SafeStride)

Date: 2026-03-09  
Project path: `C:\safestride\webapp`

## Branch + deployment status
- `production` head: `f645d7d` (pushed)
- `gh-pages` head: `78ff062` (pushed)
- Latest Cloudflare Pages manual deploy: `a8426382`
- Alias URL: `https://production.safestride-akura.pages.dev`

## What is live and verified
- `https://production.safestride-akura.pages.dev/` loads updated nav links for:
  - `/login`
  - `/genspark-import`
- `https://production.safestride-akura.pages.dev/login` returns login page (200)
- `https://production.safestride-akura.pages.dev/genspark-import` returns import page (200)
- `https://production.safestride-akura.pages.dev/signup` returns signup page (200)
- `https://production.safestride-akura.pages.dev/assessment` returns assessment page (200)
- `https://production.safestride-akura.pages.dev/strava-callback` returns callback page (200)
- `https://www.akura.in/login.html` returns updated login page (200)
- `https://www.akura.in/genspark-import.html` returns updated import page (200)
- `https://www.akura.in/signup.html` returns signup page (200)
- `https://www.akura.in/assessment.html` returns assessment page (200)
- `https://www.akura.in/strava-callback.html` returns callback page (200)

## Config normalization completed
Supabase frontend runtime endpoints were aligned to the resolvable production project:
- URL: `https://bdisppaxbvygsspcuymb.supabase.co`
- Publishable key: `sb_publishable_BBjk8yeyQ2jgh5iFiQINUQ_mwU2FMnk`

Files updated:
- `login.html`
- `genspark-import.html`
- `public/login.html`
- `public/genspark-import.html`
- `public/signup.html`
- `public/onboarding.html`
- `public/index.html` (extensionless route links)

Additional hardening completed:
- Removed exposed Strava client secret from frontend (`public/onboarding.html`)
- Added explicit 404/401 import error messaging in `genspark-import` UI for safer production behavior

## Remaining blocker (critical)
The new edge function is not deployed yet in Supabase production:
- Endpoint: `https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/import-genspark-data`
- Current status: `404 Not Found`

Local environment blocker:
- `supabase functions deploy ...` cannot run because no Supabase CLI access token is configured on this machine.

## Immediate next command once token is available
```bash
supabase functions deploy import-genspark-data --project-ref bdisppaxbvygsspcuymb
```

Then verify:
```bash
curl -i -X OPTIONS "https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/import-genspark-data"
```

