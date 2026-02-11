# 🚀 Quick Start: Launch Kura Coach for 10 Athletes TODAY

## ✅ What We Built

### 1. Adaptive Training Engine
- **kura_coach_service.dart** - Core workout generator (600+ lines)
  - AISRI score calculator
  - 6 training zones with HR/pace targets
  - Safety gate validation (Zone P/SP)
  - Weekly schedule generator
  - Garmin-compatible workout format

- **kura_coach_adaptive_service.dart** - Adaptation system (400+ lines)
  - Athlete state analyzer (AISRI + Strava + goals)
  - 4-week plan generator
  - Weekly performance tracker
  - Automatic adaptation algorithm
  - Batch processing for 10 athletes

### 2. Database Tables
- **athlete_goals** - Training goals and preferences
- **ai_workout_plans** - 4-week plans with phases
- **ai_workouts** - Individual workouts (Garmin-compatible)
- **workout_performance** - RPE and feedback
- **AISRI_training_history** - Weekly progression

### 3. Admin Interface
- **admin_batch_generation_screen.dart** - UI to generate plans
  - Select athletes
  - Analyze (shows AISRI, phase)
  - Generate button
  - Results summary

### 4. Automation
- **function_weekly_tracking_cron.sql** - Weekly tracking
- View to identify athletes needing adaptation after week 4

---

## 🎯 Today's Tasks

### STEP 1: Deploy Database (5 min)

```sql
-- In Supabase SQL Editor, run these 3 files in order:

-- 1. Goals table
-- Copy: database/migration_athlete_goals.sql
-- Paste in editor → Run

-- 2. Workout tables (if not already deployed)
-- Copy: database/migration_kura_coach_workouts.sql
-- Paste in editor → Run

-- 3. Weekly tracking function
-- Copy: database/function_weekly_tracking_cron.sql
-- Paste in editor → Run
```

**Verify:** Check Tables section in Supabase:
- ✅ athlete_goals
- ✅ ai_workout_plans
- ✅ ai_workouts
- ✅ workout_performance
- ✅ AISRI_training_history

---

### STEP 2: Onboard Athletes

Each of the 10 athletes must:

1. **Create Account**
   - Download SafeStride app
   - Sign up with email

2. **Connect Strava**
   - Settings → Integrations → Strava
   - OAuth flow (auto-downloads 3 weeks history)

3. **Complete AISRI Evaluation**
   - More Menu → AISRI Assessment
   - Complete all 6 assessments:
     * Running Performance
     * Strength
     * Range of Motion
     * Balance
     * Mobility
     * Alignment
   - **Result:** AISRI score 0-100

4. **Set Goals** ⚠️ NEW SCREEN NEEDED
   - More Menu → Set Goals (create this screen)
   - Fill out:
     * Primary goal (5K/10K/marathon/fitness)
     * Target event and date
     * Current PRs (5K, 10K, half, full)
     * Target times
     * Days per week (3-7)
     * Preferred time (morning/afternoon/evening)
     * Max workout duration (30/45/60/90 min)

**Status Check:** In Supabase, verify each athlete has:
- ✅ Row in `athlete_profiles`
- ✅ Strava connected (check `strava_activities` table)
- ✅ Latest `AISRI_assessments` row
- ✅ Row in `athlete_goals`

---

### STEP 3: Batch Generate Plans

1. **Add Admin Screen to Navigation**
```dart
// In lib/screens/more_menu_screen.dart
// Add this option to the menu:
{
  'title': 'Admin: Generate Plans',
  'icon': Icons.rocket_launch,
  'route': '/admin-batch-generation',
  'admin_only': true,  // Optional: restrict access
}
```

2. **Run Generation**
   - Open SafeStride app
   - More Menu → Admin: Generate Plans
   - You'll see list of 10 athletes
   - Athletes with ✅ "Goals set" are ready
   - Select all 10 athletes (checkbox)
   - Click **"Analyze Athletes"** button
     * Shows AISRI score for each
     * Shows recommended training phase
     * Shows training level from Strava
   - Click **"Generate Plans"** button
     * Creates 4-week plans (28 workouts each)
     * Total: 280 workouts scheduled
     * Status: All start TODAY
   - See results dialog:
     * ✅ Success count
     * Training phase per athlete
     * AISRI scores

3. **Verify in Database**
```sql
-- Check plans created
SELECT 
    u.email,
    ap.full_name,
    awp.plan_name,
    awp.training_phase,
    awp.start_date,
    COUNT(aw.id) as workout_count
FROM ai_workout_plans awp
JOIN auth.users u ON u.id = awp.user_id
JOIN athlete_profiles ap ON ap.user_id = awp.user_id
LEFT JOIN ai_workouts aw ON aw.plan_id = awp.id
WHERE awp.status = 'active'
GROUP BY u.email, ap.full_name, awp.plan_name, awp.training_phase, awp.start_date
ORDER BY awp.start_date DESC;

-- Should show 10 athletes with 28 workouts each
```

---

## 📅 What Happens Next

### Week 1-4: Training Phase
- Athletes open app daily
- See today's workout:
  - Zone (AR, F, EN, TH, P, or SP)
  - Duration and intervals
  - HR targets (calculated from age)
  - Pace targets (estimated)
- Complete workout (outdoor run or watch)
- Strava auto-uploads
- SafeStride auto-syncs from Strava
- Marks workout 'completed'
- Records actual: duration, distance, HR, pace
- Athletes log RPE (Rate of Perceived Exertion 1-10)

### Every Sunday: Weekly Tracking
```sql
-- Manual query for now (automate later)
SELECT kura_coach_weekly_tracking();

-- Or check this view to see who needs adaptation:
SELECT * FROM athletes_needing_adaptation;
```

### After Week 4: Automatic Adaptation
System analyzes each athlete's performance:

**Metrics Analyzed:**
- Completion rate (workouts done / scheduled)
- AISRI score change (baseline vs current)
- Weekly trend (improving or declining)
- Average RPE

**Decision Logic:**
- ⬆️ **PROGRESS** if:
  - Completion > 85%
  - AISRI improved +5 points
  - Performance improving
  - **Action:** Move to harder phase (Foundation → Endurance)
  
- ↔️ **MAINTAIN** if:
  - Completion 60-85%
  - AISRI stable (±5 points)
  - **Action:** Repeat current phase with variation
  
- ⬇️ **REDUCE** if:
  - Completion < 60%
  - AISRI declined -5 points
  - Injury reported
  - **Action:** Move to easier phase (Threshold → Endurance)

**New Plan Generated:**
- New 4-week plan created automatically
- Athlete sees updated calendar
- Cycle repeats every 4 weeks

---

## 🔧 Optional: Build UI Screens

For better athlete experience, create these screens:

### 1. Goals Form Screen (HIGH PRIORITY)
**File:** `lib/screens/athlete_goals_screen.dart`

**UI Components:**
- Dropdown: Primary goal
- Text field: Target event name
- Date picker: Target date
- Time pickers: Current/target PRs (HH:MM:SS)
- Chips: Days per week (3, 4, 5, 6, 7)
- Radio buttons: Preferred time (morning/afternoon/evening)
- Slider: Max workout duration (30-90 min)
- Text area: Injury history
- Slider: Motivation level (1-10)
- Save button

**Integration:**
```dart
// Call from More menu
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => AthleteGoalsScreen()),
);
```

### 2. Workout Calendar Screen
**File:** `lib/screens/kura_coach_calendar_screen.dart`

**Features:**
- Weekly calendar grid (Mon-Sun)
- Each day: Workout card with:
  - Zone badge (color-coded)
  - Duration
  - Status icon (scheduled/completed/skipped)
- Tap workout → Detail screen
- "Generate New Plan" FAB (for manual regeneration)

### 3. Workout Detail Screen
**File:** `lib/screens/workout_detail_screen.dart`

**Features:**
- Workout name
- Zone badge (large, colored)
- Duration and estimated distance
- HR zone chart (visual bar showing target range)
- Pace targets (min/km)
- Interval breakdown table (if applicable)
- "Start Workout" button (future: syncs to Garmin)
- "Mark Complete" button (manual completion)
- "Log Performance" button (opens RPE form)

### 4. Weekly Progress Screen
**File:** `lib/screens/weekly_progress_screen.dart`

**Features:**
- Week selector tabs (Week 1, 2, 3, 4)
- Completion chart (bar chart: scheduled vs completed)
- Time in zones pie chart (AR, F, EN, TH, P, SP)
- Totals: distance, time, calories
- Average RPE line chart
- AISRI score progression
- "Adaptation Preview" section (shown after week 4)

---

## 📊 Monitoring & Support

### Check Weekly Progress
```sql
-- View training history
SELECT 
    ap.full_name,
    ath.week_start_date,
    ath.workouts_completed,
    ath.workouts_scheduled,
    ROUND(ath.workouts_completed::DECIMAL / ath.workouts_scheduled * 100, 0) as completion_pct,
    ath.total_time_minutes,
    ath.total_distance,
    ath.AISRI_score_end
FROM AISRI_training_history ath
JOIN athlete_profiles ap ON ap.user_id = ath.user_id
ORDER BY ath.week_start_date DESC
LIMIT 50;
```

### Troubleshooting

**Athlete not seeing workouts:**
- Check `ai_workouts` table → status should be 'scheduled'
- Verify plan start_date is today or earlier
- Check athlete's user_id matches

**Plan generation failed:**
- Ensure athlete has completed AISRI evaluation
- Check `athlete_goals` table has row for user
- Verify Strava activities exist (last 3 weeks)
- Review error message in results dialog

**Adaptation not triggering:**
- Check plan has been active for 4+ weeks
- Run `SELECT * FROM athletes_needing_adaptation;`
- Manually trigger: `KuraCoachAdaptiveService.adaptTrainingPlan()`

---

## 🎉 Success Checklist

### Today (Launch Day)
- [ ] Database migrations deployed (3 files)
- [ ] 10 athletes onboarded
- [ ] All 10 have AISRI scores
- [ ] All 10 have goals set
- [ ] All 10 connected to Strava
- [ ] Batch generation completed
- [ ] 280 workouts scheduled (28 per athlete)
- [ ] Athletes can see today's workout in app

### Week 1
- [ ] Athletes completing workouts
- [ ] Strava sync working
- [ ] Workouts marked 'completed' automatically
- [ ] Athletes logging RPE

### Week 4
- [ ] Weekly tracking data captured (4 weeks)
- [ ] Completion rates ≥80%
- [ ] Athletes engaged

### Week 5 (First Adaptation)
- [ ] Adaptation runs successfully
- [ ] New plans generated for all 10
- [ ] Athletes see next 4 weeks scheduled
- [ ] Training phases adjusted appropriately

---

## 📚 Full Documentation

**Read this for complete details:**
`docs/KURA_COACH_EXECUTION_PLAN.md`

Includes:
- System workflow diagrams
- Data flow architecture
- Adaptation algorithm details
- Success metrics
- Future features roadmap

---

## 🚀 LET'S GO!

**Right now:**
1. Deploy database migrations (5 min)
2. Onboard first athlete as test (15 min)
3. Verify plan generates correctly
4. Onboard remaining 9 athletes
5. Run batch generation
6. Athletes start training TODAY!

**Questions? Issues?**
- Check Supabase logs
- Review error messages in results dialog
- Verify all preconditions met (AISRI + goals + Strava)

---

**The system is ready. Let's transform 10 athletes' lives with AI-powered training!** 🎯🏃‍♂️💪
