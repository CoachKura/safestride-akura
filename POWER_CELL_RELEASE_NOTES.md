# Power Cell Training System Release Notes

## Release
- Version: 1.0.0
- Date: 2026-03-05
- Status: Production Live

## Repository Commits
- Root repository (`C:\safestride`, branch `main`): `b7fce26`
- Frontend repository (`C:\safestride\webapp`, branch `production`): `37ff246`

## Delivered Components
- Database migration: `supabase/migrations/20260305000000_power_cells.sql`
- Canonical migration: `database_canonical/migrations/006_power_cells.sql`
- Seed data: `supabase/seed.sql` (7 protocols, 26 power cells)
- Edge function: `supabase/functions/power-cells-get/index.ts`
- Frontend page: `webapp/public/power-cells.html`
- Frontend manager: `webapp/public/js/power-cell-manager.js`
- Frontend styles: `webapp/public/css/power-cells.css`
- Smoke test: `test-power-cells.ps1`

## API Contract
- Endpoint: `POST /functions/v1/power-cells-get`
- Body: `{ "user_id": "<uuid>" }`
- Response fields:
  - `available_power_cells`
  - `user_history`
  - `user_aisri`
  - `protocols`

## Validation Summary
- AISRI 40 scenario: 7 available cells
- AISRI 70 scenario: 24 available cells
- History scenario: required history fields present
- Local smoke test script passed

## Notes
- Production currently uses function-level JWT validation as the active auth enforcement mechanism.
- Validation scripts are archived under `scripts/archive/`.
