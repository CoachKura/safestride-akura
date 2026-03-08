# Production Development A to F

Created: 2026-03-06
Workspace: `C:\safestride\webapp`

## Part A: Power Cells Enhancement (3 hours)

### A.1 Enhanced Power Cell UI

Files:
- `public/power-cells.html`
- `public/css/power-cells-enhanced.css`
- `public/css/power-cell-modals.css`

Expected output:
- Power Cell card grid with cleaner visual hierarchy
- KPI strip (`Total`, `Available`, `Scheduled`)
- Details modal shell
- Schedule modal shell
- Toast notifications container

### A.2 Workout Scheduling System

File:
- `public/js/power-cell-scheduler.js`

Expected output:
- AISRI-based lock and availability states
- Local schedule persistence (`localStorage`)
- Optional Supabase sync when authenticated
- Card state tags (`available`, `locked`, `scheduled`)

### A.3 Database Migration

File:
- `supabase/migrations/20260306000000_power_cell_schedule.sql`

Expected output:
- `public.power_cell_schedules` table
- Trigger-based `updated_at` maintenance
- User scoped RLS policies by `auth.uid()`
- User/date index

### A.4 Testing Checklist

- [ ] `public/power-cells.html` opens without console errors
- [ ] Details modal opens and closes from all cards
- [ ] Schedule modal saves date/time/notes
- [ ] Scheduled state persists after page refresh
- [ ] Unauthenticated mode still saves locally and shows fallback toast

### Part A Commit Guidance

Suggested commit message:
- `feat(part-a): enhance power cells UI and scheduling flow`

## Part B: Athlete Onboarding Flow (1 hour)

### B.1 Onboarding Welcome Screen

Goal:
- Add a 5-step experience that frames AISRI, training safety, and value quickly.

### B.2 Connect to Signup/Login Flow

Goal:
- Route first-time users through onboarding before dashboard access.

### B.3 Part B Testing

Checklist:
- [ ] New users see onboarding flow
- [ ] Returning users skip onboarding
- [ ] Progress indicator works across steps
- [ ] CTA routes to signup/login correctly

Suggested files:
- `public/onboarding.html`
- `public/js/onboarding-wizard.js`
- `public/css/onboarding-wizard.css`

## Part C: Dashboard Improvements (2 hours)

Focus:
- Weekly summaries, risk signals, trend charting, and recent workout context.

## Part D: Mobile App Features (1.5 hours)

Focus:
- PWA manifest, service worker baseline, offline fallback, install prompt.

## Part E: Performance and Polish (1.5 hours)

Focus:
- Lazy loading, skeleton states, resilient async error handling, and UX polish.

## Part F: Testing and Quality (1 hour)

Focus:
- Cross-browser checks, mobile checks, UAT scripts, and release sign-off.
