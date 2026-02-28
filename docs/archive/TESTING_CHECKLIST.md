# 🎯 Adaptive Timeline Calculator - Testing Checklist

## ✅ Setup Complete

- [x] Core calculator service created (`lib/services/adaptive_pace_progression.dart`)
- [x] UI screen built (`lib/screens/pace_progression_screen.dart`)
- [x] Database service ready (`lib/services/progression_plan_service.dart`)
- [x] Dashboard widget created (`lib/widgets/pace_progression_widget.dart`)
- [x] Assessment integration complete
- [x] Web test page created
- [x] Flutter app running on http://localhost:3001
- [x] Test page running on http://localhost:8080

## 🧪 Testing Options

### Option 1: Quick Test (Recommended First!) ⚡

**URL**: http://localhost:8080/test-timeline-calculator.html

**What to test**:

1. Click "Calculate Timeline" for Beginner
   - Expected: ~52 weeks (12 months)
   - Current pace: 11:00/km → 3:30/km
2. Click "Calculate Timeline" for Intermediate
   - Expected: ~14 weeks (3.5 months)
   - Current pace: 6:00/km → 3:30/km
3. Click "Calculate Timeline" for Advanced
   - Expected: ~6 weeks (1.5 months)
   - Current pace: 4:30/km → 3:30/km
4. Try Custom values
   - Experiment with different paces, mileage, AISRI scores
   - See how timeline changes

**What you'll see**:

- ✅ Total weeks calculation
- ✅ Constraint analysis (pace vs mileage vs AISRI)
- ✅ Detailed breakdown with progress bars
- ✅ Key insights and recommendations

---

### Option 2: Full App Flow 📱

**URL**: http://localhost:3001

**Complete flow**:

1. Sign in to SafeStride
2. Complete evaluation form (18 assessment images)
3. View AISRI results screen
4. Click **"View Your Journey"** button
5. See beautiful timeline to 3:30/km!

**What you'll see**:

- ✅ Hero section with goal visualization
- ✅ Timeline summary (weeks, pace, mileage, AISRI)
- ✅ Current week focus
- ✅ Phase breakdown (Foundation → Goal Achievement)
- ✅ 7-day workout calendar
- ✅ "Start Your Journey" button

**📝 Note**: To save plans to database, run the SQL migration first (see below)

---

## 🗄️ Database Migration (Optional for Testing)

**Only needed if**: You want to test saving/loading progression plans

**Steps**:

1. Open Supabase Dashboard: https://app.supabase.com/project/bdisppaxbvygsspcuymb/editor
2. Click "SQL Editor"
3. Click "New Query"
4. Copy SQL from: `RUN_DATABASE_MIGRATION.md`
5. Click "Run"

---

## 📊 Expected Test Results

### Beginner Scenario

```
Input:
  Current Pace: 11:00/km
  Weekly Mileage: 10 km
  AISRI: 42

Output:
  Total Timeline: ~52 weeks (12 months)

Constraints:
  ✓ Pace improvement: 49 weeks (11:00→3:30 @ 0.15/week)
  ✓ Mileage build: 15 weeks (10→40 km @ max 10%/week)
  ✓ AISRI improvement: 17 weeks (42→75 @ 2 points/week)

Bottleneck: PACE IMPROVEMENT (slowest constraint)
```

### Intermediate Scenario

```
Input:
  Current Pace: 6:00/km
  Weekly Mileage: 35 km
  AISRI: 58

Output:
  Total Timeline: ~25 weeks (6 months)

Constraints:
  ✓ Pace improvement: 25 weeks (6:00→3:30 @ 0.10/week)
  ✓ Mileage build: 8 weeks (35→60 km @ max 10%/week)
  ✓ AISRI improvement: 9 weeks (58→75 @ 2 points/week)

Bottleneck: PACE IMPROVEMENT (slowest constraint)
```

### Advanced Scenario

```
Input:
  Current Pace: 4:30/km
  Weekly Mileage: 65 km
  AISRI: 78

Output:
  Total Timeline: ~7 weeks (1.75 months)

Constraints:
  ✓ Pace improvement: 7 weeks (4:30→3:30 @ 0.15/week)
  ✓ Mileage build: 2 weeks (65→80 km @ max 10%/week)
  ✓ AISRI improvement: 0 weeks (already above 75)

Bottleneck: PACE IMPROVEMENT (fastest possible!)
```

---

## 🔍 What to Verify

### Calculator Logic ✓

- [ ] Timeline increases with slower starting pace
- [ ] Timeline increases with lower AISRI score
- [ ] Timeline increases with lower starting mileage
- [ ] Minimum 3:30/km goal pace always enforced
- [ ] Safe 10% weekly mileage increase respected
- [ ] AISRI-based pace improvement rates applied correctly

### UI Display ✓

- [ ] Hero section shows current→goal pace
- [ ] Timeline summary displays correctly
- [ ] Current week focus is clear
- [ ] Phase breakdown is color-coded
- [ ] Workout calendar shows all 7 days
- [ ] Buttons are clickable and responsive

### Data Accuracy ✓

- [ ] Beginner timeline: 40-60 weeks
- [ ] Intermediate timeline: 10-20 weeks
- [ ] Advanced timeline: 5-10 weeks
- [ ] Constraint analysis shows bottleneck
- [ ] Weekly improvement rates match AISRI

---

## 🐛 Known Limitations

1. **Database not connected locally**: Migration needs to run in Supabase dashboard
2. **Samsung phone not connected**: Testing on web browser instead
3. **Unused imports**: Minor warnings in assessment_results_screen.dart

---

## 🎉 Success Criteria

**MVP Complete if**:

- ✅ Test page shows correct timelines for 3 scenarios
- ✅ Calculator respects all constraints (pace, mileage, AISRI)
- ✅ UI displays timeline, phases, and workouts
- ✅ No compilation errors
- ✅ Universal goal (3:30/km) enforced for all

**Full Integration Complete if**:

- ✅ All above MVP criteria
- ✅ Database migration runs successfully
- ✅ Plans can be saved and loaded
- ✅ Dashboard widget shows progress
- ✅ End-to-end flow works (evaluation→results→timeline)

---

## 📝 Test Scenarios to Try

### 1. Couch to 5K Runner

- Pace: 12:00/km
- Mileage: 5 km/week
- AISRI: 35
- Expected: ~60 weeks (very conservative)

### 2. Casual Jogger

- Pace: 8:00/km
- Mileage: 20 km/week
- AISRI: 50
- Expected: ~45 weeks

### 3. Regular Runner

- Pace: 5:30/km
- Mileage: 40 km/week
- AISRI: 65
- Expected: ~15 weeks

### 4. Experienced Runner

- Pace: 4:00/km
- Mileage: 70 km/week
- AISRI: 80
- Expected: ~4 weeks

---

## 💡 Testing Tips

1. **Start with test page** - Fastest way to see calculator in action
2. **Try extreme values** - Test with 15:00/km or 3:35/km to verify limits
3. **Check constraint analysis** - See which factor (pace/mileage/AISRI) is limiting
4. **Experiment with custom values** - Find your own timeline!
5. **Note the differences** - Higher AISRI = faster timeline

---

## 🚀 Next Steps After Testing

1. **If calculator works**: Run database migration, test full app flow
2. **If issues found**: Report specific scenarios that fail
3. **If all good**: Add dashboard widget, test progress tracking
4. **If ready for production**: Deploy to mobile app

---

## 📞 Questions?

Review these docs:

- `ADAPTIVE_TIMELINE_CALCULATOR.md` - Full implementation details
- `IMPROVED_ONBOARDING_FLOW.md` - Complete vision and phases
- `RUN_DATABASE_MIGRATION.md` - Database setup instructions

---

**Ready to Test? Open http://localhost:8080/test-timeline-calculator.html! 🎯**
