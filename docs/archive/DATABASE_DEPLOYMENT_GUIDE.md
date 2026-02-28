# 🚀 AI AGENT DATABASE DEPLOYMENT GUIDE

## ✅ Fixed the Schema Issue
Changed `ai_decisions` table from UUID to TEXT athlete_id to match all other tables and agents.

## 📋 Deployment Steps

### Step 1: Deploy Database Tables

1. **Open Supabase SQL Editor**
   - Go to: https://app.supabase.com/project/bdisppaxbvygsspcuymb/sql
   - Click "New Query"

2. **Copy and Paste the SQL**
   - Open: `c:\safestride\supabase\migrations\DEPLOY_ALL_TABLES.sql`
   - Copy ALL content (Ctrl+A, Ctrl+C)
   - Paste into Supabase SQL Editor

3. **Run the Query**
   - Click "Run" button or press Ctrl+Enter
   - Wait for completion (~10-15 seconds)
   - You should see "Success. No rows returned" message

4. **Verify Tables Created**
   - Scroll down to verification queries section
   - You should see:
     ```
     AISRI_assessments: 3 rows
     training_load_metrics: 14 rows
     injury_risk_predictions: 0 rows
     workouts: 24 rows
     race_predictions: 0 rows
     ai_decisions: 0 rows
     ```

### Step 2: Test All Endpoints

1. **Ensure FastAPI is Running**
   ```powershell
   # Check if server is running
   Invoke-RestMethod -Uri "http://localhost:8001" -Method Get
   # Should return: {"status":"AISRi AI Engine Running"}
   ```

2. **Run Test Script**
   ```powershell
   cd C:\safestride
   .\test-all-endpoints.ps1
   ```

3. **Expected Results**
   - ✓ List Athletes: Found 7 athletes
   - ✓ Predict Injury Risk: Returns LOW/MODERATE/HIGH with recommendation
   - ✓ Autonomous Decision: Returns TRAIN/REST/RECOVERY/INTENSIFY/LIGHT_TRAIN
   - ✓ Predict Performance: Returns VO2max and race times
   - ✓ Generate Workout: Returns workout details
   - ✓ Generate Training Plan: Returns 7-day plan

## 🗃️ Database Schema Overview

### Tables Created:
1. **AISRI_assessments** - AISRI scores and pillar data
2. **training_load_metrics** - Training load tracking (last 7 days used)
3. **injury_risk_predictions** - AI-generated injury risks
4. **workouts** - Workout data with pace (last 20 used)
5. **race_predictions** - Performance predictions
6. **ai_decisions** - Daily coaching decisions

### Sample Data Inserted:
- **2 test athletes** from profiles table:
  - 33308fc1-3545-431d-a5e7-648b52e1866c (Muthulakshmi) - 20 workouts
  - cf77e535-a46b-4a25-b035-4e7c2a458e7a (KRISHNAKUMAR) - 4 workouts
- **AISRI scores** for both athletes
- **7 days of training load** for both athletes
- **Average pace ~350-360 sec/km** (5:50-6:00 min/km)

## 🎯 Next Steps After Deployment

### 1. Add More Athletes
```sql
-- Add AISRI and workout data for other 5 athletes from profiles table
INSERT INTO "AISRI_assessments" (athlete_id, aisri_score, pillars)
VALUES ('5ca7cfd9-2b06-4830-a6be-9dedd194976f', 60, '{"running": 60, "strength": 60, "rom": 60, "balance": 60, "alignment": 60, "mobility": 60}'::jsonb);
```

### 2. Setup n8n Workflow
```powershell
# Install n8n (if not done)
npm install -g n8n

# Start n8n
n8n
```

Then create workflow:
- **Trigger**: Cron (0 4 * * * = 4:00 AM daily)
- **Node 1**: HTTP Request to /agent/commander (list_athletes)
- **Node 2**: Split Out to loop through athletes
- **Node 3**: HTTP Request to /agent/autonomous-decision for each athlete
- **Node 4**: Filter HIGH risk decisions and send alerts

### 3. Integrate with Strava
- Import 905 workouts from athlete_1771670436116
- Auto-populate workouts table from Strava webhook
- Calculate training load from activity data

### 4. Mobile App Testing
- Update Flutter service IPs to 192.168.1.13 if needed
- Test from mobile device
- Add UI screens for: Dashboard, Performance, Training, Profile

## 🐛 Troubleshooting

### If endpoints still fail:
1. **Check FastAPI logs** - Look for Python exceptions
2. **Verify tables exist** - Go to Supabase Table Editor
3. **Check sample data** - Query tables to ensure data inserted
4. **Test Supabase connection** - Check SUPABASE_URL and SUPABASE_KEY in .env

### If no workout data error:
```sql
-- Check workouts table
SELECT * FROM workouts WHERE athlete_id = '33308fc1-3545-431d-a5e7-648b52e1866c';
-- Should return 20 rows
```

### If AISRI not found:
```sql
-- Check AISRI table
SELECT * FROM "AISRI_assessments" WHERE athlete_id = '33308fc1-3545-431d-a5e7-648b52e1866c';
-- Should return 2 rows
```

## 📊 Validation Queries

```sql
-- Get latest AISRI for all athletes
SELECT athlete_id, aisri_score, created_at 
FROM "AISRI_assessments" 
ORDER BY created_at DESC;

-- Get average training load (last 7 days)
SELECT athlete_id, AVG(load_score) as avg_load
FROM training_load_metrics
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY athlete_id;

-- Get workout pace statistics
SELECT athlete_id, 
       COUNT(*) as workout_count,
       AVG(average_pace) as avg_pace,
       MIN(average_pace) as best_pace
FROM workouts
GROUP BY athlete_id;
```

## ✨ Success Criteria

✅ All 6 tables created successfully  
✅ Sample data inserted (2 athletes, 24 workouts, 14 load metrics)  
✅ All 6 endpoints return successful responses  
✅ No Internal Server Errors  
✅ Data saves to database (check injury_risk_predictions, race_predictions, ai_decisions)  

## 📝 Notes

- All tables use TEXT athlete_id for consistency
- RLS policies allow public read (for testing)
- All migrations are idempotent (safe to run multiple times)
- Sample data uses ON CONFLICT DO NOTHING (won't duplicate)
