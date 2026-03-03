# SafeStride Platform - Complete Navigation & User Flow

## 🎯 Platform Overview

SafeStride is a comprehensive athlete management system with **professional UI**, **6-pillar AISRI scoring**, and **monthly re-evaluation tracking**. This document explains how all pages connect and the complete user journey.

---

## 🗺️ Complete Navigation Map

```
┌─────────────────────────────────────────────────────────────────────┐
│                         HOME PAGE                                    │
│                    /public/home.html                                 │
│                                                                       │
│  • Welcome & Platform Overview                                       │
│  • Feature Highlights (6 Pillars, Training Calendar, etc.)          │
│  • CTA: "Get Started" → Signup/Login                                │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      SIGNUP / LOGIN                                  │
│                /public/signup.html | /login.html                     │
│                                                                       │
│  • Create Account (Name, Email, Password, Role)                     │
│  • Login with Credentials                                            │
│  • Role Selection: Athlete or Coach                                 │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    ATHLETE ONBOARDING                                │
│                  /public/onboarding.html                             │
│                                                                       │
│  Step 1: Profile Setup (Age, Weight, Height, HR)                    │
│  Step 2: Initial Assessment (Quick Pillar Tests)                    │
│  Step 3: Device Connection (Strava/Garmin)                          │
│  Step 4: Confirmation & Welcome                                      │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│               ATHLETE DASHBOARD (Main Hub)                           │
│              /public/athlete-dashboard.html                          │
│                                                                       │
│  • Today's Workout Card (Distance, Duration, HR Zone)               │
│  • Weekly Progress Summary (Chart)                                   │
│  • AISRI Score Display (Circular Progress)                          │
│  • 6-Pillar Breakdown (Running, Strength, ROM, etc.)                │
│  • Training Zones (Unlocked/Locked)                                 │
│  • 7-Day Calendar Preview                                            │
│  • AI Insights & Recommendations                                     │
│  • Strava Connection Status Banner                                   │
│  • Monthly Evaluation Reminder (if due)                             │
│                                                                       │
│  Navigation Buttons:                                                 │
│  → Training Calendar (view full 12-week plan)                       │
│  → Evaluation Form (start assessment)                               │
│  → Strava Dashboard (activity sync)                                 │
│  → Training Plan Builder (create new plan)                          │
└─────────────────────────────────────────────────────────────────────┘
            ↓                  ↓                    ↓
            
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────┐
│  TRAINING        │  │  EVALUATION       │  │  TRAINING PLAN       │
│  CALENDAR        │  │  FORM             │  │  BUILDER             │
│  /public/        │  │  /public/         │  │  /public/            │
│  training-       │  │  athlete-         │  │  training-plan-      │
│  calendar.html   │  │  evaluation.html  │  │  builder.html        │
│                  │  │                   │  │                      │
│  • 12-Week View  │  │  • 6-Pillar Tests │  │  • Connect Devices   │
│  • Week Selector │  │  • Image Capture  │  │  • AI Analysis       │
│  • Daily         │  │  • ROM Tests      │  │  • Generate Plan     │
│    Workouts      │  │  • Strength       │  │  • Export PDF        │
│  • Completion    │  │  • Balance        │  │  • Save to DB        │
│    Tracking      │  │  • Mobility       │  │                      │
│  • Click Day →   │  │  • Alignment      │  │  → Saves to          │
│    Workout Modal │  │  • Running (Auto) │  │    training_plans    │
│  • Mark Complete │  │  • Submit →       │  │                      │
│  • RPE Feedback  │  │    Calculates     │  │  → Creates           │
│  • Export        │  │    AISRI Score    │  │    daily_workouts    │
│                  │  │  • Schedule Next  │  │                      │
│  Shows:          │  │    Evaluation     │  │  Returns to:         │
│  • Evaluation    │  │                   │  │  → Dashboard         │
│    Due Markers   │  │  Returns to:      │  │                      │
│                  │  │  → Dashboard      │  │                      │
└──────────────────┘  └──────────────────┘  └──────────────────────┘
```

---

## 📱 Detailed Page Flow & Features

### 1. **Home Page** (`/public/home.html`)
**Purpose**: Landing page introducing SafeStride

**Features**:
- Hero section with platform overview
- Feature cards (6 Pillars, Training Calendar, Coach Dashboard)
- Social proof / testimonials
- Clear CTA buttons

**Navigation**:
- "Get Started" → `/public/signup.html`
- "Sign In" → `/login.html`

---

### 2. **Signup/Login** (`/public/signup.html`, `/login.html`)
**Purpose**: User authentication and account creation

**Features**:
- Email/password signup
- Role selection (Athlete/Coach)
- Profile details (name, age, etc.)
- Supabase Auth integration

**Navigation**:
- After signup → `/public/onboarding.html` (first-time athletes)
- After login → Role-based redirect:
  - **Athletes** → `/public/athlete-dashboard.html`
  - **Coaches** → `/public/coach-dashboard.html`

---

### 3. **Athlete Onboarding** (`/public/onboarding.html`)
**Purpose**: First-time setup for new athletes

**4-Step Wizard**:
1. **Profile Setup**: Age, weight, height, max HR
2. **Initial Assessment**: Quick pillar tests with image capture
3. **Device Connection**: Connect Strava/Garmin
4. **Confirmation**: Review and complete

**Navigation**:
- Completes → Sets `onboarding_completed = true`
- Redirects → `/public/athlete-dashboard.html`

---

### 4. **Athlete Dashboard** (`/public/athlete-dashboard.html`) ⭐ **MAIN HUB**
**Purpose**: Central hub for athletes - daily workout, progress tracking, AISRI score

**Key Sections**:

#### **A. Today's Workout Card**
- **Beautiful gradient card** showing:
  - Workout name (e.g., "Easy Recovery Run")
  - Distance (km)
  - Duration (minutes)
  - HR Zone (Zone 2-5)
  - Intensity (Easy/Moderate/Hard)
  - Workout notes and coaching tips
- **Actions**:
  - "Mark Complete" button → Opens completion form
  - "Skip" button → Skip workout with confirmation

#### **B. Weekly Progress Summary**
- **Stats Cards**:
  - Total activities this week
  - Total distance (km)
  - Total time (minutes)
  - Average pace
- **Chart.js bar chart**: Daily distance for the week

#### **C. AISRI Score Display**
- **Circular progress indicator**: SVG circle showing score (0-100)
- **Risk badge**: Low/Medium/High/Critical with color coding
- **Last assessed date**: Shows days since last evaluation
- **Re-evaluate button** → `/public/athlete-evaluation.html`

#### **D. 6-Pillar Breakdown**
- **Individual pillar scores** with progress bars:
  1. Running (40% weight) - Blue
  2. Strength (15% weight) - Green
  3. ROM (12% weight) - Orange
  4. Balance (13% weight) - Cyan
  5. Alignment (10% weight) - Purple
  6. Mobility (10% weight) - Pink
- Color-coded bars showing score out of 100

#### **E. Training Zones**
- **6 zones displayed**:
  - AR (Active Recovery) - Always unlocked
  - F (Foundation) - Unlocked at AISRI 0+
  - EN (Endurance) - Unlocked at AISRI 40+
  - TH (Threshold) - Unlocked at AISRI 55+
  - P (Power) - Unlocked at AISRI 70+
  - SP (Speed) - Unlocked at AISRI 85+
- **Visual indicators**: Lock icon for locked zones, check icon for unlocked

#### **F. 7-Day Calendar Preview**
- **Mini calendar grid** showing:
  - Completed workouts (green background)
  - Scheduled workouts (blue background)
  - Today (blue with border)
  - Rest days (gray background)
- **Click** → Opens full calendar

#### **G. AI Insights**
- **Smart recommendations**:
  - Training load alerts
  - Recovery status
  - Injury risk warnings
  - Progression suggestions

#### **H. Banners** (conditional display):
- **Strava Connect Banner** (if not connected):
  - Orange gradient banner
  - "Connect Strava" button → `/public/strava-callback.html`
- **Evaluation Reminder Banner** (if evaluation due):
  - Yellow gradient banner
  - "Start Evaluation" button → `/public/athlete-evaluation.html`
  - Shows days overdue if past due date

**Navigation**:
- **Top Nav Bar**:
  - Dashboard (current page) ✓
  - Training Calendar → `/public/training-calendar.html`
  - Evaluation Form → `/public/athlete-evaluation.html`
  - Strava Dashboard → `/public/strava-dashboard.html`
- **Quick Actions**:
  - "New Plan" button → `/public/training-plan-builder.html`
  - "Logout" button → Sign out and redirect to login

---

### 5. **Training Calendar** (`/public/training-calendar.html`)
**Purpose**: 12-week training plan visualization and workout tracking

**Features**:

#### **A. Week Selector**
- **Horizontal scrollable tabs**: Week 1-12
- **Active week highlighted**: White background, colored text
- **Click week tab** → Loads that week's workouts

#### **B. Calendar Grid**
- **7-day grid layout**: Monday-Sunday
- **Each day card shows**:
  - Day number
  - Workout type badge (AR, F, EN, TH, P, SP, Rest)
  - Workout name
  - Distance (km)
  - Duration (min)
  - Completion checkmark (if completed)

#### **C. Day Status**:
- **Today**: Blue background with border
- **Completed**: Green background
- **Scheduled**: White background, blue text
- **Rest Day**: Gray background
- **Evaluation Due**: Yellow marker at bottom

#### **D. Stats Header**:
- Total workouts in plan
- Completed workouts
- Total planned distance
- Completion rate percentage

#### **E. Workout Detail Modal**:
Clicking any day opens modal showing:
- Full workout details
- Planned metrics (distance, duration, HR zone, intensity)
- Coaching tips specific to workout type
- **Completion Form**:
  - Actual distance input
  - Actual duration input
  - Average heart rate input
  - RPE slider (1-10 effort scale)
  - Notes textarea
- **Actions**:
  - "Mark Complete" → Saves to `workout_completions` table
  - "Skip" → Confirms and closes

**Navigation**:
- "Export" button → Download PDF/CSV (future feature)
- "Sync Strava" → Pull activities from Strava
- Back to Dashboard → Top nav bar

---

### 6. **Athlete Evaluation Form** (`/public/athlete-evaluation.html`)
**Purpose**: Comprehensive 6-pillar physical assessment with image/video capture

**7-Step Wizard**:

#### **Step 1: ROM (Range of Motion)** 🟠
Tests:
- **Ankle Dorsiflexion**: Left & right (degrees)
  - Image capture available
- **Hip Flexion**: Left & right (degrees)
  - Image capture available
- **Hip Extension**: Left & right (degrees)
  - Image capture available

#### **Step 2: Strength** 🟢
Tests:
- **Single Leg Squat**: Left & right (reps)
  - Image capture available
- **Calf Raises**: Left & right (reps to failure)
  - Image capture available
- **Core Plank**: Hold time (seconds)
  - Image capture available

#### **Step 3: Balance** 🔵
Tests:
- **Single Leg Stand**: Left & right (seconds, eyes closed)
  - Image capture available
- **Y-Balance Test**: Left & right reach distance (cm)
  - Image capture available

#### **Step 4: Mobility** 🔴
Tests:
- **Hip Flexor Mobility**: Left & right (score 1-10)
  - Image capture available
- **Hamstring Mobility**: Left & right (score 1-10)
  - Image capture available
- **Thoracic Rotation**: Overall score (1-10)
  - Image capture available

#### **Step 5: Alignment** 🟣
Tests:
- **Posture Assessment**: Overall score (0-100)
  - Image capture available (front/side/back views)
- **Gait Analysis**: Running gait score (0-100)
  - Image/video capture available

#### **Step 6: Running** 🔵
- **Auto-calculated from Strava**:
  - Running performance score
  - Recent metrics (30-day):
    - Total distance
    - Average pace
    - Consistency score
    - Training load
- **"Sync Strava Activities" button** → Pull latest data

#### **Step 7: Review & Submit** ✅
- **AISRI Score Display**:
  - Large circular progress indicator
  - Calculated score (0-100)
  - Risk category (Low/Medium/High/Critical)
- **All 6 pillar scores shown**:
  - Running, Strength, ROM, Balance, Alignment, Mobility
  - Color-coded cards with individual scores
- **Notes sections**:
  - Assessor notes (coach/admin observations)
  - Athlete feedback (how they're feeling)
- **Submit button** → Saves to database

**Image Capture Flow**:
1. Click "Capture Photo/Video" area
2. File picker opens (camera on mobile, file on desktop)
3. Select image/video
4. Preview shown in card
5. Options: Retake or Remove
6. Files stored in `capturedMedia` object
7. On submit → Upload to Supabase Storage
8. Create records in `assessment_media` table

**Database Operations on Submit**:
1. Create record in `physical_assessments` table
2. Upload all captured media to Supabase Storage
3. Create records in `assessment_media` table
4. Create record in `aisri_score_history` table
5. Schedule next evaluation in `evaluation_schedule` table (30 days)
6. Redirect → `/public/athlete-dashboard.html`

**Progress Indicator**:
- **7 circular steps** at top of page
- **Current step highlighted** (blue)
- **Completed steps** (green checkmark)
- **Pending steps** (gray)

**Navigation**:
- "Previous" button (hidden on step 1)
- "Next" button (hidden on step 7)
- "Submit Assessment" button (only on step 7)
- "Save Draft" button (top right) → Save to localStorage

---

### 7. **Training Plan Builder** (`/public/training-plan-builder.html`)
**Purpose**: Generate personalized 12-week training plans based on AISRI score

**Current Status**: ⚠️ **Needs Redesign** (you mentioned "collage project look")

**Planned Modern Flow**:

#### **Step 1: Connect Devices**
- Strava OAuth button
- Garmin connect option
- Manual data entry fallback

#### **Step 2: AI Analysis**
- Pull latest Strava activities
- Calculate current AISRI score
- Analyze training history
- Assess injury risk
- Display 6-pillar breakdown

#### **Step 3: Plan Configuration**
- **Goal Selection**:
  - Target distance (5K, 10K, Half Marathon, Marathon)
  - Target date / weeks available
  - Current fitness level
- **Preferences**:
  - Training days per week
  - Long run day (Saturday/Sunday)
  - Recovery preferences
- **Safety Gates**:
  - Automatic zone restrictions based on AISRI
  - Progressive overload limits

#### **Step 4: Generated Plan**
- **12-week calendar preview**
- **Weekly breakdown**:
  - Week number
  - Weekly distance
  - Key workouts
  - Training zones used
- **Workout cards** for each day:
  - Type, distance, duration
  - HR zone, intensity
  - Notes and tips

#### **Step 5: Review & Save**
- Edit individual workouts
- Adjust intensity/distance
- Add custom notes
- **Actions**:
  - "Save to Calendar" → Saves to `training_plans` table
  - "Export PDF" → Download plan
  - "Share with Coach" → Send to assigned coach

**Navigation After Save**:
- Redirect → `/public/training-calendar.html`
- Plan is now active and visible in calendar
- Today's workout appears on dashboard

---

## 🔄 Data Flow & Storage

### **Assessment → AISRI Score → Training Plan Flow**:

```
1. Athlete completes physical assessment
   ↓
2. Stores in physical_assessments table
   ↓
3. Uploads images/videos to Supabase Storage
   ↓
4. Creates assessment_media records
   ↓
5. Calculates AISRI score (weighted 6 pillars)
   ↓
6. Stores in aisri_score_history table
   ↓
7. Updates athlete profile with latest score
   ↓
8. Training zones unlock based on score
   ↓
9. Training plan builder uses score to:
   - Restrict high-intensity zones
   - Calculate safe progression
   - Apply safety gates
   ↓
10. Generated plan saved to training_plans table
    ↓
11. Individual workouts saved to daily_workouts table
    ↓
12. Workouts appear in calendar and dashboard
    ↓
13. Athlete marks workouts complete
    ↓
14. Stores in workout_completions table
    ↓
15. Weekly/monthly stats calculated
    ↓
16. Next evaluation scheduled automatically (30 days)
    ↓
17. Reminder shown on dashboard when due
```

---

## 📊 Database Tables Used

### **Core Tables**:
- `profiles` - User accounts (athletes, coaches)
- `physical_assessments` - Test results from evaluation form
- `assessment_media` - Images/videos captured during tests
- `aisri_score_history` - Historical AISRI scores over time
- `training_plans` - 12-week training programs
- `daily_workouts` - Individual daily workouts from plans
- `workout_completions` - Completed workouts with feedback
- `evaluation_schedule` - Monthly re-evaluation reminders
- `training_load` - ACR (Acute:Chronic Ratio) calculations
- `strava_connections` - Strava OAuth tokens
- `strava_activities` - Synced Strava activities

### **Views**:
- `v_latest_aisri_scores` - Latest score per athlete
- `v_upcoming_evaluations` - Scheduled evaluations
- `v_coach_athletes` - Coach's athlete summary

---

## 🎨 Design Standards

### **Color Palette**:
- Primary: `#667eea` (Blue-Purple)
- Secondary: `#764ba2` (Deep Purple)
- Success: `#10b981` (Green)
- Warning: `#f59e0b` (Orange)
- Danger: `#ef4444` (Red)
- Info: `#3b82f6` (Blue)

### **Component Library**:
- Cards with rounded corners (12-16px radius)
- Gradient backgrounds for featured content
- Progress bars and circular indicators
- Badge components for status/categories
- Modal overlays for detailed views
- Responsive grid layouts

### **Typography**:
- Font: Inter (system-ui fallback)
- Headers: Bold, large sizing
- Body: Regular, readable sizing
- Data: Monospace for numbers

---

## 🚀 Key Features Summary

### **What Makes This Modern**:
1. ✅ **Professional UI** - Clean, gradient-rich design
2. ✅ **Image Capture** - Native camera integration for assessments
3. ✅ **Real-time Data** - Live sync with Supabase
4. ✅ **Smart Navigation** - Clear user flows, intuitive pathways
5. ✅ **Progressive Disclosure** - Multi-step wizards, tabbed interfaces
6. ✅ **Data Visualization** - Charts, progress circles, trend graphs
7. ✅ **Responsive Design** - Mobile-first, works on all devices
8. ✅ **Automated Reminders** - Evaluation scheduling, notifications
9. ✅ **Safety Features** - Zone restrictions, progressive overload limits
10. ✅ **Comprehensive Tracking** - Complete fitness journey monitoring

---

## 🎯 User Journey Examples

### **New Athlete - First Week**:
```
Day 1: Sign up → Complete onboarding → Connect Strava
Day 2: Complete physical evaluation → Get AISRI score (65)
Day 3: View dashboard → See first workout → Mark complete
Day 4: Open training calendar → View 12-week plan
Day 5: Complete workout → Add RPE feedback
Day 6: Rest day → Review AISRI pillar breakdown
Day 7: Long run → Strava auto-sync → Dashboard updated
```

### **Returning Athlete - Monthly Flow**:
```
Week 1-3: Complete scheduled workouts → Track progress
Week 4: Monthly evaluation reminder appears on dashboard
→ Complete evaluation form → Take progress photos
→ New AISRI score calculated (75, improved!)
→ Training zones updated (Threshold now unlocked)
→ Training plan automatically adjusts
→ Next evaluation scheduled in 30 days
```

---

## 📝 Next Steps (Remaining Work)

### **High Priority**:
1. **Redesign Training Plan Builder** - Replace current "collage" look with modern wizard
2. **Build Coach Dashboard** - Athlete list, risk monitoring, plan management
3. **Enhanced Strava Integration** - Auto-calculate running pillar from activities

### **Medium Priority**:
4. **Monthly Re-evaluation Automation** - Email/push notifications
5. **Advanced Analytics** - Trend graphs, progress charts, insights
6. **Export Features** - PDF reports, CSV data exports

### **Low Priority**:
7. **Mobile App** - Native iOS/Android versions
8. **Admin Dashboard** - System management, user administration
9. **Messaging System** - Coach-athlete communication
10. **Gamification** - Badges, streaks, achievements

---

## 🔗 Quick Reference Links

- **Home**: `/public/home.html`
- **Signup**: `/public/signup.html`
- **Login**: `/login.html`
- **Onboarding**: `/public/onboarding.html`
- **Athlete Dashboard**: `/public/athlete-dashboard.html` ⭐
- **Training Calendar**: `/public/training-calendar.html`
- **Evaluation Form**: `/public/athlete-evaluation.html`
- **Training Plan Builder**: `/public/training-plan-builder.html`
- **Strava Dashboard**: `/public/strava-dashboard.html`
- **Coach Dashboard**: `/public/coach-dashboard.html` (TBD)

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-03  
**Author**: AI Assistant  
**Status**: ✅ Core Flow Complete | ⚠️ Coach Dashboard & Plan Builder Redesign Pending
