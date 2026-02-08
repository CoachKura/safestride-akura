# 🔄 Strava Data Flow & Storage Architecture

**Document Version:** 1.0.0  
**Date:** February 4, 2026  
**Status:** ✅ Complete Schema Ready

---

## 📊 Overview

This document explains how Strava data flows through SafeStride, from authentication to storage to display and AISRI integration.

---

## 🔐 Part 1: Authentication & Data Fetching

### **Flow Diagram:**
```
User → Strava Connect Screen → OAuth Dialog → Strava API → Access Token → Store in DB
```

### **Step-by-Step:**

1. **User Clicks "Connect Strava"** (Dashboard Button)
   - Opens `StravaConnectScreen`
   - Shows Strava logo and benefits

2. **OAuth Flow Begins**
   ```dart
   // User clicks "Connect with Strava"
   final authUrl = 'https://www.strava.com/oauth/authorize?'
       'client_id=$clientId'
       '&redirect_uri=$redirectUri'
       '&response_type=code'
       '&scope=activity:read_all,profile:read_all';
   
   // Opens browser/webview
   await launchUrl(authUrl);
   ```

3. **User Authorizes in Strava**
   - Strava shows permission screen
   - User clicks "Authorize"

4. **Callback with Code**
   ```dart
   // Receives: https://yourapp.com/callback?code=abc123
   final code = extractCodeFromUrl(callbackUrl);
   ```

5. **Exchange Code for Token**
   ```dart
   final response = await http.post(
     'https://www.strava.com/oauth/token',
     body: {
       'client_id': clientId,
       'client_secret': clientSecret,
       'code': code,
       'grant_type': 'authorization_code',
     },
   );
   
   final tokens = jsonDecode(response.body);
   // tokens['access_token']
   // tokens['refresh_token']
   // tokens['expires_at']
   // tokens['athlete'] (basic profile)
   ```

6. **Store Connection in Database**
   ```sql
   INSERT INTO strava_connections (
     user_id,
     access_token,
     refresh_token,
     expires_at,
     scope,
     athlete_id
   ) VALUES (
     auth.uid(),
     'encrypted_access_token',
     'encrypted_refresh_token',
     1738838400,
     'activity:read_all,profile:read_all',
     12345678
   );
   ```

---

## 💾 Part 2: Data Storage Schema

### **Database Tables:**

#### **1. strava_connections**
```sql
CREATE TABLE strava_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  strava_athlete_id BIGINT NOT NULL,
  access_token TEXT NOT NULL,
  refresh_token TEXT NOT NULL,
  expires_at BIGINT NOT NULL,
  scope TEXT,
  connected_at TIMESTAMPTZ DEFAULT now(),
  last_synced_at TIMESTAMPTZ,
  UNIQUE(user_id)  -- One Strava account per user
);
```

**Purpose:** Stores OAuth tokens for API access  
**Security:** Tokens should be encrypted in production  
**Usage:** Check if user is connected, refresh expired tokens

---

#### **2. strava_athletes**
```sql
CREATE TABLE strava_athletes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  strava_athlete_id BIGINT UNIQUE NOT NULL,
  firstname TEXT,
  lastname TEXT,
  profile_picture TEXT,
  city TEXT,
  state TEXT,
  country TEXT,
  sex TEXT,  -- M/F
  weight NUMERIC,  -- kg
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);
```

**Purpose:** Stores athlete profile data from Strava  
**Usage:** Display athlete info, pre-fill evaluation form  
**Updates:** Refreshed on each sync

---

#### **3. strava_activities**
```sql
CREATE TABLE strava_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  strava_activity_id BIGINT UNIQUE NOT NULL,
  name TEXT,
  sport_type TEXT,  -- Run, TrailRun, VirtualRun
  start_date TIMESTAMPTZ,
  distance NUMERIC,  -- meters
  moving_time INTEGER,  -- seconds
  elapsed_time INTEGER,  -- seconds
  total_elevation_gain NUMERIC,  -- meters
  average_speed NUMERIC,  -- m/s
  max_speed NUMERIC,  -- m/s
  average_heartrate NUMERIC,  -- bpm
  max_heartrate NUMERIC,  -- bpm
  average_cadence NUMERIC,  -- spm (steps per minute)
  calories NUMERIC,
  suffer_score NUMERIC,  -- Strava's relative effort
  perceived_exertion INTEGER,  -- 1-10 scale
  kudos_count INTEGER,
  synced_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for performance
CREATE INDEX idx_strava_activities_user_id ON strava_activities(user_id);
CREATE INDEX idx_strava_activities_start_date ON strava_activities(start_date);
CREATE INDEX idx_strava_activities_sport_type ON strava_activities(sport_type);
```

**Purpose:** Stores detailed activity data for analysis  
**Retention:** Keep last 12 months (configurable)  
**Usage:** Calculate weekly stats, training load, fatigue indicators

---

#### **4. strava_personal_bests**
```sql
CREATE TABLE strava_personal_bests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  distance_meters INTEGER NOT NULL,  -- 5000, 10000, 21097, 42195
  time_seconds INTEGER NOT NULL,
  pace_per_km INTEGER,  -- seconds per km
  activity_id BIGINT,  -- Strava activity ID
  achieved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, distance_meters)
);
```

**Purpose:** Track personal records for standard distances  
**Standard Distances:**
- 5K (5000m)
- 10K (10000m)
- Half Marathon (21097m)
- Marathon (42195m)

**Usage:** Display in profile, compare with goals

---

#### **5. strava_weekly_stats**
```sql
CREATE TABLE strava_weekly_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start_date DATE NOT NULL,
  week_number INTEGER,
  year INTEGER,
  total_distance NUMERIC,  -- meters
  total_time INTEGER,  -- seconds
  total_elevation_gain NUMERIC,  -- meters
  activity_count INTEGER,
  average_pace NUMERIC,  -- min/km
  longest_run NUMERIC,  -- meters
  training_load NUMERIC,  -- calculated metric
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, week_start_date)
);
```

**Purpose:** Pre-aggregated weekly training data  
**Calculation:** Runs weekly after sync  
**Usage:** Display weekly trends, identify overtraining

---

## 🎯 Summary

### **Data Flow:**
1. **Authenticate** → OAuth → Store tokens
2. **Sync** → Fetch activities → Store in DB
3. **Calculate** → Weekly stats, PBs → Pre-aggregate
4. **Display** → Dashboard, history, profile
5. **Analyze** → Enhance AISRI with training data

### **Storage:**
- **5 Tables** store all Strava data
- **RLS Policies** ensure user privacy
- **Indexes** optimize query performance
- **Retention** configurable (default: 12 months)

### **Viewing:**
- **Dashboard Card** shows current stats
- **Activity History** lists all runs
- **Profile** displays personal bests
- **AISRI Report** integrates training data

### **AISRI Enhancement:**
- **Physical Tests** provide baseline (100% if no Strava)
- **Training Data** refines scores (weighted combination)
- **Each Pillar** has specific Strava metrics
- **Overall Score** more accurate with real training data

---

## 📚 Next Steps

1. **Run Migration** → See `STRAVA_SETUP_GUIDE.md`
2. **Test Sync** → Connect Strava, sync data
3. **Verify Storage** → Check Supabase Table Editor
4. **View Data** → Dashboard, activity history
5. **Test AISRI** → Complete assessment, compare scores

---

**Document Status:** ✅ Complete  
**Last Updated:** February 4, 2026  
**Version:** 1.0.0
