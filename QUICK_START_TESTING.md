# 🚀 Quick Start Guide - Test Your Unified System

## ✅ What Changed (TL;DR)

**Before:** Connect Strava twice (Flutter app + HTML builder separately)  
**After:** Connect Strava ONCE → Both apps use same backend!

---

## 🎯 Test It Now!

### **Step 1: Run the Flutter App**

```bash
cd C:\safestride
flutter run -d chrome
```

### **Step 2: Test New User Flow**

1. Click **"Connect with Strava"**
2. Complete Strava OAuth
3. 🎉 **NEW**: You'll see evaluation form with **auto-filled data**:
   - Age ✓
   - Gender ✓
   - Weight ✓
4. Complete remaining questions
5. Submit assessment
6. See **Strava Home Dashboard** with your AISRI score!

### **Step 3: Test Training Plan**

1. From dashboard, click **"Training Plan"**
2. 🎉 **NEW**: You'll see an **AISRI Score Banner** at the top
3. Notice: Training volume is **automatically adjusted** based on your risk level:
   - Low Risk (AISRI ≥80): Full volume (100%)
   - Moderate Risk (AISRI 60-79): Reduced volume (85%)
   - High Risk (AISRI <60): Conservative volume (70%)

---

## 🔧 Setup Backend (Optional - For Full Testing)

### **Quick Setup**

```bash
cd C:\safestride\ai_agents

# Create .env file
echo SUPABASE_URL=https://xzxnnswggwqtctcgpocr.supabase.co > .env
echo SUPABASE_SERVICE_KEY=your_key >> .env
echo STRAVA_CLIENT_ID=your_id >> .env
echo STRAVA_CLIENT_SECRET=your_secret >> .env

# Install requirements
pip install fastapi uvicorn supabase httpx

# Run backend
python -m uvicorn unified_api_router:unified_router --reload --port 8000
```

### **Test Auto-AISRI Calculation**

```bash
# Run scheduler manually to test
python aisri_scheduled_updater.py
```

---

## 📊 Database Setup (One-Time)

Run this in your Supabase SQL editor:

```sql
CREATE TABLE IF NOT EXISTS athlete_aisri_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    aisri_score INTEGER NOT NULL,
    risk_level VARCHAR(20) NOT NULL,
    confidence INTEGER NOT NULL,
    pillar_adaptability INTEGER,
    pillar_injury_risk INTEGER,
    pillar_fatigue INTEGER,
    pillar_recovery INTEGER,
    pillar_intensity INTEGER,
    pillar_consistency INTEGER,
    calculation_method VARCHAR(50) NOT NULL,
    data_source VARCHAR(50),
    notes TEXT,
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_aisri_user_latest ON athlete_aisri_scores(user_id, calculated_at DESC);
```

---

## 🎬 Demo Scenario

### **New User Experience:**

1. **Launch App** → See login screen
2. **Click "Connect Strava"** → OAuth flow
3. **OAuth Completes** → See Strava stats screen
4. **Click "Let's Run!"** → **MAGIC HAPPENS:**
   - Form already shows your age, gender, weight! ✨
   - Green banner says "Data auto-filled from Strava"
5. **Complete Assessment** → AISRI calculated
6. **Go to Training Plan** → See volume adjusted to your risk level

### **Returning User Experience:**

1. **Launch App** → Auto-login
2. **Dashboard** → See latest AISRI score (auto-calculated weekly)
3. **Training Plan** → Volume already adjusted
4. **Open HTML Builder** (localhost:55854) → **SAME DATA!** No re-auth needed!

---

## 🔍 Quick Verification

### **Check Auto-Fill Works:**

```dart
// In evaluation_form_screen.dart, check initState()
// You should see:
_autoFillFromStrava() {
  if (widget.athleteData != null) {
    _ageController.text = athlete['age'].toString();
    _selectedGender = athlete['sex'] == 'M' ? 'Male' : 'Female';
    _weightController.text = athlete['weight'].toString();
  }
}
```

### **Check Training Plan Integration:**

```dart
// In strava_training_plan_screen.dart, check _buildPlan()
// You should see:
double volumeMultiplier = 1.0;
if (_aisriScore != null) {
  final aisriScore = _aisriScore!['aisri_score'] as int;
  if (aisriScore >= 80) volumeMultiplier = 1.0;      // Low risk
  else if (aisriScore >= 60) volumeMultiplier = 0.85; // Moderate
  else volumeMultiplier = 0.70;                       // High risk
}
```

---

## 🐛 Troubleshooting

### **"Evaluation form not showing auto-filled data"**

- Check console logs: Should see "Auto-filling evaluation form from Strava data"
- Verify athleteData is passed: Check navigation arguments in login_screen.dart
- Confirm athlete object has 'age', 'sex', 'weight' fields

### **"AISRI score not showing in training plan"**

- Check database: Query `athlete_aisri_scores` table
- Verify user_id matches current logged-in user
- Check console: Should see "Loaded AISRI score: XX"

### **"Backend not working"**

- Verify `.env` file has correct Supabase credentials
- Check port 8000 is not in use
- Test health endpoint: `curl http://localhost:8000/api/v2/health`

---

## 📚 Full Documentation

For complete details, see:

- **[IMPLEMENTATION_COMPLETE.md](IMPLEMENTATION_COMPLETE.md)** - What was implemented
- **[UNIFIED_ARCHITECTURE.md](UNIFIED_ARCHITECTURE.md)** - How it all works together

---

## ✨ Key Benefits You'll See

1. **No More Duplicate Auth**: Connect Strava once, works everywhere
2. **Instant Assessment**: Age, gender, weight auto-filled from Strava
3. **Smart Training Plans**: Volume adjusts to your injury risk automatically
4. **Weekly Updates**: AISRI scores refresh automatically every Sunday
5. **Unified Experience**: Flutter app + HTML builder share same data

---

**Ready to test?** Just run `flutter run -d chrome` and connect your Strava! 🎉
