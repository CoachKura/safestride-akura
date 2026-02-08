# 🚀 Strava Integration - Quick Reference Card

**Last Updated:** February 4, 2026  
**Status:** ✅ Schema Ready, Code Ready

---

## ✅ What You Get with Strava Integration

### **Automatic Data Collection:**
- ✅ **Activity History** (last 12 weeks)
- ✅ **Training Metrics** (distance, pace, HR, cadence)
- ✅ **Weekly Statistics** (pre-aggregated)
- ✅ **Personal Bests** (5K, 10K, HM, Marathon)
- ✅ **Training Load** (calculated)

### **Enhanced AISRI Scoring:**
- ✅ **Adaptability** - Training variety analysis
- ✅ **Injury Risk** - Load spike detection
- ✅ **Fatigue** - Recent vs historical load
- ✅ **Recovery** - Rest pattern analysis
- ✅ **Intensity** - Performance capacity
- ✅ **Consistency** - Training regularity

### **UI Features:**
- ✅ **Dashboard Stats Card** - Current week + 4-week average
- ✅ **Activity History Screen** - All recent runs
- ✅ **Auto-fill Evaluation Form** - Pre-populate training data
- ✅ **Strava Connect Screen** - OAuth flow

---

## 📊 Database Schema Summary

### **5 Tables:**

#### **1. strava_connections**
```sql
id, user_id, strava_athlete_id, access_token, 
refresh_token, expires_at, last_synced_at
```
**Purpose:** OAuth tokens for API access

#### **2. strava_athletes**
```sql
id, user_id, strava_athlete_id, firstname, lastname, 
sex, weight, profile_picture, city, country
```
**Purpose:** Athlete profile data

#### **3. strava_activities**
```sql
id, user_id, strava_activity_id, name, sport_type, 
start_date, distance, moving_time, average_speed, 
average_heartrate, average_cadence, suffer_score
```
**Purpose:** Detailed activity data (12 weeks retention)

#### **4. strava_personal_bests**
```sql
id, user_id, distance_meters, time_seconds, 
pace_per_km, activity_id, achieved_at
```
**Purpose:** Track PRs (5K, 10K, HM, Marathon)

#### **5. strava_weekly_stats**
```sql
id, user_id, week_start_date, total_distance, 
total_time, activity_count, average_pace, 
longest_run, training_load
```
**Purpose:** Pre-aggregated weekly summaries

---

## 🔄 Data Sync Process

### **Step-by-Step:**

1. **User Connects Strava** → OAuth Flow
2. **Exchange Code for Token** → Store in `strava_connections`
3. **Fetch Athlete Profile** → Store in `strava_athletes`
4. **Fetch Recent Activities** → Store in `strava_activities`
5. **Calculate Personal Bests** → Store in `strava_personal_bests`
6. **Calculate Weekly Stats** → Store in `strava_weekly_stats`
7. **Update Last Sync Time** → Ready to use

### **Sync Frequency:**
- **Manual:** User clicks "Sync" button
- **Auto:** Background sync every 24 hours (optional)

---

## 🎨 UI Components

### **1. Dashboard Card**
```dart
StravaDashboardCard()
  → This Week: 45 km, 5 runs
  → 4-Week Avg: 42 km/week, 4.5 runs/week
  → 5K PR: 21:34 (4:18/km)
  → 10K PR: 45:22 (4:32/km)
  → [Sync Button]
```

### **2. Activity History Screen**
```dart
StravaActivityHistoryScreen()
  → List of recent activities
  → Distance, Duration, Pace, HR
  → Tap for details
```

### **3. Strava Connect Screen**
```dart
StravaConnectScreen()
  → Strava logo
  → Benefits list
  → "Connect with Strava" button
  → OAuth flow
```

### **4. Auto-fill Evaluation Form**
```dart
_loadStravaDataIfAvailable()
  → Pre-fill: Name, Gender, Weight
  → Pre-fill: Weekly Mileage, Training Frequency
  → Pre-fill: Average Pace, Experience Years
  → Show: "✓ Training data loaded from Strava"
```

---

## 🧮 AISRI Enhancement Formula

### **Pillar Scoring:**

#### **Without Strava:**
```
Score = Physical Tests Only (0-100)
```

#### **With Strava:**
```
Adaptability  = Physical 60% + Training Variety 40%
Injury Risk   = Physical 70% + Load Spikes 30%
Fatigue       = Physical 40% + Recent Load 60%
Recovery      = Physical 50% + Rest Patterns 50%
Intensity     = Physical 30% + Performance 70%
Consistency   = Physical 20% + Regularity 80%
```

### **Training Metrics Used:**

- **Adaptability:** Distance/pace variation (CoV)
- **Injury Risk:** Week-over-week load increases >10%
- **Fatigue:** Last week load / 3-week average
- **Recovery:** Days between hard efforts (suffer score >100)
- **Intensity:** Recent PBs + fast sessions + HR monitoring
- **Consistency:** Average gap between runs + max gap

---

## 🔧 Implementation Checklist

### **Backend (Supabase):**
- [ ] Run migration: `STRAVA_SETUP_GUIDE.md` (SQL section)
- [ ] Verify tables: Check Supabase Table Editor
- [ ] Test RLS: Ensure users can only see own data
- [ ] Create Strava OAuth App: Get Client ID + Secret
- [ ] Configure Supabase Auth: Add Strava provider

### **Flutter Code:**
- [x] `lib/services/strava_service.dart` - API client
- [x] `lib/screens/strava_connect_screen.dart` - OAuth UI
- [ ] Update `lib/screens/dashboard_screen.dart` - Add card
- [ ] Update `lib/screens/evaluation_form_screen.dart` - Auto-fill
- [ ] Update `lib/services/aisri_calculator.dart` - Strava scoring

### **Testing:**
- [ ] Test OAuth flow end-to-end
- [ ] Verify data sync (activities, stats, PBs)
- [ ] Check dashboard displays correct data
- [ ] Test auto-fill in evaluation form
- [ ] Compare AISRI scores (with/without Strava)

---

## 📖 Key Documents

| Document | Purpose | Size |
|----------|---------|------|
| **STRAVA_SETUP_GUIDE.md** | Complete setup instructions | 14 KB |
| **STRAVA_IMPLEMENTATION.md** | Technical implementation details | 12.7 KB |
| **STRAVA_DATA_FLOW.md** | End-to-end data flow & architecture | 11 KB |
| **STRAVA_DELIVERY_SUMMARY.md** | Project delivery summary | 10 KB |
| **STRAVA_QUICK_REFERENCE.md** | This file - Quick reference | 8 KB |

---

## 🎯 Quick Commands

### **Database:**
```sql
-- Verify tables created
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name LIKE 'strava%';

-- Check activity count
SELECT user_id, COUNT(*) FROM strava_activities GROUP BY user_id;

-- View personal bests
SELECT * FROM strava_personal_bests WHERE user_id = 'your-user-id';
```

### **Flutter:**
```bash
# Add dependencies (if not already added)
flutter pub add http

# Run app
flutter run

# Check for errors
flutter analyze
```

### **Strava API:**
```bash
# Test token
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://www.strava.com/api/v3/athlete

# Get activities
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "https://www.strava.com/api/v3/athlete/activities?per_page=50"
```

---

## 🔐 Security Notes

### **Token Storage:**
- ✅ Tokens stored in database (encrypted in production)
- ✅ RLS policies prevent cross-user access
- ✅ Refresh tokens automatically before expiry
- ❌ Never log tokens or expose in UI

### **API Rate Limits:**
- **Strava:** 100 requests per 15 minutes, 1000 per day
- **Strategy:** Batch requests, cache data, sync incrementally
- **Handling:** Exponential backoff on 429 errors

### **User Privacy:**
- ✅ Users control connection (can disconnect anytime)
- ✅ Only fetch authorized scopes
- ✅ Data cleared on disconnect
- ✅ Explain what data is collected

---

## ❓ Common Questions

### **Q: What if user disconnects Strava?**
**A:** Assessment form falls back to manual input. Stored data remains but sync stops.

### **Q: How far back do we sync?**
**A:** Last 12 weeks (84 days) by default. Configurable.

### **Q: What about non-running activities?**
**A:** Filter for `Run`, `TrailRun`, `VirtualRun` only. Ignore cycling, swimming, etc.

### **Q: Can we sync older data?**
**A:** Yes, adjust `after` parameter in sync service. Be mindful of API rate limits.

### **Q: What if Strava is down?**
**A:** App continues working with last synced data. Show "Last synced: X hours ago" message.

---

## 🚀 Next Steps

1. **Read Setup Guide** → `STRAVA_SETUP_GUIDE.md` (45 min)
2. **Run Migration** → Create database tables (5 min)
3. **Configure OAuth** → Strava App + Supabase (15 min)
4. **Update Dashboard** → Add Strava card (10 min)
5. **Test Flow** → Connect → Sync → View (30 min)

---

## 📞 Support

- **Full Documentation:** `/docs/STRAVA_*.md` files
- **Database Schema:** `STRAVA_SETUP_GUIDE.md` (SQL section)
- **Code Examples:** All `lib/services/strava_*.dart` and `lib/screens/strava_*.dart` files
- **Troubleshooting:** `STRAVA_SETUP_GUIDE.md` (Troubleshooting section)

---

**Status:** ✅ **READY TO IMPLEMENT**  
**Estimated Setup Time:** 75 minutes  
**Estimated Testing Time:** 30 minutes

**Built with ❤️ for data-driven injury prevention**
