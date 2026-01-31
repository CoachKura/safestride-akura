# 🎯 Akura SafeStride - Complete Implementation Plan

**Last Updated**: January 31, 2026  
**Status**: Phase 1 In Progress  
**Target Completion**: March 15, 2026

---

## 📊 Current Status

### ✅ Completed Features
- ✅ User Authentication (Supabase Auth)
- ✅ Assessment Intake (9-step form with AIFRI calculation)
- ✅ Athlete Dashboard Pro (AIFRI score, streak, today's workout)
- ✅ Weekly Mileage Card (real-time tracking from activity_logs)
- ✅ Total Monthly Distance Card (purple gradient, clickable toast)
- ✅ Track Workout Page (RPE, pain, sleep, nutrition logging)
- ✅ Database Schema (7 tables in Supabase)
- ✅ VS Code Workspace (12 one-click tasks)
- ✅ GitHub Copilot Integration (complete project context)

### 🔄 In Progress
- 🔄 Athlete Dashboard Completion (injury timeline, workout history)

### ⏳ Pending
- ⏳ Strava API Integration
- ⏳ Garmin Connect Integration
- ⏳ Coach Dashboard
- ⏳ Push Notifications
- ⏳ Data Export Features
- ⏳ Mobile PWA Version
- ⏳ Production Deployment

---

## 🗺️ Implementation Phases

### **Phase 1: Complete Athlete Dashboard** (Week 1-2)
**Priority**: HIGH  
**Status**: IN PROGRESS

#### 1.1 Dashboard Enhancements
- [ ] **Injury Timeline** - Visual timeline of past and active injuries
- [ ] **Workout History** - Scrollable list of last 30 days with filters
- [ ] **Profile Settings** - Edit name, email, photo, weekly goals
- [ ] **6-Pillar Deep Dive** - Detailed breakdown of each pillar score
- [ ] **Assessment History** - View past AIFRI assessments with trends

#### 1.2 Data Visualization
- [ ] **Weekly Distance Chart** - Line chart showing last 4 weeks
- [ ] **RPE Trend Chart** - Line chart showing RPE over time
- [ ] **Injury Heat Map** - Body diagram showing injury hotspots
- [ ] **Training Load Chart** - Acute:Chronic Workload Ratio

#### 1.3 Quick Actions
- [ ] **Quick Log Workout** - Modal form for rapid workout entry
- [ ] **Quick Report Injury** - Fast injury reporting with body diagram
- [ ] **Quick Assessment** - Simplified AIFRI check-in (5 questions)

**Deliverables**:
- Enhanced athlete-dashboard-pro.html with new sections
- New JavaScript modules: injury-timeline.js, workout-history.js
- Updated CSS for new components
- Integration with existing Supabase tables

**Estimated Time**: 8-10 days  
**Files to Modify**: athlete-dashboard-pro.html, athlete-dashboard.js, dashboard.css

---

### **Phase 2: Strava Integration** (Week 3-4) ⭐
**Priority**: HIGH  
**Status**: PENDING

#### 2.1 Strava OAuth Setup
- [ ] Register Strava API application (get client_id & client_secret)
- [ ] Create OAuth callback route in Hono backend
- [ ] Store Strava tokens in Supabase (profiles table: strava_access_token, strava_refresh_token, strava_athlete_id)
- [ ] Implement token refresh logic (expires every 6 hours)

#### 2.2 Strava Activity Sync
- [ ] **Manual Sync Button** - "Sync from Strava" button on dashboard
- [ ] **Auto Sync** - Background sync every 6 hours (Cloudflare Cron)
- [ ] **Activity Mapping**:
  - Strava `Run` → activity_logs (distance_km, duration_minutes, activity_date)
  - Extract: moving_time, average_speed, elevation_gain
  - Calculate RPE from: average_heartrate, suffer_score
- [ ] **Duplicate Detection** - Check activity_date + distance_km to avoid duplicates

#### 2.3 Strava Features
- [ ] **Connect Strava Card** - Dashboard card showing connection status
- [ ] **Recent Activities** - Display last 5 Strava activities with sync button
- [ ] **Activity Details** - Modal showing full Strava activity data
- [ ] **Disconnect Option** - Revoke Strava access

**Technical Stack**:
```typescript
// Hono API Routes
POST /api/strava/oauth/authorize  // Redirect to Strava OAuth
GET /api/strava/oauth/callback    // Handle OAuth callback
POST /api/strava/sync             // Manual sync activities
GET /api/strava/activities        // Get recent Strava activities
DELETE /api/strava/disconnect     // Revoke access

// Supabase Schema Changes
ALTER TABLE profiles ADD COLUMN strava_access_token TEXT;
ALTER TABLE profiles ADD COLUMN strava_refresh_token TEXT;
ALTER TABLE profiles ADD COLUMN strava_athlete_id BIGINT;
ALTER TABLE profiles ADD COLUMN strava_connected_at TIMESTAMP;

ALTER TABLE activity_logs ADD COLUMN strava_activity_id BIGINT;
ALTER TABLE activity_logs ADD COLUMN source TEXT DEFAULT 'manual';
```

**Strava API Endpoints**:
- `GET /athlete` - Get authenticated athlete
- `GET /athlete/activities` - List activities (paginated)
- `GET /activities/:id` - Get activity details
- `POST /oauth/token` - Exchange authorization code
- `POST /oauth/token` - Refresh access token

**Deliverables**:
- Hono backend routes for Strava OAuth and sync
- Frontend Strava connection UI (dashboard card + settings)
- Background sync worker (Cloudflare Cron)
- Documentation for Strava setup

**Estimated Time**: 10-12 days  
**Files to Create**: api/strava.ts, frontend/strava-connect.js  
**Files to Modify**: athlete-dashboard-pro.html, wrangler.jsonc (cron)

---

### **Phase 3: Garmin Connect Integration** (Week 5-6)
**Priority**: MEDIUM  
**Status**: PENDING

#### 3.1 Garmin OAuth Setup
- [ ] Register Garmin Connect API application
- [ ] Implement OAuth 1.0a flow (Garmin uses OAuth 1.0a, not 2.0)
- [ ] Store Garmin tokens in Supabase

#### 3.2 Garmin Activity Sync
- [ ] Manual sync button
- [ ] Auto sync every 12 hours
- [ ] Activity mapping (similar to Strava)
- [ ] Support for: runs, cycling, swimming, strength training

#### 3.3 Advanced Garmin Features
- [ ] **Training Status** - Import Garmin's training effect, VO2 max
- [ ] **Body Battery** - Sync stress and recovery metrics
- [ ] **Sleep Data** - Import sleep quality scores
- [ ] **Heart Rate Zones** - Sync HR zone data

**Deliverables**:
- Garmin OAuth backend routes
- Garmin sync UI components
- Background sync worker
- Documentation

**Estimated Time**: 10-12 days  
**Files to Create**: api/garmin.ts, frontend/garmin-connect.js

---

### **Phase 4: Coach Dashboard** (Week 7-8)
**Priority**: MEDIUM  
**Status**: PENDING

#### 4.1 Multi-Athlete Management
- [ ] **Athlete List** - Table showing all managed athletes
- [ ] **Filters** - By AIFRI risk level, injury status, group
- [ ] **Search** - Find athletes by name or email
- [ ] **Bulk Actions** - Select multiple athletes for actions

#### 4.2 Athlete Details Modal
- [ ] **Overview Tab** - AIFRI score, recent workouts, injuries
- [ ] **Training Plan Tab** - Assign/edit weekly goals
- [ ] **Communication Tab** - Send messages, notes
- [ ] **History Tab** - Assessment history, workout logs

#### 4.3 Coach Features
- [ ] **Group Management** - Create training groups
- [ ] **Bulk Assign Workouts** - Assign workouts to multiple athletes
- [ ] **Injury Alerts** - Dashboard alerts for new injuries
- [ ] **Weekly Reports** - Automated email summaries

**Deliverables**:
- coach-dashboard.html with athlete table
- Backend API for coach-athlete relationships
- Email notification system (SendGrid)
- Group management UI

**Estimated Time**: 12-14 days  
**Files to Modify**: coach-dashboard.html, api/coach.ts

---

### **Phase 5: Push Notifications** (Week 9)
**Priority**: MEDIUM  
**Status**: PENDING

#### 5.1 Service Worker Setup
- [ ] Create service-worker.js with push notification support
- [ ] Register service worker on dashboard load
- [ ] Request notification permissions from user

#### 5.2 Notification Types
- [ ] **Daily Workout Reminder** - 8 AM local time
- [ ] **Weekly Mileage Check** - Sunday 6 PM
- [ ] **Assessment Reminder** - Every 90 days
- [ ] **Injury Alert** - When RPE > 8 or pain logged
- [ ] **Streak Milestone** - 7-day, 30-day, 100-day streaks

#### 5.3 Backend Notification System
- [ ] Cloudflare Cron jobs for scheduled notifications
- [ ] Web Push API integration
- [ ] Supabase table: notifications (user_id, type, sent_at)

**Deliverables**:
- service-worker.js with push handling
- Backend notification scheduler
- Frontend notification settings page
- User notification preferences

**Estimated Time**: 5-6 days  
**Files to Create**: service-worker.js, api/notifications.ts

---

### **Phase 6: Data Export Features** (Week 10)
**Priority**: LOW  
**Status**: PENDING

#### 6.1 Workout Data Export
- [ ] **CSV Export** - Export workouts to CSV (date, distance, RPE, notes)
- [ ] **Date Range Filter** - Select custom date range
- [ ] **Excel Compatible** - Proper CSV formatting

#### 6.2 Assessment Reports
- [ ] **PDF Report** - Generate PDF with AIFRI score, pillar breakdown, recommendations
- [ ] **Email Report** - Send PDF to athlete email
- [ ] **Coach Access** - Coaches can generate reports for athletes

#### 6.3 Training Log Export
- [ ] **Full Training Log** - Export all workouts, assessments, injuries
- [ ] **Summary Statistics** - Include totals, averages, trends

**Deliverables**:
- CSV export functionality (frontend)
- PDF generation (backend with puppeteer)
- Export UI on dashboard
- Email delivery system

**Estimated Time**: 4-5 days  
**Files to Create**: api/export.ts, frontend/export-modal.js

---

### **Phase 7: Mobile PWA Version** (Week 11-14)
**Priority**: LOW  
**Status**: PENDING

#### 7.1 Progressive Web App Setup
- [ ] Create manifest.json (installable app)
- [ ] Add app icons (192x192, 512x512)
- [ ] Service worker for offline support
- [ ] IndexedDB for local caching

#### 7.2 Mobile-Optimized UI
- [ ] Bottom tab navigation (Dashboard, Track, History, Profile)
- [ ] Swipeable cards
- [ ] Touch-friendly buttons (44px minimum)
- [ ] Pull-to-refresh

#### 7.3 Mobile-Specific Features
- [ ] **Live GPS Tracking** - Real-time run tracking with map
- [ ] **Camera Upload** - Take photos of injuries
- [ ] **Voice Input** - Voice-to-text for workout notes
- [ ] **Offline Mode** - Queue workouts for later sync

**Deliverables**:
- Mobile PWA at m.akura.in
- GPS tracking functionality
- Offline support
- Installable app

**Estimated Time**: 15-20 days  
**Files to Create**: mobile/ directory (separate React app)

---

### **Phase 8: Production Deployment** (Week 15)
**Priority**: HIGH  
**Status**: PENDING

#### 8.1 Cloudflare Pages Deployment
- [ ] Build production-ready app (npm run build)
- [ ] Deploy to Cloudflare Pages
- [ ] Configure custom domain (www.akura.in)
- [ ] SSL certificate setup

#### 8.2 Environment Configuration
- [ ] Production Supabase database
- [ ] Environment variables (Strava/Garmin keys)
- [ ] Error monitoring (Sentry)
- [ ] Analytics (Google Analytics)

#### 8.3 Testing & QA
- [ ] End-to-end testing on production
- [ ] Mobile device testing (iOS + Android)
- [ ] Performance audit (Lighthouse)
- [ ] Security audit

**Deliverables**:
- Production app at www.akura.in
- Monitoring dashboard
- Deployment documentation
- Backup and rollback procedures

**Estimated Time**: 5-6 days  
**Files to Modify**: wrangler.jsonc, package.json, README.md

---

## 📅 Timeline Summary

| Phase | Duration | Start Date | End Date | Priority |
|-------|----------|------------|----------|----------|
| 1. Complete Athlete Dashboard | 10 days | Feb 1 | Feb 10 | HIGH |
| 2. Strava Integration | 12 days | Feb 11 | Feb 22 | HIGH |
| 3. Garmin Integration | 12 days | Feb 23 | Mar 6 | MEDIUM |
| 4. Coach Dashboard | 14 days | Mar 7 | Mar 20 | MEDIUM |
| 5. Push Notifications | 6 days | Feb 23 | Feb 28 | MEDIUM |
| 6. Data Export | 5 days | Mar 1 | Mar 5 | LOW |
| 7. Mobile PWA | 20 days | Mar 6 | Mar 25 | LOW |
| 8. Production Deploy | 6 days | Mar 9 | Mar 14 | HIGH |

**Total Estimated Time**: 85 days (~3 months)  
**Parallel Execution**: Some phases can run in parallel  
**Target Completion**: March 15, 2026

---

## 🎯 Immediate Next Steps (This Week)

### Step 1: Complete Athlete Dashboard (TODAY)
Start with high-impact features:

1. **Injury Timeline** - Visual representation of injuries
2. **Workout History** - Last 30 days with filters
3. **Profile Settings** - Edit user information

### Step 2: Strava Integration Setup (Feb 1-2)
1. Register Strava API application
2. Set up OAuth flow
3. Create database schema changes

### Step 3: Strava Sync Implementation (Feb 3-5)
1. Build sync functionality
2. Add dashboard UI
3. Test with real Strava account

---

## 🔧 Technical Requirements

### Backend (Hono + Cloudflare Workers)
- Strava OAuth client
- Garmin OAuth 1.0a client
- Cron jobs for background sync
- Push notification scheduler
- PDF generation (puppeteer)
- Email service (SendGrid)

### Frontend (HTML + Tailwind + Vanilla JS)
- Service worker for PWA
- IndexedDB for offline storage
- Web Push API for notifications
- Camera API for photo upload
- Geolocation API for GPS tracking
- Web Speech API for voice input

### Database (Supabase PostgreSQL)
- Add Strava/Garmin token columns
- Create notifications table
- Add activity source tracking
- Optimize queries for performance

### Deployment (Cloudflare Pages)
- Production environment variables
- Custom domain configuration
- SSL certificate
- CDN configuration

---

## 📚 Documentation Needs

- [ ] Strava API integration guide
- [ ] Garmin API integration guide
- [ ] Coach dashboard user manual
- [ ] Mobile PWA installation guide
- [ ] Deployment runbook
- [ ] API endpoint documentation
- [ ] Database schema documentation

---

## 🎉 Success Metrics

### User Engagement
- 90%+ daily active users
- Average 5+ workouts logged per week
- 80%+ assessment completion rate
- 70%+ Strava connection rate

### Technical Performance
- Page load time < 2 seconds
- API response time < 500ms
- 99.9% uptime
- Zero data loss

### Business Metrics
- 200+ active athletes by March 2026
- 10+ coaches onboarded
- 50%+ mobile usage
- 4.5+ star rating

---

**Last Updated**: January 31, 2026  
**Status**: Phase 1 In Progress  
**Next Review**: February 7, 2026

---

**🚀 Let's build the best injury prevention platform for runners!**
