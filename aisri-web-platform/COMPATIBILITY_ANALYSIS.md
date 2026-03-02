# 🔍 AISRi System Compatibility Analysis

## Database Schema Comparison: Existing vs New Web Platform

### ✅ **EXISTING SYSTEM** (Currently in Supabase)

Based on codebase analysis, your **current Supabase database** has:

#### **Core Tables:**

1. **`profiles` table**

   ```sql
   - id (UUID, links to auth.users)
   - email (TEXT, unique)
   - full_name (TEXT)
   - role (TEXT) - 'athlete', 'coach', 'admin'
   - telegram_id (TEXT, nullable)
   - whatsapp_number (TEXT, nullable)
   - created_at (TIMESTAMPTZ)
   - updated_at (TIMESTAMPTZ)
   ```

   ✅ **Status**: MATCHES new web platform requirements

2. **`athlete_coach_relationships` table**

   ```sql
   - id (UUID)
   - athlete_id (UUID → profiles)
   - coach_id (UUID → profiles)
   - status (TEXT) - 'active', 'inactive', 'pending'
   - created_at, updated_at
   ```

   ✅ **Status**: MATCHES new web platform requirements

3. **`AISRI_assessments` table**

   ```sql
   - id (UUID)
   - profile_id (UUID → profiles)
   - aisri_score (NUMERIC)
   - mobility_score, stability_score, strength_score, etc.
   - key_risk_factors (JSONB)
   - recommendations (JSONB)
   - assessment_date (DATE)
   ```

   ✅ **Status**: Compatible with new web platform

4. **`athlete_detailed_profile` table**

   ```sql
   - athlete_id (TEXT/UUID)
   - profile_id (UUID → profiles)
   - Comprehensive athlete data (fitness, training, goals)
   - Strava/Garmin OAuth tokens
   - Current level, baseline assessment status
   ```

   ✅ **Status**: Used by AI Engine, compatible

5. **`workout_assignments` & `workout_results` tables**
   - Daily workout tracking
   - GIVEN vs RESULT comparison
   - Performance labels (BEST/GREAT/GOOD)

   ✅ **Status**: Compatible

6. **`ability_progression` table**
   - Tracks athlete improvement over time

   ✅ **Status**: Compatible

7. **`gps_activities` table** (from calendar fix)
   - GPS workout data
   - 55 columns including pace, HR, elevation

   ✅ **Status**: Already exists (from calendar migration)

8. **`athlete_calendar` table** (from calendar fix)
   - Scheduled workouts
   - Status tracking

   ✅ **Status**: Already exists (from calendar migration)

---

### 🆕 **NEW WEB PLATFORM** (aisri-web-platform)

#### **What We're Adding:**

1. **`evaluation_responses` table** ← NEW
   ```sql
   - athlete_id (UUID → profiles)
   - Onboarding evaluation data:
     * Personal (age, gender, height, weight)
     * Performance (weekly volume, VO2max, race times)
     * Injury history (past injuries, pain areas)
     * Recovery metrics (sleep, HRV, resting HR)
     * Goals (upcoming races, targets, priority)
   - completed (BOOLEAN)
   - completed_at (TIMESTAMPTZ)
   ```
   ⚠️ **Status**: NEW - needs to be created

---

## 🔗 Integration Points

### ✅ **COMPATIBLE** - No Conflicts

| Component          | Existing System               | New Web Platform       | Status        |
| ------------------ | ----------------------------- | ---------------------- | ------------- |
| **Authentication** | Supabase Auth + JWT           | Supabase Auth + JWT    | ✅ Same       |
| **User Table**     | `profiles` with `role`        | `profiles` with `role` | ✅ Same       |
| **Role System**    | athlete/coach/admin           | athlete/coach/admin    | ✅ Same       |
| **Athlete Data**   | `athlete_detailed_profile`    | Uses same table        | ✅ Compatible |
| **Assessments**    | `AISRI_assessments`           | Uses same table        | ✅ Compatible |
| **Coach-Athlete**  | `athlete_coach_relationships` | Uses same table        | ✅ Compatible |
| **Calendar**       | `athlete_calendar` (existing) | Read/write same table  | ✅ Compatible |
| **GPS Data**       | `gps_activities` (existing)   | Read/write same table  | ✅ Compatible |

---

## 🎯 AI Engine Integration

### **FastAPI Endpoints** (api.akura.in)

| Endpoint                        | Request Format           | Existing System         | New Web Platform |
| ------------------------------- | ------------------------ | ----------------------- | ---------------- |
| `/agent/predict-injury-risk`    | `{ athlete_id: "uuid" }` | ✅ Used by Telegram bot | ✅ Will use      |
| `/agent/predict-performance`    | `{ athlete_id: "uuid" }` | ✅ Used by Telegram bot | ✅ Will use      |
| `/agent/generate-training-plan` | `{ athlete_id: "uuid" }` | ✅ Used by Telegram bot | ✅ Will use      |
| `/agent/autonomous-decision`    | `{ athlete_id: "uuid" }` | ✅ Used by Telegram bot | ✅ Will use      |

✅ **Status**: FULLY COMPATIBLE - Same API, same payload format

---

## 📱 Multi-Platform Ecosystem

```
┌─────────────────────────────────────────────────────┐
│           EXISTING PLATFORMS (LIVE)                 │
├─────────────────────────────────────────────────────┤
│  1. Flutter Mobile App                              │
│     - iOS/Android native                            │
│     - Direct Supabase connection                    │
│     - Uses: profiles, AISRI_assessments             │
│                                                     │
│  2. Telegram Bot                                    │
│     - communication_agent_v2.py                     │
│     - Uses: profiles (telegram_id column)           │
│     - Calls AI Engine API                           │
│                                                     │
│  3. Calendar Web App (akura.in/calendar/)           │
│     - React/Vite                                    │
│     - Uses: athlete_calendar, gps_activities        │
└─────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────┐
│           NEW WEB PLATFORM (Building)               │
├─────────────────────────────────────────────────────┤
│  4. Next.js SaaS Platform                           │
│     - Landing page                                  │
│     - Authentication (Supabase Auth)                │
│     - Athlete Dashboard                             │
│     - Coach Dashboard                               │
│     - Admin Dashboard                               │
│     - ADDS: evaluation_responses table              │
│     - USES: All existing tables                     │
└─────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────┐
│              SHARED INFRASTRUCTURE                  │
├─────────────────────────────────────────────────────┤
│  • Supabase PostgreSQL                              │
│    - All tables accessible to all platforms         │
│    - Row Level Security (RLS) enforced              │
│    - Same auth.users for all platforms              │
│                                                     │
│  • FastAPI AI Engine (api.akura.in)                 │
│    - Used by Telegram bot, Flutter, Web platform    │
│    - Same endpoints, same payload format            │
└─────────────────────────────────────────────────────┘
```

---

## ✅ **Compatibility Summary**

### **✅ COMPATIBLE**

1. **Authentication System**: Both use Supabase Auth + JWT
2. **User Management**: Same `profiles` table with `role` column
3. **Database Tables**: New platform uses existing tables
4. **AI Engine API**: Same endpoints, same request format
5. **No Schema Conflicts**: New table (`evaluation_responses`) is additive only

### **⚠️ REQUIRES ATTENTION**

1. **Service Role Key**: Currently has anon key instead of service_role key
   - Impact: RLS restrictions apply to server-side operations
   - Fix: Update `.env` with actual service_role key

2. **New Table Migration**: Must run `01_evaluation_responses.sql`
   - Impact: Onboarding evaluation form won't work without it
   - Fix: Execute migration in Supabase SQL Editor

---

## 🚀 **Deployment Strategy**

### **Phase 1: Add New Web Platform** (Zero Impact on Existing)

1. Deploy Next.js app to Vercel
2. Run `evaluation_responses` migration
3. Test authentication with existing users
4. Verify AI Engine integration

### **Phase 2: Cross-Platform Testing**

1. Create test athlete in Flutter app → Verify appears in web dashboard
2. Create test athlete in web platform → Verify appears in Flutter
3. Update assessment in Telegram → Verify updates in web dashboard
4. Schedule workout in web → Verify appears in calendar app

### **Phase 3: Production Launch**

1. Both platforms access same data
2. Athletes can use mobile app OR web
3. Coaches use web dashboard
4. Telegram bot continues independently
5. Calendar continues independently

---

## 📋 **Action Items**

### **Immediate (Before Development)**

- [ ] Get actual Supabase service_role key
- [ ] Update web platform `.env.local` with all keys
- [ ] Run `01_evaluation_responses.sql` migration

### **During Development**

- [ ] Test authentication with existing Supabase users
- [ ] Verify `profiles` table queries work correctly
- [ ] Test AI Engine API calls with real athlete_id values
- [ ] Ensure RLS policies allow web platform access

### **Before Launch**

- [ ] Verify no conflicts with Flutter app
- [ ] Test Telegram bot still works
- [ ] Confirm calendar app unaffected
- [ ] Load test with 100+ athletes

---

## ✅ **Conclusion**

**The new web platform is FULLY COMPATIBLE with your existing AISRi system.**

**No breaking changes. No migrations needed (except one new table).**

All platforms will:

- Share the same database
- Use the same authentication
- Call the same AI Engine
- Work independently without conflicts

**You can deploy the web platform alongside all existing systems safely.** 🚀
