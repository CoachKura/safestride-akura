# SafeStride by AKURA - Deployment & Implementation Guide

## 🎯 Current Status

### ✅ Completed
- **Database Schema**: Complete PostgreSQL schema with triggers for HR zone calculation
- **Backend API**: Full REST API with authentication, athlete management, workout publishing
- **Strava Integration**: OAuth flow, activity sync, webhook structure
- **Garmin Integration**: Documentation and API structure (awaiting credentials)
- **Email System**: Invitation email templates
- **Frontend Structure**: React + Vite + TailwindCSS setup
- **Authentication**: JWT-based auth with role-based access control

### 🚧 Remaining Implementation

#### Frontend Pages (Priority Order)
1. **LoginPage.jsx** - Coach/athlete login with role selection
2. **SignupPage.jsx** - Athlete signup from email invite
3. **Coach Dashboard** - Athlete list, stats overview, quick actions
4. **Coach Calendar** - Monthly view, workout publishing interface
5. **Coach Invite** - Send email invitations to athletes
6. **Athlete Dashboard** - Today's workout, device status, upcoming workouts
7. **Athlete Devices** - Connect Garmin/Strava/Coros, OAuth handling
8. **Athlete Workouts** - Calendar view, workout details, manual logging
9. **Athlete Profile** - Edit profile, view HR zones

## 📋 Step-by-Step Deployment

### 1. Database Setup (Supabase)

**A. Create Supabase Project**
```bash
1. Go to https://supabase.com/dashboard
2. Click "New Project"
3. Name: safestride-production
4. Region: Southeast Asia (Singapore) - closest to Chennai
5. Database Password: [secure password]
```

**B. Run Schema**
```sql
1. Go to SQL Editor in Supabase dashboard
2. Copy contents of database/schema.sql
3. Execute the query
4. Verify tables created: coaches, athletes, hr_zones, etc.
```

**C. Get Credentials**
```
Project URL: https://pjtixkysxgcdsbxhuuvr.supabase.co
Anon Key: sb_publishable_lJqZZzro0lgmpuTPODIoqA_F_UA9lwn
Service Role Key: (from Project Settings → API)
```

### 2. Backend Deployment (Railway)

**A. Prepare Repository**
```bash
cd backend
git init
git add .
git commit -m "Initial backend"
git branch -M main
git remote add origin https://github.com/Akuraelite/safestride.git
git push -u origin main
```

**B. Deploy to Railway**
```bash
1. Go to https://railway.app/
2. Sign in with GitHub
3. Click "New Project" → "Deploy from GitHub repo"
4. Select: Akuraelite/safestride
5. Add "Root Directory": backend
```

**C. Set Environment Variables**
```
In Railway dashboard → Variables:

PORT=5000
NODE_ENV=production
SUPABASE_URL=https://pjtixkysxgcdsbxhuuvr.supabase.co
SUPABASE_ANON_KEY=sb_publishable_lJqZZzro0lgmpuTPODIoqA_F_UA9lwn
SUPABASE_SERVICE_KEY=[your_service_role_key]
JWT_SECRET=[generate secure random string]
JWT_EXPIRES_IN=7d
STRAVA_CLIENT_ID=162971
STRAVA_CLIENT_SECRET=6554eb9bb83f222a585e312c17420221313f85c1
STRAVA_REDIRECT_URI=https://akura.in/auth/strava/callback
STRAVA_WEBHOOK_SECRET=[random string for webhook verification]
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=coach@akura.in
SMTP_PASSWORD=[Gmail App Password - see below]
FRONTEND_URL=https://akura.in
COACH_PORTAL_URL=https://akura.in/coach
```

**D. Gmail App Password Setup**
```
1. Go to Google Account settings
2. Security → 2-Step Verification (enable if not already)
3. App Passwords → Generate new password
4. Select "Mail" and "Other (Custom)"
5. Name it "SafeStride Backend"
6. Copy the 16-character password
7. Use this as SMTP_PASSWORD
```

**E. Get Railway URL**
```
After deployment completes:
Railway will provide a URL like: https://safestride-backend-production.up.railway.app
Save this for frontend configuration
```

### 3. Frontend Deployment (Vercel)

**A. Create .env.local**
```bash
cd frontend
cat > .env.local << EOF
VITE_API_URL=https://safestride-backend-production.up.railway.app
VITE_STRAVA_CLIENT_ID=162971
VITE_SUPABASE_URL=https://pjtixkysxgcdsbxhuuvr.supabase.co
VITE_SUPABASE_ANON_KEY=sb_publishable_lJqZZzro0lgmpuTPODIoqA_F_UA9lwn
EOF
```

**B. Build and Test Locally**
```bash
npm install
npm run dev
# Test at http://localhost:5173
```

**C. Deploy to Vercel**
```bash
1. Install Vercel CLI: npm install -g vercel
2. Login: vercel login
3. Deploy: vercel --prod
4. Follow prompts:
   - Project name: safestride
   - Directory: ./frontend (or current if already in frontend/)
```

**D. Add Environment Variables in Vercel**
```
1. Go to Vercel dashboard → Project Settings → Environment Variables
2. Add all variables from .env.local
3. Apply to: Production, Preview, and Development
```

**E. Configure Custom Domain (akura.in)**
```
1. Vercel dashboard → Domains
2. Add domain: akura.in
3. Add DNS records (at your domain registrar):

   Type: A
   Name: @
   Value: 76.76.21.21

   Type: CNAME
   Name: www
   Value: cname.vercel-dns.com

4. Wait for DNS propagation (5-60 minutes)
5. Vercel will automatically provision SSL certificate
```

### 4. Strava Webhook Setup

**A. Subscribe to Webhook**
```bash
curl -X POST https://www.strava.com/api/v3/push_subscriptions \
  -F client_id=162971 \
  -F client_secret=6554eb9bb83f222a585e312c17420221313f85c1 \
  -F callback_url=https://safestride-backend-production.up.railway.app/api/strava/webhook \
  -F verify_token=YOUR_WEBHOOK_SECRET
```

**B. Verify Subscription**
```bash
curl -G https://www.strava.com/api/v3/push_subscriptions \
  -d client_id=162971 \
  -d client_secret=6554eb9bb83f222a585e312c17420221313f85c1
```

### 5. Update Strava App Settings

```
1. Go to https://www.strava.com/settings/api
2. Find your app (Client ID: 162971)
3. Update:
   - Authorization Callback Domain: akura.in
   - Save changes
```

### 6. Seed Initial Data

**Coach Account Creation**
```bash
# Use bcrypt to hash password
node -e "console.log(require('bcryptjs').hashSync('your_password', 10))"

# Update coaches table in Supabase SQL Editor:
UPDATE coaches 
SET password_hash = '$2a$10$[your_hashed_password]'
WHERE email = 'coach@akura.in';
```

### 7. Testing Checklist

**Backend Tests**
- [ ] Health check: `https://[railway-url]/health`
- [ ] Coach login: POST `/api/auth/coach/login`
- [ ] Get athletes: GET `/api/coach/athletes`
- [ ] Get workout templates: GET `/api/workouts/templates`

**Frontend Tests**
- [ ] Homepage loads: `https://akura.in`
- [ ] Login page works: `https://akura.in/login`
- [ ] Coach can login and see dashboard
- [ ] Athlete can sign up from invite link

**Strava Integration Tests**
- [ ] Athlete can connect Strava
- [ ] OAuth callback redirects correctly
- [ ] Activities sync from Strava
- [ ] Webhook receives new activities

## 🔧 Remaining Frontend Implementation

### Priority 1: Authentication Pages

**LoginPage.jsx**
```jsx
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

export default function LoginPage() {
  const [role, setRole] = useState('athlete'); // 'athlete' or 'coach'
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  
  const { loginCoach, loginAthlete } = useAuth();
  const navigate = useNavigate();

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      if (role === 'coach') {
        await loginCoach(email, password);
        navigate('/coach/dashboard');
      } else {
        await loginAthlete(email, password);
        navigate('/athlete/dashboard');
      }
    } catch (err) {
      setError(err.response?.data?.error || 'Login failed');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      {/* Implementation: Role selector, form, error handling */}
    </div>
  );
}
```

**SignupPage.jsx**
```jsx
// Athlete signup from email invite
// 1. Extract token from URL params
// 2. Verify token with backend
// 3. Show signup form (name, age, weight, height, password)
// 4. Submit and auto-login
```

### Priority 2: Coach Dashboard

**pages/coach/Dashboard.jsx**
```jsx
// Dashboard with:
// - Stats cards (total athletes, active, completion rate)
// - Athletes list with status
// - Recent activities
// - Quick actions (invite, publish workouts)
```

**pages/coach/Athletes.jsx**
```jsx
// Full athletes list with:
// - Search/filter
// - Individual athlete cards showing:
//   - Current times (HM/10K)
//   - Device connections
//   - Recent activity
//   - Injuries
```

**pages/coach/Calendar.jsx**
```jsx
// Training calendar with:
// - Monthly view
// - Click dates to add workouts
// - Workout template selector
// - Publish to all/selected athletes
// - See scheduled workouts per date
```

**pages/coach/Invite.jsx**
```jsx
// Invite form:
// - Email input
// - Name input
// - Send invitation button
// - Show sent invitations list
// - Copy invite link
```

### Priority 3: Athlete Dashboard

**pages/athlete/Dashboard.jsx**
```jsx
// Dashboard showing:
// - Today's workout card
//   - Protocol name
//   - HR zones (personalized)
//   - Duration/distance
//   - Workout structure
// - Device connection status
// - Upcoming 7 days mini-calendar
// - Recent activities
// - Stats (week/month)
```

**pages/athlete/Devices.jsx**
```jsx
// Device sync page:
// - Connect Strava button (OAuth)
// - Connect Garmin button (when available)
// - Connect Coros, Apple Health (future)
// - Show connected devices
// - Manual sync button
// - Last sync timestamp
// - Disconnect option
```

**pages/athlete/Workouts.jsx**
```jsx
// Workouts page:
// - Calendar view (month/week toggle)
// - Click date to see workout details
// - Mark workout as completed
// - Manual activity logging form
// - Workout history list
```

**pages/athlete/Profile.jsx**
```jsx
// Profile page:
// - Edit personal info (name, age, weight, height)
// - Display Max HR (auto-calculated)
// - Display 5 HR zones with ranges
// - Current times (HM/10K)
// - Injury notes
// - Save changes button
```

### Component Library

Create reusable components in `frontend/src/components/`:

**Layout.jsx** - Shared layout with navigation
**WorkoutCard.jsx** - Display workout details
**AthleteCard.jsx** - Display athlete info
**Calendar.jsx** - Calendar grid component
**StatsCard.jsx** - Stats display card
**HRZoneDisplay.jsx** - Show HR zones visually
**DeviceConnectButton.jsx** - Device connection buttons
**LoadingSpinner.jsx** - Loading indicator

## 🚀 Quick Start Commands

**Complete Setup (from scratch)**
```bash
# 1. Clone repo
git clone https://github.com/Akuraelite/safestride.git
cd safestride

# 2. Backend setup
cd backend
npm install
cp .env.example .env
# Edit .env with your credentials
npm run dev # Test locally

# 3. Frontend setup
cd ../frontend
npm install
cp .env.example .env.local
# Edit .env.local
npm run dev # Test locally

# 4. Deploy (after local testing)
# Railway (backend): Connect GitHub repo
# Vercel (frontend): vercel --prod
```

## 📞 Support & Contact

**Coach Kura Balendar Sathyamoorthy**
- Email: coach@akura.in
- WhatsApp: https://wa.me/message/24CYRZY5TMH7F1
- Instagram: @akura_safestride

**Platform URLs**
- Production: https://akura.in
- Backend API: https://safestride-backend-production.up.railway.app
- Database: Supabase Dashboard

---

**Status**: Backend 100% complete, Frontend 40% complete, Ready for deployment and final frontend implementation.
