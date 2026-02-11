# 🏃‍♂️ AISRI - Complete Economical Runner System

## 🎯 Overview

The **AISRI (AI Fitness Running Index)** system is a comprehensive injury prevention and performance optimization platform that implements the "Economical Runner" philosophy. It combines 6 performance pillars, 6 HR training zones, and a 6-phase progression roadmap (0-5000km) to create durable, efficient, and injury-resistant runners.

---

## 📊 System Architecture

### **1. Six Performance Pillars**

| Pillar | Weight | Assessment |
|--------|--------|------------|
| **Running Performance** | 40% | Consistency, pace improvement, volume progression |
| **Strength** | 15% | Lower body, core, calf raises (single leg squat, plank holds) |
| **ROM** (Range of Motion) | 12% | Ankle dorsiflexion, hip flexion/extension |
| **Balance** | 13% | Single leg balance, stability tests |
| **Mobility** | 10% | Hip mobility, thoracic spine |
| **Alignment** | 10% | Knee drop, pelvic alignment |

#### AISRI Score Formula:
```
AISRI = (Running × 0.40) + (Strength × 0.15) + (ROM × 0.12) + 
        (Balance × 0.13) + (Mobility × 0.10) + (Alignment × 0.10)
```

#### Risk Levels:
- **0-39**: High Risk (AR, F zones only)
- **40-54**: Moderate Risk (+EN zone)
- **55-69**: Low Risk (+TH zone)
- **70-84**: Advanced (+P zone with safety gate)
- **85-100**: Elite (All zones including SP)

---

### **2. Six HR Training Zones**

Calculated from Max HR = **208 - (0.7 × Age)**

| Zone | Name | % Max HR | Purpose | Color | Lock Requirement |
|------|------|----------|---------|-------|------------------|
| **AR** | Active Recovery | 50-60% | Recovery, warm-up, cool-down | 🔵 Light Blue | Always unlocked |
| **F** | Foundation | 60-70% | Aerobic base building | 🔵 Blue | Always unlocked |
| **EN** | Endurance | 70-80% | Steady state aerobic | 🔵 Turquoise | AISRI ≥ 40 |
| **TH** ⭐ | Threshold (CORE) | 80-87% | Lactate threshold training | 🟠 Orange | AISRI ≥ 55 |
| **P** 🔒 | Power | 87-95% | High-intensity intervals | 🔴 Red | Safety Gate |
| **SP** 🔒 | Speed | 95-100% | Sprint work | 🔴 Dark Red | Safety Gate |

**⭐ Threshold (TH) = CORE ZONE** - Most effective for economical running development

---

### **3. Safety Gates System**

High-intensity zones (Power & Speed) are locked until specific requirements are met to prevent injury.

#### **Power Zone (P) Requirements:**
- ✅ AISRI Score ≥ 70
- ✅ ROM Score ≥ 75
- ✅ No injuries in past 4 weeks
- ✅ 8+ weeks training in lower zones
- ✅ Acute:Chronic load ratio ≤ 1.3

#### **Speed Zone (SP) Requirements:**
- ✅ AISRI Score ≥ 75
- ✅ All 5 pillars (Strength, ROM, Balance, Mobility, Alignment) ≥ 75
- ✅ Perfect running form (verified through assessment)
- ✅ 12+ weeks training including Power Zone work
- ✅ Acute:Chronic load ratio ≤ 1.2

---

### **4. Six Training Phases (0-5000km Journey)**

Progressive roadmap from beginner to elite runner over ~2 years.

| Phase | KM Range | Weeks | Focus | Zone Distribution |
|-------|----------|-------|-------|-------------------|
| **1. Base Building** | 0-800 | 1-16 | Aerobic foundation | 75% F, 20% AR, 5% EN |
| **2. Aerobic Development** | 800-1600 | 17-32 | Oxygen efficiency | 65% F, 25% EN, 10% TH |
| **3. Threshold Focus** | 1600-2400 | 33-48 | Lactate threshold | 55% F, 30% TH, 15% EN |
| **4. Interval Training** | 2400-3200 | 49-64 | VO2 max development | 45% F, 35% P, 20% TH |
| **5. Peak Performance** | 3200-4000 | 65-80 | Race preparation | 40% F, 30% P, 30% TH |
| **6. Taper & Recovery** | 4000-5000 | 81-100 | Maintenance, peak | 50% F, 40% AR, 10% EN |

---

## 🗂️ File Structure

### **Core Services** (lib/services/)

#### **AISRI_calculator_service.dart** (501 lines)
- Master calculation engine for AISRI score
- 6 pillar assessment algorithms
- Recovery score integration
- Load metrics (Acute:Chronic ratio)
- Zone permission logic
- Safety gates validation
- HR zone calculator

**Key Methods:**
```dart
// Master calculation
static Map<String, dynamic> calculateAISRIScore({
  required int age,
  required double weightKg,
  required double heightCm,
  required Map<String, dynamic> recentWorkouts,
  required Map<String, dynamic> injuryHistory,
  required Map<String, dynamic> sleepData,
  required Map<String, dynamic> assessmentData,
  int? subjectiveFeel,
})

// HR Zones
static Map<String, dynamic> calculateHRZones(int age)

// Returns: AISRI_score, pillar_scores, recovery_score, load_ratio, 
//         allowed_zones, safety_gates, risk_level, status_label
```

#### **training_phase_manager.dart** (301 lines)
- 6-phase progression tracking
- Zone distribution for each phase
- Weekly schedule generation
- Next milestone calculator
- Phase-specific protocols

**Key Methods:**
```dart
// Get current phase based on total km
static Map<String, dynamic> getCurrentPhase(double totalKmRun)

// Generate weekly schedule
static List<Map<String, dynamic>> generateWeeklySchedule({
  required Map<String, dynamic> currentPhase,
  required List<String> allowedZones,
  required int AISRIScore,
})

// Next phase milestone
static Map<String, dynamic> getNextPhaseMilestone(double currentKm)
```

---

### **UI Screens** (lib/screens/)

#### **start_run_screen.dart** (800+ lines)
Complete rewrite with 6 HR zones and zone locking.

**Features:**
- ✅ 6 HR zone grid with color coding
- ✅ Zone locking/unlocking based on AISRI score
- ✅ Safety gate dialogs with requirements checklist
- ✅ AISRI score card with recovery & load metrics
- ✅ Training phase progress bar with km tracking
- ✅ Star badge on TH (CORE ZONE)
- ✅ Verification badge on unlocked gated zones
- ✅ HR range and % max HR display

#### **safety_gates_screen.dart** (450+ lines)
Detailed view of Power and Speed zone requirements.

**Features:**
- ✅ Progress bars for each zone (requirements met/total)
- ✅ Checklist with green checkmarks / red X marks
- ✅ Tips on how to unlock each requirement
- ✅ "Why Safety Gates?" educational section
- ✅ Requirement descriptions with actionable advice

#### **dashboard_screen.dart** (Enhanced)
Integrated AISRI Dashboard Widget for home screen.

**Features:**
- ✅ Comprehensive AISRI visualization
- ✅ 6-pillar pie chart breakdown
- ✅ Training phase progress bar
- ✅ Weekly zone distribution
- ✅ Navigation to Safety Gates screen
- ✅ Fallback to simple card if data unavailable

---

### **Widgets** (lib/widgets/)

#### **AISRI_dashboard_widget.dart** (600+ lines)
Comprehensive visualization component.

**Components:**
1. **AISRI Score Circle** - Circular progress indicator (0-100)
2. **Status Badge** - Beginner/Intermediate/Advanced/Elite
3. **Risk Level** - Color-coded risk assessment
4. **6-Pillar Pie Chart** - Custom painted donut chart
5. **Pillar Cards Grid** - Individual pillar scores with icons
6. **Training Phase Card** - Current phase with progress bar
7. **Zone Distribution** - Weekly zone allocation badges

**Custom Painters:**
- `_CircularScorePainter` - Animated circular progress
- `_PillarPieChartPainter` - 6-segment donut chart with weighted slices

---

### **Database Schema** (database/)

#### **migration_AISRI_phase_tracking.sql**
Complete tracking system for training progression.

**Tables Created:**

1. **AISRI_zone_history** - Zone unlock tracking
   - user_id, zone_code, unlocked_at, AISRI_score_at_unlock, requirements_met

2. **AISRI_training_log** - Daily training log
   - user_id, log_date, zone_completed, distance_km, duration_minutes, avg_heart_rate, AISRI_score, load_ratio

3. **phase_transitions** - Phase change history
   - user_id, from_phase, to_phase, transition_date, total_km_at_transition, AISRI_score_at_transition

**Columns Added to `profiles`:**
- `lifetime_km_total` - Total km run (for phase tracking)
- `current_training_phase` - Current phase (1-6)
- `phase_start_date` - When current phase started
- `last_zone_unlock_date` - Last zone unlock timestamp

**Triggers:**
- `update_lifetime_km()` - Auto-updates total km on workout insert
- `check_phase_transition()` - Auto-detects phase transitions based on km milestones

---

## 🎨 Visual Design

### **Color Palette**

```dart
AR (Active Recovery): #87CEEB (Light Blue)
F (Foundation):       #4A90E2 (Blue)
EN (Endurance):       #48D1CC (Turquoise)
TH (Threshold):       #FFA500 (Orange) ⭐ CORE ZONE
P (Power):            #FF6B6B (Red) 🔒
SP (Speed):           #8B0000 (Dark Red) 🔒

Pillars:
Running:    #4A90E2 (Blue)
Strength:   #E74C3C (Red)
ROM:        #9B59B6 (Purple)
Balance:    #2ECC71 (Green)
Mobility:   #F39C12 (Orange)
Alignment:  #1ABC9C (Turquoise)
```

### **Status Labels**

| AISRI Score | Label | Color |
|-------------|-------|-------|
| 0-39 | Beginner | 🔴 Red |
| 40-59 | Intermediate | 🟠 Orange |
| 60-79 | Advanced | 🟢 Light Green |
| 80-89 | Advanced+ | 🟢 Green |
| 90-100 | Elite | 🟢 Dark Green |

---

## 📈 Load Management

### **Acute:Chronic Ratio**

Injury risk based on training load progression:

| Ratio | Status | Risk Level |
|-------|--------|------------|
| < 0.8 | Detraining | Low performance |
| 0.8 - 1.3 | **Optimal** | ✅ Safe zone |
| 1.3 - 1.5 | High Risk | ⚠️ Caution needed |
| > 1.5 | Very High Risk | 🛑 Reduce volume immediately |

**Calculation:**
```
Acute Load = Average daily km (last 7 days)
Chronic Load = Average daily km (last 28 days)
Ratio = Acute / Chronic
```

---

## 🚀 User Workflow

### **New User Journey**

1. **Sign up** → Complete AISRI Assessment (6-step evaluation)
2. **System calculates** AISRI score and unlocks initial zones (AR, F)
3. **Dashboard displays** current phase (Phase 1: Base Building, 0km)
4. **Start Run** → Select from unlocked zones (AR or F)
5. **Complete workouts** → Lifetime km increases → Phase progresses
6. **AISRI improves** → EN zone unlocks at 40+ → TH at 55+ → P at 70+ (with gate)
7. **Reach milestones** → Phase transitions automatically (800km →  Phase 2)
8. **Safety gates unlock** → Power Zone → Speed Zone (with all requirements met)
9. **Complete journey** → 5000km → Phase 6: Taper & Recovery → Elite runner

---

## 📱 Key User Features

### **1. Intelligent Zone Locking**
- Visual indicators (lock icons, greyed out cards)
- Tap locked zone → Shows requirements dialog
- Progress bars showing how close to unlocking
- Recommendations on how to improve

###  **2. Training Phase Visualization**
- Progress bar (0-5000km)
- Current phase name and km range
- Weekly zone distribution badges
- Next milestone calculator

### **3. Safety First Philosophy**
- Prevents premature high-intensity training
- Educates user on injury risk factors
- Provides actionable steps to unlock zones
- Tracks load ratios to prevent overtraining

### **4. Data-Driven Insights**
- 6-pillar breakdown with individual scores
- Recovery score based on sleep, fatigue, injuries
- Load metrics with Acute:Chronic ratio
- Risk level assessment with color coding

---

## 🧪 Testing Scenarios

### **Test Case 1: New Runner (Phase 1)**
- AISRI Score: 35 (Beginner)
- Unlocked Zones: AR, F
- Expected Behavior:
  - ✅ Only AR and F zones selectable
  - ✅ EN, TH, P, SP show lock icons
  - ✅ Tap locked zone → Shows "AISRI Score ≥ 40 required"
  - ✅ Phase 1 progress: 0/800km

### **Test Case 2: Intermediate Runner (Phase 2)**
- AISRI Score: 58 (Advanced)
- Total KM: 1200
- Unlocked Zones: AR, F, EN, TH
- Expected Behavior:
  - ✅ TH zone available (score ≥ 55)
  - ✅ P zone locked (needs score ≥ 70 + safety gate)
  - ✅ Phase 2 (Aerobic Development): 1200/1600km (50% complete)
  - ✅ Zone distribution: 65% F, 25% EN, 10% TH

### **Test Case 3: Advanced Runner (Phase 4)**
- AISRI Score: 73 (Advanced+)
- Total KM: 2850
- ROM Score: 78
- Load Ratio: 1.2
- No injuries
- Unlocked Zones: AR, F, EN, TH, P
- Expected Behavior:
  - ✅ P zone unlocked (all safety gate requirements met)
  - ✅ SP zone still locked (needs score ≥ 75 + all pillars ≥ 75)
  - ✅ Phase 4 (Interval Training): 2850/3200km (56% complete)
  - ✅ Safety Gates screen shows P unlocked, SP requirements partially met

### **Test Case 4: Elite Runner (Phase 5)**
- AISRI Score: 87 (Elite)
- Total KM: 3600
- All Pillars: ≥ 80
- Load Ratio: 1.1
- 15 weeks training including Power work
- Unlocked Zones: All (AR, F, EN, TH, P, SP)
- Expected Behavior:
  - ✅ SP zone unlocked (all requirements met)
  - ✅ Verification badge shown on P and SP zones
  - ✅ Phase 5 (Peak Performance): 3600/4000km (50% complete)
  - ✅ Weekly schedule includes all zone types

---

## 🎯 Why This Works

### **Scientific Foundation**

1. **Progressive Overload** - Gradual increase in training load (max 10% per week)
2. **Specificity** - Zone-based training targets specific physiological adaptations
3. **Recovery** - Adequate time between high-intensity sessions
4. **Individualization** - AISRI score adapts to each athlete's capabilities
5. **Injury Prevention** - Safety gates prevent premature intensity

### **Research-Backed Statistics**

- **80% of running injuries** result from:
  - Premature high-intensity training
  - Insufficient aerobic base
  - Poor biomechanics
  - Inadequate strength/mobility
  - Rapid load increases

- **Optimal load ratio** (0.8-1.3) reduces injury risk by **50%**
- **Threshold training** (TH zone) provides **maximum economy gains per time invested**
- **6-phase progression** ensures **systematic adaptation** without overtraining

---

## 🛠️ Deployment

### **Database Migration**

**Option 1: Supabase Dashboard (Recommended)**
1. Open your Supabase project dashboard
2. Navigate to **SQL Editor** (left sidebar)
3. Click **+ New query**
4. Copy the entire contents of `database/migration_AISRI_phase_tracking.sql`
5. Paste into the SQL Editor
6. Click **Run** (or press Ctrl+Enter)
7. Verify success: Should see "Success. No rows returned"

**Option 2: Command Line (If psql installed)**
```bash
# Replace with your actual Supabase connection details
psql -h [your-supabase-host].supabase.co -U postgres -d postgres -f database/migration_AISRI_phase_tracking.sql
```

**Verification Steps:**
- Check that 3 new tables exist: `AISRI_zone_history`, `AISRI_training_log`, `phase_transitions`
- Check that `profiles` table has 4 new columns: `lifetime_km_total`, `current_training_phase`, `phase_start_date`, `last_zone_unlock_date`
- Insert a test workout and verify `lifetime_km_total` updates automatically

### **Dependencies**
No additional packages required - uses Flutter Material Design and custom painters.

### **Environment**
- Flutter 3.5.0+
- Dart 3.0+
- Supabase PostgreSQL

---

## 📚 Future Enhancements

### **Phase 2 (Coming Soon)**
- [ ] **Weekly Schedule Generator** - Auto-generate week-by-week training plan
- [ ] **Workout Prescription** - AI-recommended workouts based on phase and AISRI
- [ ] **Phase Transition Notifications** - Alert when reaching new phase
- [ ] **Zone Performance Analytics** - Track pace and HR trends per zone
- [ ] **Form Analysis Integration** - Video-based running form assessment
- [ ] **Sleep & Recovery Tracking** - Integration with health apps
- [ ] **Social Features** - Compare progress with training partners
- [ ] **Coach Dashboard** - Monitor athlete progress remotely

### **Phase 3 (Long-term)**
- [ ] **Race Day Predictor** - Predict race times based on training
- [ ] **Injury Risk Alerts** - Proactive warnings before injury occurs
- [ ] **Smart Watch Integration** - Real-time HR zone monitoring
- [ ] **Nutrition Guidance** - Meal plans aligned with training phase
- [ ] **Community Challenges** - Group training events and milestones

---

## 🏆 Success Metrics

### **Key Performance Indicators**

1. **Injury Reduction**: Target 70% reduction in running injuries
2. **Adherence Rate**: 80%+ users completing weekly training
3. **Phase Progression**: Average 2 years from Phase 1 → Phase 6
4. **Zone Unlock Rate**: Optimal progression without premature unlocks
5. **User Satisfaction**: 4.5+ star rating for training effectiveness

---

## 📞 Support

For questions or issues:
- Technical: See code comments in respective files
- Conceptual: Refer to AISRI research papers (Economical Runner methodology)
- Implementation: Check [IMPLEMENTATION_STATUS.md](./IMPLEMENTATION_STATUS.md)

---

## 📄 License

SafeStride AISRI System © 2026

---

**Built with ❤️ for economical runners who value longevity over speed.**

*"The goal is not to run fast today, but to run forever."* 🏃‍♂️💚
