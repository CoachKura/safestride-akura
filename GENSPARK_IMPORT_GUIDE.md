# Genspark Import Guide

This project now includes a dedicated import pipeline for Genspark exports.

## Current production status (2026-03-09)
- Frontend import UI is live on:
  - `https://production.safestride-akura.pages.dev/genspark-import`
  - `https://www.akura.in/genspark-import.html`
- Frontend config is aligned to:
  - `https://bdisppaxbvygsspcuymb.supabase.co`
  - `sb_publishable_BBjk8yeyQ2jgh5iFiQINUQ_mwU2FMnk`
- Backend blocker:
  - `import-genspark-data` function is not deployed in production yet (`404`).
  - Deploy requires Supabase CLI login/token on the deployment machine.
- Frontend safeguard:
  - Import page now shows an explicit deploy-needed message when function endpoint returns `404`.

## Added components
- UI page: `/genspark-import.html`
- Edge Function: `supabase/functions/import-genspark-data/index.ts`

## What it imports
- `strava_activities` (upsert by `strava_activity_id`)
- `aisri_scores` (insert latest parsed score, if present)

## One-shot complete mode (new)
By default, the function runs in complete mode (`completeProcess: true`):
- Imports Strava activities
- Uses AISRI from payload if present
- Otherwise derives AISRI from imported activities
- Best-effort updates:
  - `profiles.strava_connected = true`
  - `athlete_onboarding_status` advanced to active training

Optional:
- `triggerWorkflow: true` to invoke `athlete-workflow` (requires valid `userId` + `userEmail`)

## Supported input modes
1. `payload` JSON (recommended)
2. `sourceUrl` that returns JSON (useful when Genspark provides direct export links)

## Deploy the function
```bash
supabase functions deploy import-genspark-data --project-ref bdisppaxbvygsspcuymb
```

Optional hardening:
```bash
supabase secrets set GENSPARK_IMPORT_KEY=your_strong_secret
```

If `GENSPARK_IMPORT_KEY` is set, the client must pass `x-import-key`.

## Test with dry run
```bash
curl -X POST "https://<PROJECT_REF>.supabase.co/functions/v1/import-genspark-data" \
  -H "Content-Type: application/json" \
  -H "apikey: <ANON_KEY>" \
  -H "Authorization: Bearer <ANON_KEY>" \
  -d '{
    "athleteId": "ATH0001",
    "userId": "3e4c11be-0e25-4e52-a9c4-0f6f3f40d88d",
    "userEmail": "athlete@example.com",
    "fullName": "Athlete Name",
    "payload": {
      "athleteId": "ATH0001",
      "activities": [
        { "id": 123456789, "distance": 5000, "moving_time": 1500, "start_date": "2026-03-09T05:30:00Z" }
      ],
      "aisriScore": 67
    },
    "dryRun": true,
    "completeProcess": true,
    "triggerWorkflow": false
  }'
```

## Genspark coordination workflow
1. In Genspark chat, request a machine-readable JSON export.
2. Paste that JSON into `/genspark-import.html`.
3. Click `Run Dry-Run` first.
4. If mapping looks correct, click `Run Complete One-Shot Import`.

## Current limitation
The direct agent page URL can be blocked by Cloudflare challenge. In that case, use exported JSON from the agent rather than page scraping.
