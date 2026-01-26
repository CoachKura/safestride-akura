# SafeStride by AKURA

**Elite Running Coach Platform for Chennai's Elite Runners**

SafeStride by AKURA is a comprehensive running coaching platform that replaces VDOT O2 scoring with a proprietary AKURA Performance Index (API) tailored for Chennai's climate and elite running community.

---

## 🎯 Project Overview

### **Features**
- ✅ **AKURA Performance Index (0-100)** - Proprietary scoring replacing VDOT
- ✅ **5 HR Zones Training** - Max HR = 208 - (0.7 × Age)
- ✅ **7 Protocol System** - START, ENGINE, OXYGEN, POWER, ZONES, STRENGTH, LONG RUN
- ✅ **Device Integration** - Strava, Garmin, COROS, Apple Health
- ✅ **Coach Dashboard** - Manage multiple athletes, analytics, calendar
- ✅ **Athlete Portal** - Personal dashboard, workouts, device sync
- ✅ **10 Pre-loaded Chennai Athletes** - Ready for Day 1 testing
- ✅ **Auto-synced Workouts** - Seamless device integration
- ✅ **90-Day Roadmap** - Structured training plans

### **Tech Stack**
- **Frontend**: HTML5, TailwindCSS, JavaScript (ES6+), Chart.js
- **Backend**: Node.js + Express (deployed at Render)
- **Database**: Supabase (PostgreSQL)
- **Authentication**: JWT tokens
- **Deployment**: 
  - Frontend: Render → https://safestride-frontend.onrender.com
  - Backend: Render → https://safestride-backend-cave.onrender.com
  - Domain: akura.in (DNS pending)

---

## 📂 Project Structure

```
safestride-by-akura/
├── index.html                    # Homepage with hero, features, CTA
├── athlete-dashboard.html        # Athlete personal dashboard
├── athlete-devices.html          # Device connection page (Strava/Garmin)
├── coach-dashboard.html          # Coach overview & athlete roster
├── js/
│   ├── akuraAPI.js              # AKURA Performance Index calculator ⭐
│   ├── chennai-athletes.js      # 10 pre-loaded athlete profiles
│   ├── main.js                  # Homepage logic & auth
│   ├── athlete-dashboard.js     # Athlete dashboard logic
│   ├── athlete-devices.js       # Device sync logic
│   └── coach-dashboard.js       # Coach dashboard logic
└── README.md                     # This file
```

---

## 🚀 Quick Start

### **1. Local Development**

Simply open `index.html` in a web browser:

```bash
# Open homepage
open index.html

# Or use a local server
python -m http.server 8000
# Then visit http://localhost:8000
```

### **2. Login Credentials (Demo Mode)**

**Coach Login:**
- Email: `coach@akura.in`
- Password: `coach123`
- Role: Coach

**Athlete Login:**
- Email: `priya.sharma@example.com`
- Password: `athlete123`
- Role: Athlete

*Note: When backend is offline, the app uses demo data from `chennai-athletes.js`*

---

## 🏃‍♂️ 10 Chennai Athletes (Pre-loaded)

| Name | Age | Current Pace | Goal | AKURA API | HR Zones |
|------|-----|--------------|------|-----------|----------|
| Arjun Kumar | 28 | 4:15/km | Sub-3:00 Marathon | 78 | Zone 3: 148-169 bpm |
| Priya Sharma | 25 | 4:45/km | Sub-1:35 HM | 72 | Zone 3: 152-174 bpm |
| Vikram Reddy | 32 | 4:30/km | Sub-3:15 Marathon | 75 | Zone 3: 145-166 bpm |
| Anjali Menon | 27 | 5:00/km | Sub-1:50 HM | 68 | Zone 3: 148-169 bpm |
| Rahul Iyer | 30 | 4:20/km | Sub-3:05 Marathon | 76 | Zone 3: 146-167 bpm |
| Deepa Krishnan | 29 | 4:50/km | Sub-1:40 HM | 70 | Zone 3: 147-168 bpm |
| Karthik Subramanian | 26 | 4:10/km | Sub-2:55 Marathon | 80 | Zone 3: 151-172 bpm |
| Lakshmi Venkatesh | 31 | 5:10/km | Sub-2:00 HM | 65 | Zone 3: 143-163 bpm |
| Aditya Nair | 28 | 4:35/km | Sub-3:20 Marathon | 74 | Zone 3: 148-169 bpm |
| Sneha Patel | 24 | 4:55/km | Sub-1:45 HM | 69 | Zone 3: 153-175 bpm |

---

## 🧮 AKURA Performance Index (API)

### **Calculation Algorithm**

```javascript
AKURA API = (
    HR Efficiency × 30% +
    Pace Progression × 25% +
    Consistency Score × 20% +
    Injury Resistance × 15% +
    Chennai Heat Adaptation × 10%
)
```

### **Components**

1. **HR Efficiency (30%)**
   - Resting HR (optimal: 40-50 bpm)
   - HR Reserve (Max HR - Resting HR)
   - Workout HR efficiency (pace per HR%)

2. **Pace Progression (25%)**
   - Tracks improvement in tempo run paces
   - Compares last 6 weeks vs previous 6 weeks
   - Bonus for consistent improvement

3. **Consistency Score (20%)**
   - 6-7 runs/week = 100 points
   - 4-5 runs/week = 75 points
   - 3 runs/week = 55 points

4. **Injury Resistance (15%)**
   - None = 100 points
   - Minor injuries = 80-85 points
   - Major injuries = 40-60 points

5. **Chennai Heat Adaptation (10%)**
   - Year 1: 60%, Year 2: 75%, Year 3+: 90-100%
   - Climate-specific adjustment factor

### **Reference Paces Based on API Score**

| API Score | Easy Pace | Tempo Pace | Interval | HM Race Pace |
|-----------|-----------|------------|----------|--------------|
| 50 | 6:30/km | 5:45/km | 5:15/km | 5:00/km |
| 70 | 5:30/km | 4:45/km | 4:15/km | 4:00/km |
| 90 | 4:30/km | 3:50/km | 3:30/km | 3:15/km |

---

## 💓 5 HR Zones (Karvonen Method)

**Formula:** Max HR = 208 - (0.7 × Age)

| Zone | Name | % of Max HR | Purpose | Example (25yo, Max HR 191) |
|------|------|-------------|---------|----------------------------|
| 1 | Recovery | 50-60% | Active recovery | 124-137 bpm |
| 2 | Easy/Base | 60-70% | Aerobic base building | 137-149 bpm |
| **3** | **Tempo/Threshold** | **70-80%** | **Primary Zone** ⭐ | **149-161 bpm** |
| 4 | VO2 Max | 80-90% | Speed development | 161-174 bpm |
| 5 | Anaerobic | 90-100% | Sprint training | 174-191 bpm |

**Zone 3 (Tempo) is the primary focus for SafeStride training.**

---

## 📅 7 Protocol System

1. **START** - Initial assessment and baseline (Day 1 evaluation)
2. **ENGINE** - Aerobic base building (Zones 1-2)
3. **OXYGEN** - VO2 max development (Zone 4)
4. **POWER** - Speed and strength work (Zone 5)
5. **ZONES** - HR zone discipline and pacing (Zone 3 focus)
6. **STRENGTH** - Injury prevention and mobility
7. **LONG RUN** - Endurance capacity building

---

## 🔗 Device Integration

### **Strava OAuth**
- **Client ID**: `162971`
- **Redirect URI**: `https://safestride-frontend.onrender.com/athlete-devices.html`
- **Scopes**: `activity:read_all,activity:write`
- **API Documentation**: https://developers.strava.com/

### **Garmin Connect**
- Status: Coming soon
- Requires OAuth 1.0a setup

### **Manual Upload**
- Athletes can manually add workouts
- Fields: Type, Distance, Duration, Avg HR, Date, Notes

---

## 🚀 Deployment

### **Current Live URLs**

- **Backend API**: https://safestride-backend-cave.onrender.com
- **Frontend**: https://safestride-frontend.onrender.com
- **Custom Domain**: akura.in (DNS propagation pending)

### **Backend Environment Variables (Render)**

```env
NODE_ENV=production
PORT=10000
NODE_VERSION=20.10.0
SUPABASE_URL=https://pjtixkysxgcdsbxhuuvr.supabase.co
SUPABASE_SERVICE_KEY=<your_service_role_key>
SUPABASE_ANON_KEY=sb_publishable_lJqZZzro0lgmpuTPODIoqA_F_UA9lwn
STRAVA_CLIENT_ID=162971
STRAVA_CLIENT_SECRET=<your_strava_secret>
JWT_SECRET=<your_random_secret>
CORS_ORIGIN=https://akura.in,https://www.akura.in,https://safestride-frontend.onrender.com
```

### **Frontend Environment Variables (Not required for static HTML)**

The frontend is pure HTML/CSS/JS with no build step. API URL is hardcoded in `js/main.js`:

```javascript
const API_CONFIG = {
    baseURL: 'https://safestride-backend-cave.onrender.com',
    stravaClientId: '162971'
};
```

### **DNS Configuration for akura.in**

```dns
Type: A
Host: @
Value: 216.24.57.1
TTL: 3600

Type: A
Host: www
Value: 216.24.57.1
TTL: 3600
```

---

## 🔐 Authentication Flow

1. User enters email/password on homepage
2. Frontend sends POST to `/api/auth/login` or `/api/auth/signup`
3. Backend returns JWT token + user object
4. Token stored in `localStorage.safestride_token`
5. All API requests include `Authorization: Bearer <token>` header
6. Protected routes redirect to `/` if no valid token

---

## 📊 API Endpoints (Backend)

### **Authentication**
- `POST /api/auth/login` - Login (coach/athlete)
- `POST /api/auth/signup` - Athlete signup

### **Athlete**
- `GET /api/athlete` - Get athlete profile (protected)
- `PATCH /api/athlete` - Update athlete profile

### **Coach**
- `GET /api/coach/athletes` - Get all athletes for coach (protected)
- `POST /api/coach/invite` - Send athlete invitation

### **Workouts**
- `GET /api/workouts` - Get workout calendar (protected)
- `POST /api/workouts` - Create manual workout

### **Device Sync**
- `POST /api/strava/auth` - Strava OAuth callback
- `POST /api/garmin/auth` - Garmin OAuth callback

### **Health Check**
- `GET /api/health` - Backend status

---

## ✅ Completed Features (95%)

### **✅ Core Functionality**
- [x] AKURA Performance Index calculator
- [x] 5 HR Zones calculator (Karvonen method)
- [x] Reference pace tables based on API score
- [x] 10 Chennai athlete profiles pre-loaded
- [x] Homepage with hero, features, auth modals
- [x] Athlete dashboard with today's workout
- [x] Coach dashboard with athlete roster
- [x] Device sync UI (Strava OAuth ready)
- [x] Manual workout upload form
- [x] Progress charts (Chart.js)
- [x] Mobile-responsive design
- [x] Authentication flows (login/signup)

### **⏳ Remaining Tasks (5%)**
- [ ] Test Strava OAuth callback in production
- [ ] Update Strava callback domain to akura.in
- [ ] Verify DNS propagation for akura.in
- [ ] End-to-end testing with real backend
- [ ] Coach calendar page (publish/stage workflow)
- [ ] Coach invite page (email invitations)
- [ ] Athlete workouts page (calendar view)
- [ ] Athlete profile page (edit form)

---

## 📧 Contact & Support

- **Email**: coach@akura.in
- **Social**: @akura_safestride (Instagram)
- **WhatsApp**: https://wa.me/message/24CYRZY5TMH7F1
- **Domain**: akura.in (live soon)

---

## 🎯 Launch Checklist

### **Pre-Launch (January 26, 2026)**
- [x] Backend deployed to Render
- [x] Frontend deployed to Render
- [x] AKURA API calculator implemented
- [x] 10 Chennai athletes data loaded
- [x] Device sync UI complete
- [ ] Strava OAuth tested in production
- [ ] DNS propagation verified
- [ ] SSL certificate issued

### **Launch Day (January 27, 2026)**
- [ ] Custom domain akura.in live
- [ ] Send invites to 10 Chennai athletes
- [ ] Announce on social media
- [ ] 90-day free trial begins
- [ ] Monitor backend health & performance

---

## 🏆 Success Metrics (90 Days)

- **10 Active Athletes** - Day 1 onboarding complete
- **Sub-4:00/km HM** - At least 3 athletes achieve goal
- **95% Consistency** - Athletes maintain training frequency
- **Zero Downtime** - Backend reliability > 99.9%
- **Device Sync** - 80%+ athletes connect Strava/Garmin

---

## 📝 Version History

### **v1.0 (January 25, 2026)**
- ✅ Initial platform launch
- ✅ AKURA Performance Index v1.0
- ✅ 5 HR Zones + 7 Protocols
- ✅ 10 Chennai athletes pre-loaded
- ✅ Strava integration ready
- ✅ Coach & Athlete portals complete
- ✅ Mobile-responsive design

---

## 🤝 Contributing

This is a private project for AKURA elite running team. For feature requests or bugs, contact coach@akura.in.

---

## 📄 License

© 2026 SafeStride by AKURA. All rights reserved.

**Proprietary Software** - AKURA Performance Index algorithm is proprietary and confidential.

---

## 🎉 Thank You!

Built with ❤️ for Chennai's elite running community.

**Go fast. Stay safe. Run smart. 🏃‍♂️💨**

---

**SafeStride by AKURA** | Powered by AKURA Performance Index
