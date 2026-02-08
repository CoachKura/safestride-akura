# SafeStride - Quick Start Guide for GPS Integration & V.O2 Data

**Last Updated:** February 5, 2026  
**Time to Complete:** 15 minutes  

---

## 🎯 WHAT YOU NEED TO DO

You have **2 immediate options** based on your requirements:

### Option 1: Test with Mock Data (Fastest - 2 minutes)
**Best for:** Quick testing without real GPS data

1. **Hot reload your Flutter app:**
   ```bash
   cd "E:\Akura Safe Stride\safestride\akura_mobile"
   r  # If already running
   # OR
   flutter run -d chrome  # If not running
   ```

2. **Open Profile screen → Tap "Generate Protocol"**
   - Uses test athlete mock data (151 spm, 27.2 km/week)
   - Generates 6 workouts
   - Shows success dialog with protocol details

3. **Expected Result:**
   ```
   ✅ Protocol Generated Successfully!
   
   Cadence Optimization Protocol
   2 weeks • 3 workouts/week
   Focus: Cadence, Mobility
   
   Analysis:
   Cadence: 151 spm (Low - needs improvement)
   Weekly Distance: 27.2 km/week
   AISRI Score: 52/100
   
   6 workouts scheduled to your calendar
   ```

---

### Option 2: Connect Real GPS Watch (15 minutes)
**Best for:** Getting real athlete data from Garmin/Coros/Strava

#### Step 1: Run Database Migration
```sql
-- In Supabase SQL Editor:
-- Copy and paste: database/migration_gps_watch_integration.sql
-- Click "RUN"
-- Expected: Migration successful (4 tables + 2 views created)
```

#### Step 2: Set Up OAuth for Your Platform

**For Garmin Connect:**
1. Go to https://developer.garmin.com/
2. Register app (Name: SafeStride)
3. Get OAuth credentials
4. Implement OAuth flow in Flutter

**For Strava (Already set up):**
1. You already have Strava OAuth credentials
2. Just need to implement connection flow

**For Coros:**
1. Go to https://open.coros.com/
2. Register app
3. Get API credentials

#### Step 3: Test Connection
```dart
import 'package:safestride/services/gps_data_fetcher.dart';

final fetcher = GPSDataFetcher();

// Check connection status
final status = await fetcher.checkConnectionStatus();
print('Garmin: ${status[GPSPlatform.garmin]}');
print('Coros: ${status[GPSPlatform.coros]}');
print('Strava: ${status[GPSPlatform.strava]}');
```

#### Step 4: Fetch Real Activities
```dart
// Fetch last 30 days
final activities = await fetcher.fetchAllActivities(
  startDate: DateTime.now().subtract(Duration(days: 30)),
  endDate: DateTime.now(),
  limit: 50,
);

print('Fetched ${activities.length} activities');
```

#### Step 5: Generate Protocol with Real Data
- Profile screen → Tap "Generate Protocol"
- System fetches from connected GPS platforms
- Analyzes real biomechanics
- Generates personalized protocol



---

## 📁 FILES CREATED/MODIFIED

### New Files:
1. **`lib/services/gps_data_fetcher.dart`** (18,923 chars)
   - GPS data fetchers for Garmin/Coros/Strava
   - AISRI metrics calculator (converts VDOT, cadence, mileage → AISRI scores)
   - Unified GPSActivity model

2. **`database/migration_gps_watch_integration.sql`** (10,810 chars)
   - `gps_connections` table
   - `gps_activities` table
   - `custom_workouts` table
   - `workout_templates` table
   - Views for weekly/monthly summaries

3. **`docs/GPS_INTEGRATION_IMPLEMENTATION.md`** (15,138 chars)
   - Complete documentation
   - API references
   - Examples and troubleshooting

4. **`lib/models/workout_builder_models.dart`** (850+ lines)
   - WorkoutDefinition base class
   - 6 workout type classes
   - 5 enums for workout configuration

5. **`lib/examples/workout_builder_examples.dart`** (450+ lines)
   - 10 complete workout examples
   - Demonstrations of all features

6. **`lib/services/workout_builder_adapter.dart`** (350+ lines)
   - Integration with existing calendar system
   - Conversion between models

7. **`lib/screens/workout_builder_screen.dart`** (950+ lines)
   - Complete workout creation UI
   - Type-specific forms
   - Add set/exercise dialogs

### Modified Files:
1. **`lib/services/strava_protocol_service.dart`**
   - Added GPS data fetcher integration
   - Database storage for activities
   - Multi-source activity fetching

---

## 🚀 TESTING CHECKLIST

### ✅ Immediate Testing (No Setup Required)
- [ ] Hot reload Flutter app
- [ ] Open Profile screen
- [ ] Tap "Generate Protocol" button
- [ ] Verify success dialog appears
- [ ] Check calendar for 6 scheduled workouts

### 🔧 Setup Required Testing
- [ ] Run database migration in Supabase
- [ ] Set up Garmin/Coros OAuth (if using)
- [ ] Connect GPS platform
- [ ] Fetch real activities
- [ ] Generate protocol with real data

---

## 📊 AISRI SCORE INTERPRETATION

### Score Ranges:
- **0-40**: Very High Injury Risk - Immediate intervention needed
- **40-60**: High Injury Risk - Focus on injury prevention protocols
- **60-80**: Moderate Risk - Maintain preventive measures
- **80-100**: Low Risk - Continue current training approach

### AISRI Components:
- **Endurance Score** (0-100): Based on running fitness
- **Mobility Score** (0-100): Based on cadence (optimal: 170-180 spm)
- **Strength Score** (0-100): Based on weekly training volume
- **Balance Score** (0-100): Requires assessment
- **Flexibility Score** (0-100): Requires assessment
- **Power Score** (0-100): Requires assessment

---

## 🎓 KEY CONCEPTS

### GPS Platforms Supported:
1. **Garmin Connect** (60% of serious runners)
   - Most comprehensive metrics
   - Ground contact time, vertical oscillation
   - Running power, training effect

2. **Strava** (50% of runners)
   - Social features, segment tracking
   - Basic metrics: pace, cadence, HR

3. **Coros** (15% of runners)
   - Training load, recovery
   - Performance metrics

### Data Standardization:
All platforms → `GPSActivity` → AISRI format

### VDOT vs AISRI:
- **VDOT**: Running fitness estimate (20-85 scale)
- **SafeStride AISRI**: Comprehensive injury risk score (0-100 scale)
- **Relationship**: VDOT contributes to AISRI's Endurance component

---

## 🆘 COMMON ISSUES & SOLUTIONS

### Issue 1: "No activities found"
**Cause:** No GPS platforms connected  
**Solution:** Connect Garmin/Coros/Strava first

### Issue 2: "Database error"
**Cause:** Migration not applied  
**Solution:** Run `migration_gps_watch_integration.sql` in Supabase

### Issue 3: "Mock data still showing"
**Cause:** No real activities in database  
**Solution:** Fetch activities via `fetchAllActivities()`

### Issue 4: "Protocol generation fails"
**Cause:** Insufficient data  
**Solution:** Ensure at least 3-4 activities in last 30 days

---

## 📞 NEXT STEPS

### Immediate (Today):
1. **Test mock data** → Profile → Generate Protocol
2. **Run database migration** in Supabase

### This Week:
1. Set up OAuth for preferred platform (Garmin/Strava)
2. Connect real athlete account
3. Fetch activities and test

### Next Week:
1. Build connection management UI
2. Add manual workout creation to calendar
3. Test end-to-end flow

---

## 💡 TIPS

### For Testing:
- Use KURA's data (already in mock)
- Expected: 52 AISRI score, Low cadence, Moderate risk

### For Production:
- Set up all 3 platforms (Garmin/Coros/Strava)
- Most athletes use multiple platforms
- Fallback order: Garmin → Strava → Coros

### For Coaches:
- V.O2 dashboard → SafeStride integration
- Automatic protocol generation
- AISRI-based injury prevention

---

## 📚 DOCUMENTATION

**Full Details:**
- `docs/GPS_INTEGRATION_IMPLEMENTATION.md` - Complete implementation guide
- `database/migration_gps_watch_integration.sql` - Database schema
- `lib/services/gps_data_fetcher.dart` - GPS fetcher code
- `lib/models/workout_builder_models.dart` - Workout builder models
- `lib/screens/workout_builder_screen.dart` - Workout builder UI

**API Documentation:**
- Garmin: https://developer.garmin.com/
- Coros: https://open.coros.com/
- Strava: https://developers.strava.com/

---

## ✅ COMPLETION STATUS

**Implementation Progress:** 5/6 tasks complete (83%)

- ✅ GPS data fetchers (Garmin, Coros, Strava)
- ✅ V.O2 data adapter
- ✅ Database schema (4 tables + 2 views)
- ✅ Updated protocol service
- ✅ Workout builder system (models, examples, adapter, UI)
- ⏳ OAuth implementation & end-to-end testing (pending)

---

**Ready to use!** Start with Option 1 (mock data testing) or jump to Option 2 (real GPS integration).

**Questions?** Check `GPS_INTEGRATION_IMPLEMENTATION.md` for detailed examples and troubleshooting.
