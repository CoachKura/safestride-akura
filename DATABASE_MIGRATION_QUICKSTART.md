# 🗄️ Database Migration Quick Start

## Problem Fixed

The error **"relation 'aisri_assessments' does not exist"** happened because:

- The table name is `"AISRI_assessments"` (with **capital letters** and **quotes**)
- The table exists but **doesn't have all the columns** the Flutter app needs

## ✅ Solution: Complete Migration

### **Option 1: Run from Supabase SQL Editor** (Recommended)

1. **Open Supabase Dashboard**: https://app.supabase.com/project/xzxnnswggwqtctcgpocr/editor
2. **Go to SQL Editor** (left sidebar)
3. **Copy the entire file**: `supabase/migrations/20260227_add_agility_pillar.sql`
4. **Paste into SQL Editor**
5. **Click "Run"** (bottom right)

### **Option 2: Run from PowerShell**

```powershell
# Navigate to project
cd C:\safestride

# Run the migration
Get-Content supabase\migrations\20260227_add_agility_pillar.sql | npx supabase db execute

# OR let Supabase CLI auto-apply all migrations
npx supabase db push
```

---

## 📋 What This Migration Does

### **Adds ALL Missing Columns**:

**Personal Info**:

- user_id, age, gender, weight, height

**Training Background**:

- years_running, weekly_mileage, training_frequency, training_intensity

**Injury History**:

- injury_history, current_pain, months_injury_free

**Recovery Metrics**:

- sleep_hours, sleep_quality, stress_level

**Performance Data**:

- recent_5k_time, recent_10k_time, recent_half_time, fitness_level

**Physical Assessments (15 tests)**:

- Lower Body: ankle_dorsiflexion_cm, knee_flexion_gap_cm, knee_extension_strength, hip_flexion_angle, hip_abduction_reps, hamstring_flexibility_cm
- Core & Balance: balance_test_seconds, plank_hold_seconds
- Upper Body: shoulder_flexion_angle, shoulder_abduction_angle, shoulder_internal_rotation, neck_rotation_angle, neck_flexion
- Cardio: resting_hr, perceived_fatigue

**Pillar Scores (7 pillars including NEW Agility)**:

- pillar_adaptability
- pillar_injury_risk
- pillar_fatigue
- pillar_recovery
- pillar_intensity
- pillar_consistency
- **pillar_agility** ← NEW! 7th pillar

**Improvement Tracking**:

- improvement_from_previous
- biggest_gain
- focus_area

**Goals**:

- target_race_distance, target_race_date, primary_goal

### **Creates New Table**:

- `reassessment_reminders` for 25-day reminder system

### **Updates Security**:

- Adds RLS policies for user_id-based access
- Creates indexes for better performance

---

## ✅ Verification After Migration

Run this query in Supabase SQL Editor to verify:

```sql
-- Check if all columns exist
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'AISRI_assessments'
ORDER BY ordinal_position;
```

**Expected columns** (should see ~50+ columns including):

- user_id
- age, gender, weight, height
- pillar_adaptability through **pillar_agility** (7 pillars!)
- All physical assessment columns
- improvement_from_previous, biggest_gain, focus_area

---

## 🧪 Test After Migration

### **Test 1: Check Agility Pillar**

```sql
-- Should return pillar_agility column
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'AISRI_assessments'
AND column_name = 'pillar_agility';
```

### **Test 2: Check Reassessment Reminders Table**

```sql
-- Should return the table
SELECT * FROM reassessment_reminders LIMIT 1;
```

### **Test 3: Insert Test Record** (Optional)

```sql
-- Try inserting a test assessment
INSERT INTO "AISRI_assessments" (
    athlete_id,
    user_id,
    age,
    gender,
    weight,
    aisri_score,
    pillar_adaptability,
    pillar_injury_risk,
    pillar_fatigue,
    pillar_recovery,
    pillar_intensity,
    pillar_consistency,
    pillar_agility  -- NEW!
) VALUES (
    'test_athlete_123',
    auth.uid(),  -- Current user
    30,
    'Male',
    70.5,
    75,
    80, 75, 70, 85, 80, 90, 78  -- All 7 pillar scores
) RETURNING id, aisri_score, pillar_agility;

-- Clean up test record
DELETE FROM "AISRI_assessments" WHERE athlete_id = 'test_athlete_123';
```

---

## 🚨 Troubleshooting

### **Error: "column already exists"**

✅ **This is OK!** The migration uses `ADD COLUMN IF NOT EXISTS` so it's safe to run multiple times.

### **Error: "permission denied"**

- Make sure you're running this in the **Supabase SQL Editor** (not locally)
- Or use the **service role** if running from command line

### **Error: "relation does not exist" (still)**

- Check you're connected to the correct Supabase project
- Verify the table name: `"AISRI_assessments"` (with capital letters and quotes)

### **Table name confusion**

Your database has: `"AISRI_assessments"` (capital letters, quoted)
Flutter code uses: `.from('AISRI_assessments')` ✅ (matches!)

---

## 🎯 Next Steps After Migration

1. **✅ Run the Flutter app**: The assessment form should now save successfully
2. **✅ Complete 1st assessment**: Should navigate to Dashboard
3. **✅ Wait or simulate 25 days**: Change database date to test reminder
4. **✅ Complete 2nd assessment**: Should show Improvement Screen with all 7 pillars

---

## 📊 Schema Before vs After

### **Before Migration**:

```sql
"AISRI_assessments": id, athlete_id, aisri_score, pillars (JSONB), created_at
```

❌ Only 5 columns, pillars stored as JSONB

### **After Migration**:

```sql
"AISRI_assessments":
  - 50+ individual columns
  - All 7 pillar scores as separate INTEGER columns
  - All physical assessment results
  - Improvement tracking
  - User authentication (user_id)
```

✅ Full schema matching Flutter app expectations!

---

## 💡 Why This Migration Was Needed

The original Flutter app design expects a **detailed relational schema** with individual columns for each piece of data. This allows for:

- Better querying (filter by age, gender, specific pillars)
- Easier analytics and reporting
- Type safety and constraints
- SQL joins and aggregations
- Improvement tracking between assessments

The simple JSONB approach works for AI agents but doesn't support the full Flutter app features like:

- 25-day reminders
- Improvement tracking
- Running dynamics correlation
- Per-pillar analysis

---

## 🎉 Migration Complete!

Your database now supports:

- ✅ All 7 AISRI pillars (including Agility)
- ✅ Complete assessment data storage
- ✅ 25-day re-assessment reminders
- ✅ Improvement tracking
- ✅ User-based security (RLS)
- ✅ Optimized indexes for performance

**Ready to test the Flutter app!** 🚀
