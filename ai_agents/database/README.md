# 🗄️ Database Schema for Athlete Lifecycle Management System

## 📋 Quick Reference

This folder contains the complete database schema for the **Athlete Lifecycle Management System** - from signup through progressive training with daily adaptation.

---

## 📁 Files

### **athlete_lifecycle_schema.sql** 
Complete SQL schema with 6 tables, 3 views, 2 functions, and 6 triggers.

**To apply to Supabase:**
```sql
-- Copy entire file and paste into Supabase SQL Editor
-- Execute to create all tables and supporting structures
```

### **MIGRATION_GUIDE.md**
Step-by-step guide for applying the schema to your Supabase instance, including:
- Migration instructions (3 methods)
- Verification checklist
- Test data examples
- Troubleshooting

---

## 🗂️ Tables Overview

| Table | Purpose | Key Features |
|-------|---------|--------------|
| **athlete_detailed_profile** | Complete athlete information | Before/after signup baseline, goals, assessment status |
| **baseline_assessment_plan** | 14-day structured assessment | Daily workouts, expected performance, completion tracking |
| **daily_performance_tracking** | **GIVEN \| EXPECTED \| RESULT** | Performance labels (BEST/GREAT/GOOD), ability deduction, AI analysis |
| **adaptive_workout_generation** | Smart workout generation | Based on previous performance, 80% HR focus, injury prevention |
| **athlete_ability_progression** | Daily ability deduction | Overall score, component scores, goal progress, injury risk |
| **existing_athlete_import** | CSV import management | Google Forms integration, onboarding tracking |

---

## 🎯 Key Concepts

### **BEFORE Signup Baseline**
Captured from Strava history (last 90 days):
- Weekly volume (km)
- Average pace
- Runs per week
- Consistency score
- Longest run

### **Athlete Classification**
Automatic classification based on baseline:
- **Beginner**: < 20km/week, pace > 7:00/km
- **Intermediate**: 20-50km/week, pace 5:30-7:00/km
- **Advanced**: > 50km/week, pace < 5:30/km

### **14-Day Baseline Assessment**
Structured plan to learn athlete's true capability:
- Days 1-4: Easy runs + ROM (baseline fitness)
- Days 5-7: Tempo runs (lactate threshold)
- Days 8-10: Intervals (speed capability)
- Days 11-12: Strength assessment
- Days 13-14: Long run + rest

### **GIVEN | EXPECTED | RESULT Tracking**
Daily performance comparison:
- **GIVEN**: What was assigned (workout prescription)
- **EXPECTED**: What should be achieved (performance targets)
- **RESULT**: What actually happened (from Strava/Garmin)

**Performance Labels:**
- **BEST**: > 110% of expected
- **GREAT**: 105-110% of expected
- **GOOD**: 95-105% of expected
- **AVERAGE**: 85-95% of expected
- **POOR**: 70-85% of expected
- **NEEDS_ATTENTION**: < 70% of expected

### **Adaptive Workout Generation**
Next workout adapts based on performance:
```
IF BEST → +10% progression
IF GREAT → +5% progression
IF GOOD → Maintain level
IF AVERAGE → -10% intensity
IF POOR → Easy day or rest
```

### **80% Heart Rate Focus**
All workouts target 80% max HR:
- Builds aerobic base
- Injury-free training
- Sustainable pace development

### **Daily Ability Deduction**
System learns athlete capability daily:
- Overall ability score (0-100)
- Component scores (endurance, speed, strength, form, consistency)
- Goal readiness percent
- Injury risk level

---

## 🔍 Views

### **athlete_current_status**
Quick overview of all athletes:
```sql
SELECT * FROM athlete_current_status 
WHERE baseline_assessment_status = 'in_progress';
```

### **recent_performance_summary**
Last 7 days per athlete:
```sql
SELECT * FROM recent_performance_summary 
WHERE avg_performance_score > 80;
```

### **upcoming_workouts**
Scheduled future workouts:
```sql
SELECT * FROM upcoming_workouts 
WHERE athlete_id = 'YOUR-ATHLETE-ID';
```

---

## 🔧 Functions

### **calculate_performance_label(actual_vs_expected, completion_pct, hr_adherence)**
Automatically determines performance label from metrics.

### **update_updated_at_column()**
Automatically updates `updated_at` timestamp (applied via triggers).

---

## 📊 Example Workflow

### **1. Athlete Signup**
```sql
-- Insert detailed profile
INSERT INTO athlete_detailed_profile (
    athlete_id, current_level, primary_goal, 
    goal_type, goal_target_time, target_race_date,
    before_signup_weekly_volume_km, before_signup_avg_pace
) VALUES (...);

-- Generate 14-day plan
INSERT INTO baseline_assessment_plan (...);
```

### **2. Daily Workout Tracking**
```sql
-- Track workout completion
INSERT INTO daily_performance_tracking (
    athlete_id, workout_date, workout_type,
    given_workout, expected_performance, 
    actual_duration_minutes, actual_distance_km, actual_avg_pace,
    performance_label, performance_score
) VALUES (...);

-- Update ability progression
INSERT INTO athlete_ability_progression (
    athlete_id, overall_ability_score, 
    goal_readiness_percent, injury_risk_level
) VALUES (...);
```

### **3. Generate Next Workout**
```sql
-- Adaptive workout based on previous performance
INSERT INTO adaptive_workout_generation (
    athlete_id, scheduled_date, workout_type,
    workout_plan, based_on_performance_ids,
    progressive_overload_percent, target_hr_zone
) VALUES (...);
```

---

## 🚀 Quick Start

1. **Apply Schema**: Copy `athlete_lifecycle_schema.sql` → Paste in Supabase SQL Editor → Execute
2. **Verify**: Check [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) verification checklist
3. **Test**: Insert sample data (examples in MIGRATION_GUIDE.md)
4. **Use**: Import `athlete_onboarding.py` module in your Python code

---

## 📚 Related Documentation

- [ATHLETE_LIFECYCLE_SYSTEM.md](../ATHLETE_LIFECYCLE_SYSTEM.md) - Complete system architecture
- [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) - Detailed migration instructions
- [athlete_onboarding.py](../athlete_onboarding.py) - Python module for signup & baseline

---

## 🎯 Ultimate Goal

**"Every athlete runs at their goal pace in 80% HR zone, finishes strong in all races, INJURY-FREE"**

This database schema is designed to support that vision through systematic tracking, adaptive training, and injury prevention.

---

**Questions?** Check the [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) troubleshooting section or review the inline SQL comments in [athlete_lifecycle_schema.sql](athlete_lifecycle_schema.sql).
