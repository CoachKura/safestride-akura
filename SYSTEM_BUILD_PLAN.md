# 🏗️ SAFESTRIDE SYSTEM BUILD PLAN

## Phase 1: Foundation (Week 1) ✅ STARTING NOW

### 1. Enhanced Home Page ⏳ IN PROGRESS
**Shows complete user journey from discovery to athlete success**

Components:
- [x] Hero with Rajesh transformation
- [ ] Live community feed (like Strava)
- [ ] AISRI system explanation with interactive demo
- [ ] Complete journey visualization (onboarding → training → success)
- [ ] Safety gates explanation
- [ ] Coach oversight showcase
- [ ] Before/After comparison slider
- [ ] Get Started CTA

Files to create:
- `/public/home-enhanced.html` (new comprehensive home page)
- `/public/js/community-feed.js` (fetch recent activities)
- `/public/js/aisri-demo.js` (interactive AISRI calculator)

---

## Phase 2: Core Systems (Week 1-2)

### 2. Strava Integration System 🔴 HIGH PRIORITY
**OAuth + Activity Sync + Running Pillar Calculation**

Files to create:
- `/src/api/strava-auth.js` (OAuth flow)
- `/src/api/strava-webhook.js` (receive activity updates)
- `/src/services/running-pillar-calculator.js` (analyze activities)
- `/public/strava-callback.html` (OAuth redirect)

Database tables needed:
- `strava_connections` (athlete_id, access_token, refresh_token, expires_at)
- `synced_activities` (activity_id, athlete_id, distance, time, pace, hr, zones)

### 3. AISRI Calculation Engine 🔴 HIGH PRIORITY
**6-Pillar Scoring Algorithm**

Files to create:
- `/src/services/aisri-calculator.js` (main calculation logic)
- `/src/services/pillar-calculators/` (individual pillar logic)
  - `mobility-calculator.js`
  - `strength-calculator.js`
  - `mental-calculator.js`
  - `recovery-calculator.js`
  - `prevention-calculator.js`
  - `performance-calculator.js`

Algorithms:
```javascript
AISRI Score = (
  Mobility * 0.15 +
  Strength * 0.15 +
  Mental * 0.10 +
  Recovery * 0.15 +
  Prevention * 0.20 +
  Performance * 0.25
)

Risk Category:
- 0-39: HIGH RISK (red)
- 40-59: MODERATE RISK (orange)
- 60-79: LOW RISK (yellow)
- 80-100: OPTIMAL (green)
```

### 4. Safety Gate System 🔴 HIGH PRIORITY
**Zone Permissions + Real-time Monitoring**

Files to create:
- `/src/services/safety-gate-engine.js` (zone permission logic)
- `/src/services/activity-validator.js` (check if workout is safe)
- `/src/api/safety-check.js` (API endpoint for real-time checks)

Logic:
```javascript
Zone Permissions by AISRI:
- AISRI < 40: Zone 1 only
- AISRI 40-59: Zone 1-2
- AISRI 60-79: Zone 1-3
- AISRI 80-89: Zone 1-4
- AISRI 90-100: Zone 1-5

Safety Check on Activity:
1. Get athlete's AISRI score
2. Get allowed zones
3. Check activity's avg HR → determine actual zone
4. IF actual zone > allowed zone:
   - Flag activity as "unsafe"
   - Alert coach
   - Send warning to athlete
   - Adjust next week's plan
```

---

## Phase 3: Training System (Week 2-3)

### 5. Dynamic Training Plan Generator 🔴 HIGH PRIORITY
**12-Week Plans with 7 Protocols**

Files to create:
- `/src/services/plan-generator.js` (generate 12-week plan)
- `/src/services/protocol-library.js` (7 protocol definitions)
- `/src/services/plan-adjuster.js` (adapt plan based on performance)

Database tables:
- `training_plans` (athlete_id, phase, start_date, end_date, goal_race)
- `daily_workouts` (plan_id, date, protocol, zone, duration, distance, completed)

7 Core Protocols:
```javascript
1. START: Easy recovery (Zone 1, 30-40 min)
2. ENGINE: Aerobic base (Zone 2, 40-60 min)
3. STRENGTH: Gym/bodyweight (2-3 sets, 8-12 reps)
4. OXYGEN: VO2 max intervals (Zone 4-5, 3-5 min intervals)
5. POWER: Hill sprints (Zone 5, 30-60 sec sprints)
6. ZONES: Tempo/threshold (Zone 3, 20-30 min)
7. LONG RUN: Endurance (Zone 2, 60-120 min)
```

### 6. Enhanced Athlete Dashboard 🔴 HIGH PRIORITY
**Today's Workout + Progress Tracking**

Files to create:
- `/public/athlete-dashboard-v2.html` (enhanced dashboard)
- `/public/js/dashboard-controller.js` (fetch and display data)
- `/public/js/workout-tracker.js` (track today's workout)

Components:
- Today's Workout Card (protocol, zone, duration, instructions)
- AISRI Score Display (current score + trend)
- Weekly Progress (7-day workout completion)
- Zone Status (unlocked/locked zones)
- Safety Alerts (warnings if zone exceeded)
- Upcoming Workouts (next 7 days)

---

## Phase 4: Coach System (Week 3-4)

### 7. Coach Dashboard 🔴 HIGH PRIORITY
**At-Risk Monitoring + Zone Approvals**

Files to create:
- `/public/coach-dashboard.html` (main coach view)
- `/public/js/coach-controller.js` (fetch athlete data)
- `/src/api/coach-actions.js` (override, message, approve)

Components:
- At-Risk Athletes Section (red/yellow/orange flags)
- Zone Unlock Requests (approve/deny)
- Athlete List (searchable, filterable by risk)
- Individual Athlete View (detailed history)
- Override Training Plan (edit workouts)
- Send Message (direct communication)
- Weekly Reports (summary statistics)

Coach Actions:
```javascript
1. View all athletes (read-only)
2. Override training plans (reduce volume, add rest)
3. Send messages (warnings, encouragement)
4. Approve zone unlock requests
5. Generate reports (weekly summary, progress)
6. Lock/unlock zones manually
7. Schedule 1-on-1 calls
```

---

## Phase 5: Re-evaluation System (Week 4)

### 8. Monthly Re-evaluation System 🟡 MEDIUM PRIORITY
**Automated Reminders + Score Recalculation**

Files to create:
- `/src/services/evaluation-scheduler.js` (automated reminders)
- `/public/athlete-evaluation-v2.html` (enhanced assessment form)
- `/src/api/evaluation-submit.js` (process new scores)

Flow:
```
Day 1 of month:
1. System sends reminder email/notification
2. Athlete opens evaluation form
3. Completes physical tests (photos/videos)
4. Completes questionnaires (mental, recovery)
5. System recalculates AISRI score
6. Compares to previous month
7. Generates zone unlock request (if improved)
8. Updates training plan
9. Sends congratulations message
```

### 9. Activity Sync & Analysis 🟡 MEDIUM PRIORITY
**Webhook + Zone Checking**

Files to create:
- `/src/api/strava-webhook-handler.js` (receive events)
- `/src/services/activity-analyzer.js` (analyze workout)
- `/src/services/training-load-calculator.js` (TSS/ATL/CTL)

Webhook flow:
```
1. Athlete completes workout on Garmin
2. Garmin syncs to Strava
3. Strava sends webhook to SafeStride
4. SafeStride fetches full activity details
5. Analyzes: zone adherence, pace, HR
6. Calculates training load
7. Updates Running Pillar score
8. Checks safety gates
9. Alerts coach if needed
10. Updates dashboard
```

### 10. Zone Unlock Request System 🟡 MEDIUM PRIORITY
**Request Generation + Approval Workflow**

Files to create:
- `/src/services/unlock-request-generator.js` (create requests)
- `/public/zone-unlock-request.html` (athlete view)
- `/src/api/coach-approve-zone.js` (approval endpoint)

Flow:
```
Athlete side:
1. AISRI improves from 58 → 72
2. System generates unlock request for Zone 4
3. Athlete sees: "Zone 4 pending coach approval ⏳"
4. Receives notification when approved

Coach side:
1. Sees unlock request in dashboard
2. Reviews athlete's progress
3. Checks workout adherence
4. Clicks "Approve" or "Deny"
5. Adds personal message
6. System updates athlete's permissions
```

---

## Phase 6: Advanced Features (Week 5+)

### 11. Community Feed (Strava-style)
- Recent activities from all athletes
- Kudos/comments system
- Leaderboards (most improved AISRI)
- Challenges (e.g., "30 days injury-free")

### 12. Notifications System
- Email notifications (reminders, alerts)
- In-app notifications (zone exceeded, workout due)
- Push notifications (mobile app future)

### 13. Reports & Analytics
- Coach weekly report (PDF export)
- Athlete progress report (monthly summary)
- System-wide statistics (injury prevention rate)

### 14. Mobile App Preparation
- Progressive Web App (PWA) setup
- Offline support
- Mobile-optimized dashboards

---

## 🎯 BUILD ORDER (Priority)

### Week 1 (Now!)
1. ✅ Enhanced Home Page (showing complete journey)
2. ⏳ Strava Integration (OAuth + activity fetch)
3. ⏳ AISRI Calculator (6-pillar algorithm)

### Week 2
4. ⏳ Safety Gate System (zone permissions)
5. ⏳ Training Plan Generator (12-week plans)
6. ⏳ Enhanced Athlete Dashboard (today's workout)

### Week 3
7. ⏳ Coach Dashboard (at-risk monitoring)
8. ⏳ Activity Sync & Analysis (webhook handler)

### Week 4
9. ⏳ Monthly Re-evaluation (automated system)
10. ⏳ Zone Unlock Requests (approval workflow)

### Week 5+
11. ⏳ Community Feed
12. ⏳ Notifications System
13. ⏳ Reports & Analytics

---

## 📊 SUCCESS METRICS

After Phase 1-5 completion, we'll have:
- ✅ Complete onboarding flow (4 steps)
- ✅ Strava integration (automatic activity sync)
- ✅ AISRI scoring (6 pillars)
- ✅ Safety gates (zone blocking)
- ✅ Dynamic training plans (7 protocols)
- ✅ Athlete dashboard (today's workout)
- ✅ Coach dashboard (at-risk alerts)
- ✅ Monthly re-evaluation (automated)
- ✅ Zone unlock system (approval workflow)

**Result**: Full SafeStride system operational! 🚀

---

## 🔧 TECHNOLOGY STACK

### Frontend
- HTML5 + CSS3 (TailwindCSS via CDN)
- Vanilla JavaScript (no framework overhead)
- Chart.js (AISRI radar charts)
- Font Awesome (icons)

### Backend (Cloudflare Workers + Hono)
- Hono framework (lightweight routing)
- Cloudflare D1 (SQLite database)
- Cloudflare KV (session storage)
- Cloudflare R2 (media uploads)

### Integrations
- Strava API (OAuth + Webhooks)
- Garmin Connect (future)
- Email (Cloudflare Email Workers)

### Deployment
- Cloudflare Pages (frontend)
- Cloudflare Workers (backend APIs)
- GitHub (version control)
- Wrangler CLI (deployment)

---

**Status**: Phase 1 Starting NOW! 🚀
**Current Task**: Building Enhanced Home Page with complete user journey
**ETA**: 1-2 hours for home page, then move to Strava integration

Coach Kura, I'm starting with the home page that shows the COMPLETE PROCESS! 💪
