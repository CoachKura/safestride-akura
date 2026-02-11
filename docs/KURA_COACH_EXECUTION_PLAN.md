# 🎯 Kura Coach Execution Plan
## Adaptive Training System for 10 Athletes

---

## 📋 Overview

**System**: Kura Coach Adaptive Training  
**Athletes**: 10 initial users  
**Cycle**: 4-week training blocks with automatic adaptation  
**Start Date**: Today (workouts begin immediately)  

---

## 🔄 System Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                         KURA COACH FLOW                         │
└─────────────────────────────────────────────────────────────────┘

WEEK 0 (Today): SETUP PHASE
┌──────────────────────────────────────────────────────────────┐
│ 1. Athlete Signs Up                                          │
│    ├─ Creates SafeStride account                            │
│    ├─ Connects Strava account (downloads 3 weeks history)   │
│    └─ Completes AISRI evaluation form                       │
│                                                              │
│ 2. Athlete Sets Goals                                        │
│    ├─ Primary goal (5K, 10K, marathon, fitness, etc.)       │
│    ├─ Target event and date                                 │
│    ├─ Current PRs and target times                          │
│    ├─ Days per week available (1-7)                         │
│    └─ Training preferences (time of day, max duration)      │
│                                                              │
│ 3. Kura Coach Analyzes                                       │
│    ├─ Calculate AISRI score (6 components)                  │
│    ├─ Evaluate Strava training history (3 weeks)            │
│    │   ├─ Weekly volume (time + distance)                   │
│    │   ├─ Consistency score                                 │
│    │   └─ Training level (beginner/intermediate/advanced)   │
│    ├─ Check safety gates (Zone P/SP permissions)            │
│    └─ Determine starting phase (Foundation/Endurance/etc.)  │
│                                                              │
│ 4. Generate Initial 4-Week Plan                             │
│    ├─ Create 28 workouts (7 per week × 4 weeks)             │
│    ├─ Each workout includes:                                │
│    │   ├─ Zone (AR, F, EN, TH, P, or SP)                    │
│    │   ├─ Duration and intervals                            │
│    │   ├─ HR targets (calculated from age)                  │
│    │   ├─ Pace targets (estimated from HR)                  │
│    │   └─ Garmin-compatible workout_steps array             │
│    └─ Save to database (status: 'scheduled')                │
└──────────────────────────────────────────────────────────────┘

WEEKS 1-4: TRAINING PHASE
┌──────────────────────────────────────────────────────────────┐
│ Daily:                                                        │
│  ├─ Athlete sees today's workout in app                     │
│  ├─ Workout syncs to Garmin watch (future feature)          │
│  ├─ Athlete completes workout                               │
│  ├─ Workout uploads to Strava automatically                 │
│  └─ SafeStride syncs from Strava                            │
│      ├─ Marks workout as 'completed'                        │
│      ├─ Records actual duration, distance, HR, pace         │
│      └─ Asks for RPE (perception rating 1-10)               │
│                                                              │
│ Weekly:                                                       │
│  ├─ Track performance metrics                               │
│  │   ├─ Workouts completed vs scheduled                     │
│  │   ├─ Total time and distance                             │
│  │   ├─ Time in each training zone                          │
│  │   └─ Average RPE                                         │
│  └─ Save to AISRI_training_history table                    │
└──────────────────────────────────────────────────────────────┘

WEEK 5: ADAPTATION PHASE
┌──────────────────────────────────────────────────────────────┐
│ 1. Analyze 4-Week Performance                                │
│    ├─ Completion rate (workouts done / scheduled)           │
│    ├─ Weekly progression (improving or declining)           │
│    ├─ AISRI score change (baseline vs current)              │
│    ├─ Average RPE trend                                     │
│    └─ Injury or issue reports                               │
│                                                              │
│ 2. Calculate Adaptation                                      │
│    ├─ IF completion > 85% AND AISRI +5 AND improving:       │
│    │   └─ PROGRESS to harder phase (Foundation → Endurance) │
│    ├─ IF completion < 60% OR AISRI -5:                      │
│    │   └─ REDUCE to easier phase (Threshold → Endurance)    │
│    └─ ELSE:                                                 │
│        └─ MAINTAIN current phase (repeat with variation)    │
│                                                              │
│ 3. Generate Next 4-Week Plan                                │
│    ├─ Use new training phase                                │
│    ├─ Adjust volume based on performance                    │
│    ├─ Progress intervals (longer work, shorter rest)        │
│    └─ Update zone permissions if AISRI improved             │
│                                                              │
│ 4. Continue Cycle                                            │
│    └─ Repeat WEEKS 1-4 → WEEK 5 indefinitely                │
└──────────────────────────────────────────────────────────────┘
```

---

## 🚀 Execution Steps (What We Do Today)

### Step 1: Database Setup (5 minutes)
```bash
# Deploy 2 migrations to Supabase
```

**Files to deploy:**
1. `migration_athlete_goals.sql` ← New goals table
2. `migration_kura_coach_workouts.sql` ← Workout tables (already created)

**Actions:**
1. Open Supabase SQL Editor
2. Copy migration_athlete_goals.sql content
3. Click "Run" → Verify success
4. Repeat for migration_kura_coach_workouts.sql
5. Check tables exist: `athlete_goals`, `ai_workout_plans`, `ai_workouts`, `workout_performance`, `AISRI_training_history`

---

### Step 2: Athlete Onboarding (Per Athlete)

**Each athlete must complete:**

#### A. Account Setup
- Create SafeStride account
- Connect Strava (OAuth flow)
- Complete profile (age, gender, weight for HR/pace calculations)

#### B. AISRI Evaluation Form
Complete **6 assessments** (existing system):
1. Running Performance (field tests, VO2 estimation)
2. Strength (single-leg squat, calf raises)
3. Range of Motion (hip flexion, ankle dorsiflexion)
4. Balance (single-leg stance, Y-balance test)
5. Mobility (functional movement screen)
6. Alignment (posture and gait analysis)

**Result**: AISRI score 0-100

#### C. Goals Form (New Screen Needed)
- Primary goal:
  - [ ] Weight loss / General fitness
  - [ ] 5K race
  - [ ] 10K race
  - [ ] Half Marathon
  - [ ] Marathon
  - [ ] Speed improvement
- Target event name (if racing)
- Target date
- Current PRs (5K, 10K, half, full)
- Target times
- Days per week available (1-7)
- Preferred training time (morning/afternoon/evening)
- Max workout duration (30/45/60/90 minutes)
- Injury history
- Training obstacles

---

### Step 3: Batch Generation (Today)

**Run batch processor for 10 athletes:**

```dart
// In mobile app or admin panel
final results = await KuraCoachAdaptiveService.generatePlansFor10Athletes();

// Output:
// ✅ Athlete 1: Foundation phase, 4-week plan created
// ✅ Athlete 2: Endurance phase, 4-week plan created
// ...
// ✅ 10 athletes processed
```

**What happens:**
- For each athlete:
  1. Fetch evaluation + goals + Strava history
  2. Calculate AISRI score
  3. Analyze training load (3 weeks)
  4. Determine starting phase
  5. Generate 28 workouts (7 days × 4 weeks)
  6. Save to database with status 'scheduled'
  7. Workouts start TODAY

**Result**: Each athlete has 28 workouts scheduled from today

---

### Step 4: Weekly Automation (Ongoing)

**Set up cron job or scheduled function:**

```dart
// Run every Sunday at 11:59 PM
Future<void> weeklyTrackingJob() async {
  final activeUsers = await getActiveAthletes();
  
  for (var user in activeUsers) {
    final activePlan = await getActivePlan(user.id);
    if (activePlan != null) {
      final weekNumber = getWeekNumber(activePlan);
      
      // Track weekly performance
      await KuraCoachAdaptiveService.trackWeeklyPerformance(
        userId: user.id,
        planId: activePlan.id,
        weekNumber: weekNumber,
      );
      
      // After week 4, adapt
      if (weekNumber == 4) {
        await KuraCoachAdaptiveService.adaptTrainingPlan(
          userId: user.id,
          previousPlanId: activePlan.id,
        );
      }
    }
  }
}
```

**Triggers adaptation every 4 weeks automatically.**

---

## 📊 Data Flow

```
┌─────────────────┐
│ ATHLETE INPUTS  │
├─────────────────┤
│ • AISRI eval    │      ┌──────────────────────┐
│ • Goals form    │─────▶│  KURA COACH ENGINE   │
│ • Strava data   │      ├──────────────────────┤
└─────────────────┘      │ 1. Analyze           │
                         │ 2. Phase selection   │
                         │ 3. Plan generation   │
                         │ 4. Safety checks     │
                         └──────────┬───────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │      DATABASE TABLES        │
                    ├─────────────────────────────┤
                    │ • ai_workout_plans          │
                    │ • ai_workouts (28 per plan) │
                    │ • workout_performance       │
                    │ • AISRI_training_history    │
                    └──────────────┬──────────────┘
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        │                          │                          │
┌───────▼────────┐      ┌──────────▼─────────┐   ┌──────────▼────────┐
│ MOBILE APP     │      │ GARMIN WATCH       │   │ STRAVA SYNC       │
├────────────────┤      ├────────────────────┤   ├───────────────────┤
│ • Daily view   │      │ • Workout display  │   │ • Activity sync   │
│ • Calendar     │      │ • Interval guide   │   │ • Mark completed  │
│ • Progress     │      │ • HR zones         │   │ • Actual metrics  │
└────────────────┘      └────────────────────┘   └───────────────────┘
```

---

## 📱 Required UI Screens

### 1. Goals Setup Screen (NEW - Priority 1)
**File**: `lib/screens/athlete_goals_screen.dart`

**Features:**
- Form with all goal fields
- Date picker for target event
- Time pickers for PRs (HH:MM:SS format)
- Days per week selector (chips: 3, 4, 5, 6, 7)
- Slider for motivation level (1-10)
- "Save Goals" button

### 2. Workout Calendar Screen (NEW - Priority 2)
**File**: `lib/screens/kura_coach_calendar_screen.dart`

**Features:**
- Weekly calendar view
- Each day shows workout card:
  - Zone badge (color-coded)
  - Duration and intervals
  - HR range
  - Status icon (scheduled/in-progress/completed/skipped)
- Tap workout → Detail screen
- "Generate New Plan" FAB

### 3. Workout Detail Screen (NEW - Priority 3)
**File**: `lib/screens/workout_detail_screen.dart`

**Features:**
- Workout name and zone
- Duration and estimated distance
- HR zones chart (visual bar)
- Pace targets
- Interval breakdown table
- "Start Workout" button (future: syncs to Garmin)
- "Mark Complete" button (manual)
- "Log Performance" (RPE, enjoyment, notes)

### 4. Admin Generation Screen (NEW - Priority 4)
**File**: `lib/screens/admin_batch_generation_screen.dart`

**Features:**
- List 10 athletes with evaluation status
- Checkboxes to select athletes
- "Analyze Athletes" button
- Shows analysis results:
  - AISRI score
  - Strava training level
  - Recommended phase
- "Generate Plans" button
- Progress indicators
- Results summary

### 5. Weekly Progress Screen (NEW - Priority 5)
**File**: `lib/screens/weekly_progress_screen.dart`

**Features:**
- Week selector (Week 1, 2, 3, 4 of current plan)
- Completion chart (workouts done vs scheduled)
- Time in zones pie chart
- Distance and time totals
- Average RPE trend line
- AISRI score progression
- "Adaptation Preview" (after week 4)

---

## 🔧 Technical Requirements

### Backend (Supabase)
- [x] Database tables created (workouts, plans, performance, history)
- [ ] athlete_goals table deployed
- [ ] RLS policies verified
- [ ] Edge Function for weekly tracking (cron)
- [ ] Edge Function for batch generation (admin API)

### Mobile App (Flutter)
- [x] Kura Coach service (600+ lines)
- [x] Kura Coach adaptive service (400+ lines)
- [ ] Goals form screen
- [ ] Workout calendar screen
- [ ] Workout detail screen
- [ ] Admin generation screen
- [ ] Weekly progress screen
- [ ] Navigation updates (More menu)

### Integrations
- [x] Strava OAuth (already working)
- [x] Strava activity sync (already working)
- [ ] Garmin Connect IQ app (future)
- [ ] Push notifications (workout reminders)

---

## 📈 Success Metrics

### Week 1
- [ ] 10 athletes have active plans
- [ ] 70+ workouts scheduled
- [ ] Athletes can see today's workout
- [ ] Strava sync working

### Week 4
- [ ] ≥80% workout completion rate
- [ ] Athletes logging RPE
- [ ] Weekly tracking data captured
- [ ] No major injuries reported

### Week 5 (First Adaptation)
- [ ] Adaptation algorithm runs successfully
- [ ] New 4-week plans generated
- [ ] Athletes see progression (phase or intensity change)
- [ ] AISRI scores updated

### Month 3 (After 3 cycles)
- [ ] Athletes show measurable improvement:
  - AISRI score +10 points
  - PR improvement (faster times)
  - Consistency ≥85%
- [ ] System adapting correctly (progress/maintain/reduce)
- [ ] User satisfaction ≥8/10

---

## 🚨 Important Notes

### Safety First
- Zone P and SP require safety gates (AISRI ≥70-75, ROM ≥75, no recent injuries)
- If athlete reports injury, system auto-adjusts to Foundation phase
- RPE > 8 consistently → Reduce intensity

### Adaptation Logic
**Progress Criteria:**
- Completion rate > 85%
- AISRI improvement +5 points
- Weekly metrics improving
- Average RPE ≤ 7

**Maintain Criteria:**
- Completion rate 60-85%
- AISRI stable (±5 points)
- Consistent performance

**Reduce Criteria:**
- Completion rate < 60%
- AISRI decline -5+ points
- Average RPE > 8
- Injury reported

### Future Enhancements
1. **Garmin Connect IQ App** (Week 6-8)
   - Display workouts on watch
   - Live HR zone guidance
   - Interval countdown timers

2. **Social Features** (Month 2-3)
   - Group challenges
   - Leaderboards
   - Coach messaging

3. **Advanced Analytics** (Month 3-4)
   - ML predictions (race time, injury risk)
   - Fatigue monitoring
   - Form deterioration detection

---

## 🎯 Today's Action Items

### For Developer (You):
1. [ ] Deploy `migration_athlete_goals.sql` to Supabase
2. [ ] Verify `migration_kura_coach_workouts.sql` deployed
3. [ ] Create `athlete_goals_screen.dart` (form)
4. [ ] Create `admin_batch_generation_screen.dart`
5. [ ] Test batch generation with 1-2 test users
6. [ ] Deploy and verify with 10 real athletes

### For Athletes (10 People):
1. [ ] Download SafeStride app
2. [ ] Create account
3. [ ] Connect Strava
4. [ ] Complete AISRI evaluation
5. [ ] Fill out goals form
6. [ ] Wait for plan generation
7. [ ] Start training tomorrow! 🎉

---

## 📞 Support

**If athlete encounters issues:**
- Check Strava connection active
- Verify AISRI assessment completed
- Ensure goals form submitted
- Contact admin to regenerate plan

**If system fails:**
- Check database tables exist
- Verify RLS policies
- Review Supabase logs
- Test with single user first

---

**Let's build the future of personalized training!** 🚀
