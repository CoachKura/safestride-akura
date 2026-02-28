# AISRI Biomechanics & AI Analysis Guide

## 🔬 How AISRI Pillars Affect Running Performance

### **The Complete Biomechanical Chain**

```
AISRI Pillars → Running Mechanics → Performance Metrics → Injury Risk
```

---

## 1️⃣ Range of Motion (ROM) Pillar

### **What ROM Measures:**
- Joint flexibility across 10 body regions
- Based on clinical ROM testing protocols
- Scored 0-100 (100 = optimal for running)

### **ROM → Running Metrics Connection:**

#### **Stride Length Impact:**
```
Hip Flexion ROM:
  120°+ (Optimal) → Full stride extension → 2.0m stride
  90°  (Limited)  → Restricted stride  → 1.5m stride  
  60°  (Poor)     → Very short stride  → 1.2m stride

Result: 30% loss in stride length = Slower pace OR more energy expenditure
```

#### **Vertical Oscillation Impact:**
```
Ankle Dorsiflexion ROM:
  20°+ (Optimal) → Efficient heel strike → 6cm vertical oscillation
  10°  (Limited) → Bouncing gait      → 9cm vertical oscillation
  5°   (Poor)    → Excessive bounce   → 12cm vertical oscillation

Result: 100% increase in vertical movement = Wasted energy going UP instead of FORWARD
```

#### **Ground Contact Time:**
```
Ankle Plantarflexion ROM:
  50°+ (Optimal) → Quick push-off     → 200ms contact time
  30°  (Limited) → Delayed push-off   → 250ms contact time
  20°  (Poor)    → Prolonged contact  → 300ms contact time

Result: 50% longer ground contact = Reduced running economy
```

### **ROM Testing Protocol (Based on Clinical Standards):**

**Hip Flexion Test:**
- Lie on back, bring knee to chest
- Measure angle between thigh and torso
- **Target**: 120° (excellent), 90° (adequate), <70° (poor)
- **Affects**: Stride length (most important factor)

**Hip Extension Test:**
- Lie on stomach, lift leg backward
- Measure angle behind body
- **Target**: 30° (excellent), 20° (adequate), <10° (poor)
- **Affects**: Push-off power, stride length

**Ankle Dorsiflexion Test:**
- Standing, lean forward with heel on ground
- Measure shin angle to floor
- **Target**: 20° (excellent), 15° (adequate), <10° (poor)
- **Affects**: Vertical oscillation, landing mechanics

---

## 2️⃣ Mobility Pillar

### **What Mobility Measures:**
- Dynamic movement quality
- Multi-joint coordination
- Functional movement patterns

### **Mobility → Running Metrics Connection:**

#### **Energy Transfer Efficiency:**
```
Good Mobility (80-100 score):
  → Smooth kinetic chain
  → 5% energy loss through compensations
  → Running economy = 200 ml/kg/km

Poor Mobility (0-40 score):
  → Broken kinetic chain
  → 20% energy loss through compensations
  → Running economy = 240 ml/kg/km (20% worse)
```

#### **Cadence Impact:**
```
Hip Mobility:
  Excellent → Quick hip turnover → 180 spm cadence
  Poor      → Slow hip rotation  → 160 spm cadence

Result: Lower cadence = Longer ground contact = Higher impact forces
```

---

## 3️⃣ Alignment Pillar

### **What Alignment Measures:**
- Static postural alignment
- Dynamic biomechanical alignment
- Joint loading patterns

### **Alignment → Injury Risk Connection:**

```
Knee Valgus (Knock-knee):
  Normal alignment → 2.5x body weight knee load
  5° valgus        → 3.5x body weight knee load
  10° valgus       → 5.0x body weight knee load

Result: 2x overload on medial knee → Tibial stress fracture risk
```

#### **Ground Reaction Force Distribution:**
```
Neutral Alignment:
  ├── Heel: 35% impact
  ├── Midfoot: 30% impact
  └── Forefoot: 35% impact

Poor Alignment (Overpronation):
  ├── Heel: 45% impact (overload)
  ├── Midfoot: 40% impact (overload)
  └── Forefoot: 15% impact (underload)

Result: Uneven loading → Plantar fasciitis, tibial stress
```

---

## 4️⃣ Balance Pillar

### **What Balance Measures:**
- Single-leg stability
- Proprioception
- Neuromuscular control

### **Balance → Running Efficiency Connection:**

```
Single-Leg Stand Test:
  >30s (Excellent) → Stable landing → 2% energy loss
  15-30s (Good)    → Slight wobble  → 5% energy loss
  <15s (Poor)      → Unstable       → 12% energy loss

Result: Poor balance = Micro-corrections every step = Wasted energy
```

#### **Propulsion Efficiency:**
```
Good Balance:
  → 90% force vector forward
  → Minimal lateral movement

Poor Balance:
  → 70% force vector forward
  → 20% wasted on side-to-side corrections
```

---

## 5️⃣ Strength Pillar

### **What Strength Measures:**
- Muscle force generation
- Power output
- Endurance under load

### **Strength → Stride Metrics Connection:**

```
Glute Strength:
  Strong (100% max) → 2.2m stride length
  Moderate (70%)    → 1.8m stride length
  Weak (40%)        → 1.4m stride length

Result: 36% loss in stride length = Dramatically slower pace
```

#### **Hill Running:**
```
Leg Strength Index:
  High strength → 5% pace loss on 5% gradient
  Low strength  → 25% pace loss on 5% gradient
```

---

## 6️⃣ Running Pillar (Cardiovascular Fitness)

### **What Running Measures:**
- VO2max
- Lactate threshold
- Running economy
- Training volume

### **Running Metrics:**
- Calculated from Strava activity history
- Training load (acute:chronic ratio)
- Personal bests and trends

---

## 🤖 What The AI Is Doing

### **Phase 1: Data Collection**
```python
# From Strava OAuth
activities = fetch_strava_activities(athlete_id)
running_volume = sum([a.distance for a in activities if a.type == "Run"])
avg_pace = mean([a.pace for a in activities])
personal_bests = extract_pr_times(activities)

# From Evaluation Form
pillars = {
  "running": auto_calculated_from_strava,  # 0-100
  "strength": athlete_assessment,          # 0-100
  "rom": athlete_assessment,               # 0-100
  "balance": athlete_assessment,           # 0-100
  "alignment": athlete_assessment,        # 0-100
  "mobility": athlete_assessment          # 0-100
}
```

### **Phase 2: AISRI Score Calculation**
```python
# Weighted formula (total = 0-1000 scale)
aisri_score = (
  pillars["running"] * 0.40 +    # 40% weight (most important)
  pillars["strength"] * 0.15 +   # 15% weight
  pillars["rom"] * 0.12 +        # 12% weight
  pillars["balance"] * 0.13 +    # 13% weight
  pillars["alignment"] * 0.10 +  # 10% weight
  pillars["mobility"] * 0.10     # 10% weight
) * 10  # Scale to 0-1000

# Risk categorization
if aisri_score >= 850:
    risk = "Very Low" (AR zone - Active Recovery only)
elif aisri_score >= 700:
    risk = "Low" (F zone - Foundation training)
elif aisri_score >= 550:
    risk = "Medium" (EN zone - Endurance training)
elif aisri_score >= 400:
    risk = "High" (TH zone - Threshold training)
else:
    risk = "Critical" (P zone - Peak/Power training)
```

### **Phase 3: Biomechanical Analysis**
```python
# Analyze weak pillars and predict affected metrics
if pillars["rom"] < 50:
    predictions.add({
      "issue": "Limited Hip ROM",
      "impact": "Stride length reduced by ~25%",
      "fix": "Hip flexor stretching 3x/week",
      "injury_risk": "Hamstring strain (High)"
    })

if pillars["mobility"] < 50:
    predictions.add({
      "issue": "Poor Hip Mobility",
      "impact": "Vertical oscillation +40%",
      "fix": "Dynamic mobility drills pre-run",
      "injury_risk": "IT band syndrome (High)"
    })

if pillars["alignment"] < 50:
    predictions.add({
      "issue": "Knee Valgus",
      "impact": "Knee loading +80%",
      "fix": "Glute strengthening, gait retraining",
      "injury_risk": "Patellofemoral pain (Critical)"
    })
```

### **Phase 4: ML Insights Generation**
```python
# Pattern detection from activity history
ml_analyzer.analyze({
  "training_load_ratio": acute_load / chronic_load,
  "recent_activities": last_30_days,
  "hrv_trend": hrv_data,
  "sleep_quality": sleep_data
})

# Generate insights
if training_load_ratio > 1.5:
    insights.add({
      "type": "danger",
      "message": "Excessive training load. 60% increased injury risk.",
      "action": "Reduce volume by 30% this week"
    })
```

### **Phase 5: Training Plan Generation**
```python
# Determine safe training zones
allowed_zones = aisriEngine.getAllowedZones(aisri_score)

# Generate 12-week periodized plan
training_plan = aiTrainingGenerator.generatePlan({
  "weeks": 12,
  "goal": athlete_goal,  # "5K PR", "Marathon", "Base Building"
  "aisri_score": aisri_score,
  "weak_pillars": [p for p in pillars if pillars[p] < 60],
  "available_zones": allowed_zones
})

# Plan structure:
# - Week 1-4: Foundation (60% easy, 20% moderate, 20% strength)
# - Week 5-8: Build (50% easy, 30% moderate, 20% quality)
# - Week 9-11: Peak (40% easy, 30% quality, 30% race-specific)
# - Week 12: Taper (70% easy, 30% race-pace)
```

### **Phase 6: Real-Time Monitoring**
```python
# After each run, recalculate
new_activities = fetch_new_activities_since_last_sync()
updated_aisri = recalculate_aisri(pillars, new_activities)

# Detect early warning signs
if updated_aisri < previous_aisri - 50:
    alert("Significant AISRI drop! Possible fatigue or injury.")
    recommend("Take 2-3 recovery days")
```

---

## 📊 Complete Example: How Poor ROM Affects Everything

### **Athlete Profile:**
- ROM Score: 35/100 (Poor)
- Hip Flexion: 70° (Normal: 120°)
- Ankle Dorsiflexion: 8° (Normal: 20°)

### **Cascade of Effects:**

```
1. Limited Hip ROM (70° vs 120°)
   ↓
2. Stride Length Reduced (1.4m vs 2.0m) = 30% shorter
   ↓
3. To Maintain Speed: Must increase cadence (180 spm → 230 spm)
   ↓
4. Higher Cadence = More Ground Contacts = More Impact
   ↓
5. Poor Ankle ROM = Inefficient Landing
   ↓
6. Body Compensates with Vertical Bounce (12cm vs 6cm)
   ↓
7. Wasted Energy Going UP instead of FORWARD
   ↓
8. Running Economy Worsens by 25%
   ↓
9. Same Pace Requires 25% More Energy
   ↓
10. Early Fatigue → Form Breakdown → Injury Risk
```

### **AI Recommendations:**
```
Immediate Actions:
1. Reduce training volume by 40%
2. Add daily hip flexor stretching (3x 2min holds)
3. Incorporate ankle mobility drills
4. Strength train glutes 2x/week

Expected Improvements (8 weeks):
- Hip ROM: 70° → 100° (+43%)
- Stride length: 1.4m → 1.8m (+29%)
- Vertical oscillation: 12cm → 8cm (-33%)
- Running economy: +15% improvement
```

---

## 🎯 Summary: Why AISRI Works

**Traditional Approach:**
- Train until injury
- React to pain
- No predictive capability

**AISRI Approach:**
- Measure 6 biomechanical pillars
- Calculate injury risk score (0-1000)
- Predict which metrics are affected
- Prescribe corrective exercises
- Generate safe training zones
- Monitor in real-time
- Prevent injuries BEFORE they happen

**The AI connects:**
1. ROM limitations → Stride mechanics
2. Mobility issues → Energy waste
3. Alignment problems → Joint overload
4. Balance deficits → Instability
5. Strength gaps → Power loss
6. Training load → Fatigue accumulation

**Result:** Personalized training that maximizes performance while minimizing injury risk.
