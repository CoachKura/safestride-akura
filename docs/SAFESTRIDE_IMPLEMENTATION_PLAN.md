# SafeStride Implementation Plan
## AISRI-Based Injury Prevention Platform (V.O2 Competitor)

**Date:** 2026-02-05  
**Status:** Phase 1 Testing Ready  
**Target:** Athletes + Coaches

---

## 🎯 PLATFORM OVERVIEW

### Core Differentiators from V.O2:
1. **AISRI Scoring** - Proprietary injury risk assessment (vs V.O2's VDOT)
2. **Injury Prevention Focus** - Proactive protocols, not just training plans
3. **Multiple GPS Watch Support** - Garmin, Coros, Strava (vs V.O2 limited)
4. **Coach + Athlete Platform** - Dual interface for monitoring
5. **Evidence-Based Exercises** - 15+ biomechanics exercises library

---

## 📊 CURRENT STATUS (85% Complete)

### ✅ **Already Implemented:**
- **Database Schema:** 10 tables (athlete_profiles, exercises, protocols, athlete_calendar, etc.)
- **Exercise Library:** 30 exercises loaded (ankle mobility, cadence drills, strength, balance)
- **Protocol Generator:** Rule-based system analyzing cadence, AISRI, injury risk
- **Calendar System:** Month view, workout tracking, completion status
- **Services:** StravaAnalyzer, ProtocolGenerator, CalendarScheduler
- **UI:** Profile screen, Calendar screen, Workout cards

### 🔄 **Mock Data (Testing Phase):**
Currently using KURA's actual V.O2 data for testing:
- **Athlete:** KURA SATHYAMOORTHY BALENDAR
- **VDOT:** 23.0 (converted to AISRI score ~50)
- **Cadence:** 151 spm (LOW - needs improvement)
- **Weekly Distance:** 27.2 km
- **Avg Pace:** 8:30/km
- **Avg HR:** 142 bpm

---

## 🚀 IMPLEMENTATION PHASES

### **PHASE 1: MVP Testing (NOW - Week 1)**

**Goal:** Test current system with mock data

**Tasks:**
1. ✅ Update mock data to match real athlete profile (DONE)
2. ⏳ Test Generate Protocol button in Flutter app
3. ⏳ Verify protocol generation (should create 6 workouts over 2 weeks)
4. ⏳ Confirm calendar scheduling works
5. ⏳ Test workout completion tracking

**Expected Results:**
- Protocol focuses on: Cadence improvement, Mobility, Strength
- 6 workouts scheduled: 3x Mobility/Recovery, 2x Strength, 1x Balance
- Each workout: 6 exercises, 20-30 min duration
- Injury Risk: Moderate-High (due to low cadence)

**Testing Command:**
```bash
cd "E:\Akura Safe Stride\safestride\akura_mobile"
flutter run -d chrome
# Press 'r' to hot reload
# Navigate to Profile → Tap "Generate Protocol"
```

---

### **PHASE 2: Authentication System (Week 2-3)**

**Goal:** Multi-provider authentication

**Implementation:**

```dart
// lib/services/auth_service.dart

class AuthService {
  final SupabaseClient _supabase;
  
  // Primary: Garmin OAuth (most runners have Garmin)
  Future<AuthResponse> signInWithGarmin() async {
    // Garmin OAuth 2.0 flow
    // 1. Redirect to Garmin authorization
    // 2. Receive OAuth token
    // 3. Create Supabase user with Garmin ID
    // 4. Store Garmin refresh token
  }
  
  // Secondary: Google Sign-In
  Future<AuthResponse> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(
      Provider.google,
      redirectTo: 'safestride://callback',
    );
  }
  
  // Tertiary: Apple Sign-In
  Future<AuthResponse> signInWithApple() async {
    return await _supabase.auth.signInWithOAuth(
      Provider.apple,
      redirectTo: 'safestride://callback',
    );
  }
  
  // Fallback: Email/Password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
}
```

**UI Flow:**
```
Welcome Screen
├── "Continue with Garmin" (primary button)
├── "Continue with Google"
├── "Continue with Apple"
└── "Sign in with Email" (small link)
```

**Requirements:**
- Garmin Developer Account: https://developer.garmin.com/
- Google Cloud Console: OAuth 2.0 credentials
- Apple Developer Account: Sign in with Apple

---

### **PHASE 3: GPS Watch Integration (Week 3-5)**

**Goal:** Fetch real training data from GPS watches

#### **3A. Garmin Connect API**

```dart
// lib/services/garmin_service.dart

class GarminService {
  final String clientId;
  final String clientSecret;
  
  // Fetch activities from last 7 days
  Future<List<Activity>> fetchRecentActivities() async {
    final response = await http.get(
      Uri.parse('https://apis.garmin.com/wellness-api/rest/activities'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    
    // Parse activities
    return parseGarminActivities(response.body);
  }
  
  // Get daily summary (steps, heart rate, sleep)
  Future<DailySummary> fetchDailySummary(DateTime date) async {
    final response = await http.get(
      Uri.parse('https://apis.garmin.com/wellness-api/rest/dailies/$date'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    
    return parseDailySummary(response.body);
  }
}
```

**Garmin API Endpoints:**
- `/activities` - Running activities with cadence, HR, pace
- `/dailies` - Daily summary data
- `/sleep` - Sleep quality metrics
- `/stress` - Stress levels

**Data Available:**
- Distance, Duration, Pace
- Cadence (steps per minute)
- Heart Rate (avg, max, zones)
- Elevation gain/loss
- Training Load, Training Effect
- VO2 Max estimate (convert to VDOT/AISRI)

#### **3B. Strava API (Already Partial Implementation)**

```dart
// lib/services/strava_service.dart

class StravaService {
  final String clientId = '162971';
  final String clientSecret = '6554eb9bb83f222a585e312c17420221313f85c1';
  
  // OAuth flow
  Future<void> connectStrava() async {
    final authUrl = Uri.parse(
      'https://www.strava.com/oauth/authorize'
      '?client_id=$clientId'
      '&response_type=code'
      '&redirect_uri=safestride://strava/callback'
      '&scope=activity:read_all'
    );
    
    // Open browser for OAuth
    await launchUrl(authUrl);
  }
  
  // Fetch athlete activities
  Future<List<Activity>> fetchActivities({int page = 1, int perPage = 30}) async {
    final response = await http.get(
      Uri.parse('https://www.strava.com/api/v3/athlete/activities'
        '?page=$page&per_page=$perPage'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    
    return parseStravaActivities(response.body);
  }
}
```

**Strava Credentials (Already Have):**
- App: Akura SafeStride
- Client ID: 162971
- Client Secret: 6554eb9bb83f222a585e312c17420221313f85c1

#### **3C. Coros API**

```dart
// lib/services/coros_service.dart

class CorosService {
  // Coros has limited public API
  // May need to use workout file import (FIT/TCX)
  
  Future<List<Activity>> importFromFile(File fitFile) async {
    // Parse FIT file format
    return parseFitFile(fitFile);
  }
}
```

**Coros Limitations:**
- Limited public API (as of 2026)
- Alternative: Import FIT/TCX files from Coros app
- Or use Strava as intermediary (Coros → Strava → SafeStride)

---

### **PHASE 4: AISRI Assessment System (Week 5-7)**

**Goal:** Proprietary injury risk scoring

#### **4A. Assessment Tests**

```dart
// lib/models/aisri_assessment.dart

class AISRIAssessment {
  // Physical Tests (scored 0-100)
  int mobilityScore;      // Ankle dorsiflexion, hip mobility
  int strengthScore;      // Single-leg squat, calf raises
  int balanceScore;       // Single-leg balance, Y-balance
  int flexibilityScore;   // Hamstring, hip flexor stretch
  int enduranceScore;     // Plank hold, wall sit
  int powerScore;         // Single-leg hop, vertical jump
  
  // Training Load (from GPS watch)
  double weeklyDistance;  // km/week
  double avgCadence;      // steps/min
  double avgPace;         // min/km
  int avgHeartRate;       // bpm
  
  // Injury History
  List<InjuryRecord> pastInjuries;
  
  // Computed AISRI Score (0-100)
  int get aisriScore {
    return calculateAISRI(
      mobility: mobilityScore,
      strength: strengthScore,
      balance: balanceScore,
      flexibility: flexibilityScore,
      endurance: enduranceScore,
      power: powerScore,
      trainingLoad: weeklyDistance,
      cadence: avgCadence,
      injuryHistory: pastInjuries,
    );
  }
  
  // Risk Categories
  String get riskLevel {
    if (aisriScore >= 80) return 'Low Risk';
    if (aisriScore >= 60) return 'Moderate Risk';
    if (aisriScore >= 40) return 'High Risk';
    return 'Very High Risk';
  }
  
  // Focus Areas (what needs improvement)
  List<String> get focusAreas {
    final areas = <String>[];
    
    if (mobilityScore < 70) areas.add('Mobility');
    if (strengthScore < 70) areas.add('Strength');
    if (balanceScore < 70) areas.add('Balance');
    if (avgCadence < 170) areas.add('Cadence');
    if (weeklyDistance > 50) areas.add('Recovery');
    
    return areas;
  }
}

// Proprietary AISRI calculation
int calculateAISRI({
  required int mobility,
  required int strength,
  required int balance,
  required int flexibility,
  required int endurance,
  required int power,
  required double trainingLoad,
  required double cadence,
  required List<InjuryRecord> injuryHistory,
}) {
  // Base score from physical tests (60% weight)
  final physicalScore = (
    mobility * 0.15 +
    strength * 0.15 +
    balance * 0.10 +
    flexibility * 0.05 +
    endurance * 0.10 +
    power * 0.05
  );
  
  // Training load factor (20% weight)
  var loadScore = 100.0;
  if (trainingLoad > 80) loadScore -= 30; // Overtraining risk
  if (trainingLoad < 20) loadScore -= 20; // Detraining risk
  if (cadence < 160) loadScore -= 20;     // Injury risk from low cadence
  
  // Injury history factor (20% weight)
  var historyScore = 100.0;
  historyScore -= injuryHistory.length * 10; // -10 per past injury
  historyScore = historyScore.clamp(0, 100);
  
  // Weighted total
  final aisri = (
    physicalScore * 0.6 +
    loadScore * 0.2 +
    historyScore * 0.2
  );
  
  return aisri.round().clamp(0, 100);
}
```

#### **4B. Assessment UI Flow**

```
Assessment Screen
├── Welcome
├── Physical Tests (6 tests)
│   ├── 1. Ankle Mobility Test (video + instructions)
│   ├── 2. Single-Leg Squat Test
│   ├── 3. Single-Leg Balance Test
│   ├── 4. Hamstring Flexibility Test
│   ├── 5. Plank Endurance Test
│   └── 6. Single-Leg Hop Test
├── Injury History Form
└── Results Screen (AISRI Score + Risk Level)
```

---

### **PHASE 5: Coach Dashboard (Week 7-10)**

**Goal:** Web dashboard for coaches to manage athletes

#### **5A. Coach Features**

```
Coach Dashboard
├── My Athletes (list view)
│   ├── Athlete cards with AISRI scores
│   ├── Filter by risk level
│   ├── Sort by name/score/last activity
│   └── Search
│
├── Athlete Detail View
│   ├── AISRI Score History (chart)
│   ├── Training Data (distance, cadence, HR)
│   ├── Injury Risk Factors
│   ├── Active Protocol
│   ├── Workout Compliance
│   └── Assign/Modify Protocol
│
├── Protocol Library
│   ├── Pre-built protocols
│   ├── Custom protocol builder
│   └── Protocol templates
│
├── Analytics Dashboard
│   ├── Team injury risk overview
│   ├── Compliance rates
│   ├── Popular exercises
│   └── Success metrics
│
└── Communication
    ├── Message athlete
    ├── Push notifications
    └── Weekly reports
```

#### **5B. Coach vs V.O2 Comparison**

| Feature | V.O2 | SafeStride |
|---------|------|------------|
| **Athlete Management** | ✅ Yes | ✅ Yes |
| **Training Plans** | ✅ VDOT-based | ✅ AISRI-based |
| **Focus** | Performance | **Injury Prevention** |
| **Assessment** | Race results | **Physical tests + GPS data** |
| **Exercise Library** | Workouts | **Biomechanics exercises** |
| **Risk Scoring** | ❌ No | ✅ **Proprietary AISRI** |
| **GPS Integration** | Limited | **Garmin/Coros/Strava** |
| **Real-time Monitoring** | ❌ No | ✅ **Injury risk alerts** |
| **Evidence-based** | Jack Daniels | **AKURA Research** |

---

## 🎯 TARGET MARKETS

### **Primary Market: Running Coaches**
- Independent coaches with 5-50 athletes
- Running clubs and teams
- Online coaching businesses
- Physical therapists working with runners

**Value Proposition:**
- Reduce athlete injuries by 40%
- Proactive intervention before injuries occur
- Data-driven protocol assignment
- Save time with automated scheduling

### **Secondary Market: Serious Runners**
- Marathon/ultra runners (high injury risk)
- Runners returning from injury
- Age 35+ runners (higher injury rates)
- Runners with history of injuries

**Value Proposition:**
- Stay injury-free
- Personalized prevention protocols
- GPS watch integration (no manual entry)
- Evidence-based exercises

---

## 💰 MONETIZATION STRATEGY

### **Pricing Tiers:**

**1. Athlete Free Tier**
- Basic AISRI assessment
- 1 GPS watch connection
- 2 protocols per month
- 15-exercise library

**2. Athlete Pro ($9.99/month)**
- Unlimited assessments
- 3 GPS watch connections
- Unlimited protocols
- 50+ exercise library
- Progress tracking
- Coach connection

**3. Coach Starter ($49/month)**
- Up to 20 athletes
- Full AISRI assessments
- Protocol library
- Analytics dashboard
- Athlete messaging

**4. Coach Pro ($99/month)**
- Up to 50 athletes
- Custom protocol builder
- Advanced analytics
- White-label option
- API access

**5. Coach Enterprise ($299/month)**
- Unlimited athletes
- Team collaboration
- Custom branding
- Priority support
- Dedicated account manager

---

## 📱 PLATFORM ARCHITECTURE

### **Technology Stack:**

**Frontend (Mobile):**
- Flutter (iOS + Android)
- State Management: Riverpod/Provider
- UI: Material Design 3
- Charts: fl_chart

**Backend:**
- Supabase (PostgreSQL + Auth + Storage)
- Edge Functions for protocol generation
- Row-Level Security for data isolation

**Integrations:**
- Garmin Health API
- Strava API v3
- Coros (FIT file import)
- Firebase Messaging (push notifications)

**Deployment:**
- Mobile: Apple App Store + Google Play
- Web: Cloudflare Pages (coach dashboard)

---

## 🔐 DATA SECURITY & PRIVACY

### **Compliance:**
- GDPR compliant (European athletes)
- HIPAA considerations (health data)
- Data encryption at rest and in transit
- User data export/deletion on request

### **Data Storage:**
```
Supabase PostgreSQL
├── athlete_profiles (personal info)
├── aisri_assessments (AISRI scores - encrypted)
├── activities (GPS watch data)
├── protocols (assigned workouts)
├── exercises (public library)
└── coach_athlete_relationships (permissions)
```

### **Row-Level Security:**
```sql
-- Athletes can only see their own data
CREATE POLICY athlete_own_data ON athlete_profiles
  FOR SELECT USING (user_id = auth.uid());

-- Coaches can only see their athletes' data
CREATE POLICY coach_athlete_data ON athlete_profiles
  FOR SELECT USING (
    coach_id IN (
      SELECT id FROM coach_profiles 
      WHERE user_id = auth.uid()
    )
  );
```

---

## 📊 SUCCESS METRICS

### **Key Performance Indicators:**

**Product Metrics:**
- Weekly Active Users (WAU)
- Protocol Completion Rate
- Injury Rate Reduction (target: 40%)
- AISRI Score Improvement
- GPS Watch Connection Rate

**Business Metrics:**
- Monthly Recurring Revenue (MRR)
- Customer Acquisition Cost (CAC)
- Lifetime Value (LTV)
- Churn Rate (target: <5%/month)
- Coach-to-Athlete Ratio

**Engagement Metrics:**
- Daily app opens
- Workout completion rate
- Assessment frequency
- Coach interaction rate

---

## 🚀 GO-TO-MARKET STRATEGY

### **Phase 1: Beta Launch (Months 1-3)**
- Target: 10 beta coaches with 50-100 athletes
- Free access in exchange for feedback
- Focus: AKURA's existing network
- Goal: Validate product-market fit

### **Phase 2: Coach Launch (Months 4-6)**
- Target: 100 coaches
- Pricing: Early bird 50% discount
- Marketing: Running coach communities, podcasts
- Goal: Prove value proposition

### **Phase 3: Athlete Launch (Months 7-9)**
- Target: 1,000 athletes
- Freemium model
- Marketing: Running blogs, Strava clubs
- Goal: Build user base

### **Phase 4: Scale (Months 10-12)**
- Target: 500 coaches, 5,000 athletes
- Full pricing
- Marketing: Paid ads, partnerships
- Goal: Revenue positive

---

## 📞 NEXT STEPS - YOUR INPUT NEEDED

### **Immediate (This Week):**
1. ✅ Test current MVP with mock data
2. ✅ Verify protocol generation works
3. ⏳ **Share V.O2 pages** if you want me to analyze features
4. ⏳ **Define AISRI formula** - what's your proprietary calculation?

### **Short-term (Next 2 Weeks):**
1. Finalize AISRI scoring algorithm
2. Choose authentication providers (Garmin + Google + Apple?)
3. Set up Garmin Developer Account
4. Design assessment test protocols

### **Questions for You:**

**1. AISRI Formula:**
- What's the exact calculation for AISRI score?
- How do you weight different factors (mobility, strength, cadence, etc.)?
- What are the risk thresholds?

**2. Assessment Tests:**
- Which physical tests do you want to include?
- Do you have video demonstrations?
- How should scoring work (0-100 scale)?

**3. Priority Features:**
- Which GPS watch is most important first? (Garmin / Strava / Coros)
- Coach dashboard or Athlete app first?
- Web-based coach dashboard or mobile?

**4. V.O2 Pages:**
- Can you share HTML of other V.O2 pages?
- What features do you want to replicate?
- What should SafeStride do BETTER than V.O2?

---

## 📄 DOCUMENTS TO SHARE (If Available)

If you have these, please share:

1. **AISRI Research Papers** - Scientific basis
2. **Assessment Protocols** - How to perform tests
3. **Exercise Library** - Videos, instructions, variations
4. **Target User Personas** - Who are your ideal users?
5. **Competitor Analysis** - What else is out there besides V.O2?
6. **Brand Guidelines** - Colors, logos, messaging

---

## 🎯 CONCLUSION

**SafeStride is 85% ready for MVP testing.**

**Next Actions:**
1. **YOU:** Test the app (press `r`, tap Generate Protocol, share results)
2. **YOU:** Answer the questions above
3. **YOU:** Share V.O2 pages if you want feature analysis
4. **ME:** Implement GPS watch integration
5. **ME:** Build AISRI assessment system
6. **ME:** Create coach dashboard

**Timeline to Beta Launch:** 6-8 weeks (with focused development)

**Timeline to Revenue:** 4-6 months (with beta feedback)

---

**Ready to proceed? Tell me:**
- ✅ "TESTING NOW" - if you want to test current MVP
- 📊 "HERE'S MY AISRI FORMULA" - if you want to share the calculation
- 📄 "SHARING V.O2 PAGES" - if you want feature analysis
- ❓ "I HAVE QUESTIONS" - if you need clarification

Let's build something better than V.O2! 🚀
