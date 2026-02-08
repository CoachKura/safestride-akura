# 🚀 Quick Deployment Checklist

## Step-by-Step Deployment Guide

### ✅ Step 1: Deploy Database Migration (5 minutes)

1. **Open Supabase Dashboard**: https://app.supabase.com
2. Navigate to: **SQL Editor** (left sidebar)
3. Click: **New Query**
4. **Copy** the entire contents from: `database/migration_aifri_assessments.sql`
5. **Paste** into SQL Editor
6. Click: **Run** (or press Ctrl+Enter)
7. **Verify** success message appears
8. Navigate to: **Table Editor** → Confirm `aifri_assessments` table exists

---

### ✅ Step 2: Test the Application (10 minutes)

#### A. Create New User Account
```bash
1. Run app: flutter run -d chrome
2. Click "Don't have an account? Sign up"
3. Fill form:
   - Full Name: Test Athlete
   - Email: test@example.com
   - Password: test123456
   - Role: Athlete
4. Click "Create Account"
```

**Expected Result**: ✅ Redirected to Evaluation Form Screen

---

#### B. Complete Evaluation Form

**Step 1 - Personal Info**:
- Age: 28
- Gender: Male
- Weight: 70 kg
- Height: 175 cm

**Step 2 - Training Background**:
- Years Running: 3
- Weekly Mileage: 40 km
- Training Frequency: 5-6 days/week
- Training Intensity: 7/10

**Step 3 - Injury History**:
- Past Injuries: "Minor shin splints last year"
- Current Pain: 2/10
- Months Injury-Free: 8

**Step 4 - Recovery**:
- Sleep Hours: 7.5
- Sleep Quality: 8/10
- Stress Level: 4/10

**Step 5 - Performance**:
- Recent 5K: 22:30
- Recent 10K: (optional)
- Recent Half: (optional)
- Fitness Level: Intermediate

**Step 6 - Goals**:
- Target Race: Half Marathon
- Target Date: 90 days from now
- Primary Goal: PR time

Click: **Complete Assessment**

**Expected Result**: 
✅ Success message: "Assessment completed successfully! 🎉"  
✅ Redirected to Dashboard Screen

---

#### C. Verify Data in Database

1. **Supabase Dashboard** → **Table Editor**
2. Select table: `aifri_assessments`
3. **Verify**: Your test data appears in the table
4. **Check**: `total_score` column has calculated AISRI score
5. Select table: `profiles`
6. **Verify**: `current_aifri_score` matches assessment score

---

#### D. Test Returning User Flow

1. **Log Out**: Profile screen → Log Out button
2. **Log Back In**: 
   - Email: test@example.com
   - Password: test123456
3. **Expected Result**: ✅ Goes directly to Dashboard (skips evaluation form)

---

### ✅ Step 3: Verify RLS (Row Level Security)

Test that users can only see their own assessments:

1. Create a **second test account**
2. Complete evaluation form with **different data**
3. Check Supabase Table Editor
4. **Verify**: Each user only sees their own assessment

---

## 🎯 Success Criteria

All of these should be ✅:

- [ ] Database migration runs without errors
- [ ] `aifri_assessments` table exists with correct columns
- [ ] `profiles.current_aifri_score` column exists
- [ ] New user registration → redirects to evaluation form
- [ ] Form validation works (try submitting empty fields)
- [ ] All 6 steps can be completed
- [ ] "Complete Assessment" button saves to database
- [ ] User redirected to Dashboard after completion
- [ ] Log out + log back in → goes to Dashboard directly
- [ ] Assessment data visible in Supabase Table Editor
- [ ] AISRI score calculated and stored
- [ ] RLS prevents users from seeing other users' data

---

## 🐛 Troubleshooting

### Issue: "Table aifri_assessments does not exist"
**Solution**: Re-run the SQL migration in Supabase Dashboard

### Issue: "Permission denied for table aifri_assessments"
**Solution**: Check RLS policies in migration file were applied correctly

### Issue: Form doesn't save / endless loading
**Solution**: 
1. Check browser console for errors
2. Verify Supabase connection in `lib/main.dart`
3. Check if user is authenticated before saving

### Issue: User stuck on evaluation form after completing
**Solution**:
1. Check if assessment was saved in database
2. Verify navigation logic in `evaluation_form_screen.dart` line 250
3. Check `AuthCheckScreen` query in `main.dart`

### Issue: App doesn't compile
**Solution**:
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

---

## 📊 Expected AISRI Score Range

Based on simplified calculation:

- **Low Risk** (70-100): Experienced runners, injury-free, good recovery
- **Moderate Risk** (40-70): Average fitness, some injury history, decent recovery
- **High Risk** (0-40): Recent injuries, poor recovery, high stress/pain

---

## 🔄 Next Phase Preview

After verifying this works:

**Phase 2 Tasks**:
1. Remove demo data from Dashboard (show real name, real AISRI score, real stats)
2. Connect Logger screen to save workouts to database
3. Show real workout history in History screen
4. Implement Strava OAuth integration

**Database Tables Needed for Phase 2**:
```sql
-- workouts table
CREATE TABLE workouts (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    activity_type VARCHAR(50),
    distance DECIMAL,
    duration INTEGER,
    rpe INTEGER,
    pain_level INTEGER,
    notes TEXT,
    route_data JSONB,
    created_at TIMESTAMP
);
```

---

## 📞 Support

If you encounter issues:

1. Check this guide's troubleshooting section
2. Review `docs/EVALUATION_FORM_IMPLEMENTATION.md` for detailed implementation notes
3. Inspect browser console for JavaScript errors
4. Check Supabase logs for database errors
5. Verify all files were saved correctly

---

**Ready to deploy? Start with Step 1!** 🚀
