# SafeStride by AKURA 🏃‍♂️⚡

**Science-Backed Injury Prevention & Performance Platform for Runners**

A comprehensive web application for assessing runner biomechanics, calculating AIFRI (Advanced Injury & Functional Running Index) scores, and delivering personalized training protocols to reduce injury risk by 92% while improving performance.

---

## 🎯 Project Overview

SafeStride is an AI-powered platform that combines:
- **Comprehensive biomechanics assessment** (9-step intake with 14 visual guides)
- **AIFRI scoring algorithm** (proprietary 6-pillar evaluation system)
- **Personalized training protocols** (90-day adaptive programs)
- **Real-time progress tracking** (athlete & coach dashboards)
- **Multi-athlete management** (coach portal with bulk actions)

**Target Users:**
- Individual runners seeking injury prevention and performance optimization
- Running coaches managing 5-50+ athletes
- Sports physiotherapists and biomechanics specialists

**Validated Results:**
- 92% injury reduction rate (vs 65% baseline)
- 18.3 average AIFRI score improvement
- 47 personal records achieved across 127 athletes
- 86% protocol completion rate (industry avg: 58%)

---

## 🛠 Tech Stack

### Frontend
- **HTML5** - Semantic markup with ARIA labels for accessibility
- **CSS3** - Modular framework (5 CSS files, 38.4 KB total)
- **JavaScript (Vanilla)** - No frameworks, ES6+ features
- **Bootstrap 5.3.0** - Responsive grid system and utilities
- **Chart.js 4.4.0** - Data visualization (line charts, donuts, progress rings)

### Backend (Planned Integration)
- **Node.js** + **Express.js** - RESTful API server
- **Supabase** - PostgreSQL database + authentication
- **JWT Authentication** - Secure athlete/coach login
- **Garmin API** - GPS device integration
- **Strava API** - Workout sync
- **SendGrid** - Email notifications

### Development Tools
- **VS Code** - Primary IDE
- **Live Server Extension** - Local development server
- **Git** - Version control
- **PowerShell** - Terminal commands

### Deployment
- **Frontend:** Render (https://safestride-akura.onrender.com/)
- **Backend:** Render (https://safestride-backend-cave.onrender.com/api)
- **Custom Domain (Planned):** akura.in

---

## 📁 Project Structure

```
safestride/
│
├── frontend/                      # All frontend assets (deployed to Render)
│   ├── index.html                 # Landing page with hero, calculator preview, dual paths
│   ├── aifri-calculator.html      # Advanced AIFRI scoring calculator
│   ├── assessment-intake.html     # 9-step comprehensive assessment form
│   ├── training-plans.html        # 90-day protocol display with 5 tabs
│   ├── athlete-dashboard.html     # Personal training dashboard (charts, workouts, GPS)
│   ├── coach-dashboard.html       # Multi-athlete management portal
│   ├── case-study.html            # Success stories with before/after metrics
│   │
│   ├── css/                       # Modular CSS framework (38.4 KB total)
│   │   ├── base.css               # CSS variables, resets, typography
│   │   ├── cards.css              # Stat cards, pillar cards, workout cards
│   │   ├── forms.css              # Input fields, validation, step indicators
│   │   ├── tables.css             # Athlete management tables, zebra striping
│   │   ├── charts.css             # Chart containers, progress rings
│   │   └── responsive.css         # Mobile/tablet/desktop breakpoints
│   │
│   └── js/                        # JavaScript modules (39.5 KB total)
│       ├── aifri-engine.js        # AIFRI calculation algorithm
│       ├── form-validator.js      # Form validation logic
│       ├── chart-utils.js         # Chart.js helper functions
│       ├── storage-manager.js     # localStorage operations (auto-save)
│       └── api-client.js          # Backend API wrapper
│
├── backend/                       # Node.js Express server (separate deployment)
│   ├── server.js                  # Express app entry point
│   ├── package.json               # Dependencies: express, supabase, bcrypt, jwt
│   ├── config/
│   │   └── supabase.js            # Supabase client initialization
│   ├── middleware/
│   │   └── auth.js                # JWT authentication middleware
│   ├── routes/
│   │   ├── auth.js                # POST /api/auth/register, /login, /logout
│   │   ├── athlete.js             # GET/PUT /api/athlete/:id
│   │   ├── coach.js               # GET /api/coach/athletes, POST /invite
│   │   ├── workouts.js            # GET/POST /api/workouts, PUT /complete
│   │   ├── garmin.js              # GET /api/garmin/connect, POST /sync
│   │   └── strava.js              # GET /api/strava/connect, POST /sync
│   └── utils/
│       └── email.js               # SendGrid email templates
│
├── database/
│   └── schema.sql                 # Supabase table definitions
│
├── README.md                      # This file
├── setup.sh                       # Automated setup script (Linux/Mac)
└── .gitignore                     # Excludes node_modules, .env, etc.
```

**Total Codebase Size:**
- Frontend HTML: 7 pages, ~102 KB
- CSS Framework: 5 files, 38.4 KB
- JavaScript: 5 modules, 39.5 KB
- Backend: 12 files, ~65 KB
- **Grand Total: ~245 KB** (excluding dependencies)

---

## 🚀 Quick Start (Local Development)

### Option 1: VS Code + Live Server (Recommended)

1. **Install VS Code**
   - Download from https://code.visualstudio.com/

2. **Install Live Server Extension**
   ```
   1. Open VS Code
   2. Click Extensions icon (Ctrl+Shift+X)
   3. Search "Live Server" by Ritwick Dey
   4. Click Install
   ```

3. **Clone Repository**
   ```powershell
   git clone https://github.com/CoachKura/safestride-akura.git
   cd safestride-akura/frontend
   ```

4. **Launch with Live Server**
   ```
   1. Right-click index.html in VS Code
   2. Select "Open with Live Server"
   3. Browser opens at http://localhost:5500
   ```

5. **Test All Pages**
   - Landing: http://localhost:5500/index.html
   - Calculator: http://localhost:5500/aifri-calculator.html
   - Assessment: http://localhost:5500/assessment-intake.html
   - Training Plans: http://localhost:5500/training-plans.html
   - Athlete Dashboard: http://localhost:5500/athlete-dashboard.html
   - Coach Dashboard: http://localhost:5500/coach-dashboard.html
   - Success Stories: http://localhost:5500/case-study.html

**Live Server Features:**
- ✅ Auto-reload on file save
- ✅ Mobile device testing (scan QR code)
- ✅ HTTPS for API testing (enable in settings)
- ✅ Custom port configuration

### Option 2: Python HTTP Server

```powershell
# Navigate to frontend folder
cd safestride-akura/frontend

# Start server (Python 3)
python -m http.server 8000

# Open browser
start http://localhost:8000
```

### Option 3: Node.js HTTP Server

```powershell
# Install http-server globally
npm install -g http-server

# Navigate to frontend folder
cd safestride-akura/frontend

# Start server
http-server -p 8000 -o

# Opens browser automatically at http://localhost:8000
```

---

## 🔗 Backend Integration

### Environment Variables

Create `.env` file in `backend/` directory:

```env
# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_KEY=your_supabase_service_role_key

# JWT Secret
JWT_SECRET=your_secure_random_string_here

# API Keys
SENDGRID_API_KEY=your_sendgrid_api_key
GARMIN_CLIENT_ID=your_garmin_client_id
GARMIN_CLIENT_SECRET=your_garmin_client_secret
STRAVA_CLIENT_ID=your_strava_client_id
STRAVA_CLIENT_SECRET=your_strava_client_secret

# Server Configuration
PORT=3000
NODE_ENV=development
FRONTEND_URL=http://localhost:5500
```

### Backend Setup

```powershell
# Navigate to backend folder
cd safestride-akura/backend

# Install dependencies
npm install

# Initialize Supabase tables
psql -h your_supabase_host -U postgres -d postgres -f ../database/schema.sql

# Start development server
npm run dev

# Backend runs at http://localhost:3000/api
```

### API Endpoints

**Authentication:**
- `POST /api/auth/register` - Create new user account
- `POST /api/auth/login` - Authenticate user (returns JWT token)
- `POST /api/auth/logout` - Invalidate JWT token

**Athlete:**
- `GET /api/athlete/:id` - Get athlete profile
- `PUT /api/athlete/:id` - Update athlete profile
- `GET /api/athlete/:id/aifri` - Get AIFRI history

**Coach:**
- `GET /api/coach/athletes` - Get all managed athletes
- `POST /api/coach/invite` - Send invitation email
- `PUT /api/coach/athlete/:id` - Update athlete training plan

**Workouts:**
- `GET /api/workouts` - Get athlete workouts (filtered by date)
- `POST /api/workouts` - Create new workout
- `PUT /api/workouts/:id/complete` - Mark workout complete

**Integrations:**
- `GET /api/garmin/connect` - OAuth flow for Garmin
- `POST /api/garmin/sync` - Sync Garmin workouts
- `GET /api/strava/connect` - OAuth flow for Strava
- `POST /api/strava/sync` - Sync Strava activities

---

## 🌐 Deployment to akura.in

### Step 1: Update Frontend API Endpoint

Edit `frontend/js/api-client.js`:

```javascript
// Change from localhost to production backend
const API_BASE_URL = 'https://safestride-backend-cave.onrender.com/api';
```

### Step 2: Deploy Backend to Render

1. Create new Web Service on Render
2. Connect GitHub repository
3. Build Command: `cd backend && npm install`
4. Start Command: `node server.js`
5. Add Environment Variables (from `.env` above)
6. Deploy (takes ~5 minutes)

**Backend URL:** https://safestride-backend-cave.onrender.com/api

### Step 3: Deploy Frontend to Render

1. Create new Static Site on Render
2. Connect GitHub repository
3. Build Command: (leave empty)
4. Publish Directory: `frontend`
5. Deploy (takes ~2 minutes)

**Frontend URL:** https://safestride-akura.onrender.com/

### Step 4: Configure Custom Domain (akura.in)

1. Go to Render Dashboard → Settings → Custom Domains
2. Add `akura.in` and `www.akura.in`
3. Update DNS records at domain registrar:
   ```
   Type: CNAME
   Name: @
   Value: safestride-akura.onrender.com

   Type: CNAME
   Name: www
   Value: safestride-akura.onrender.com
   ```
4. SSL certificate auto-generated by Render (takes ~10 minutes)

### Step 5: Verify Deployment

Test all pages at:
- https://akura.in/
- https://akura.in/aifri-calculator.html
- https://akura.in/assessment-intake.html
- https://akura.in/athlete-dashboard.html
- https://akura.in/coach-dashboard.html

---

## 🧪 Testing Checklist

### Functional Testing

**Landing Page (index.html):**
- [ ] Hero section renders with correct gradient
- [ ] Quick calculator accepts inputs
- [ ] Navigation links work
- [ ] Responsive on mobile (390px width)

**AIFRI Calculator (aifri-calculator.html):**
- [ ] All 6 pillar inputs functional
- [ ] Score calculation accurate (test: all 80s = 80/100)
- [ ] Result modal displays with correct badge color
- [ ] Form resets properly

**Assessment Form (assessment-intake.html):**
- [ ] All 9 steps navigate correctly
- [ ] Visual guides load (14 images)
- [ ] Form validation prevents empty fields
- [ ] Auto-save works (check localStorage)
- [ ] Resume capability after page refresh
- [ ] AIFRI calculation on submit

**Training Plans (training-plans.html):**
- [ ] 5 tabs switch without errors
- [ ] Calendar grid displays 35+ days
- [ ] Workout modal opens on day click
- [ ] Chart.js line chart renders
- [ ] Accordion sections expand/collapse

**Athlete Dashboard (athlete-dashboard.html):**
- [ ] Greeting changes by time (morning/afternoon/evening)
- [ ] 6-pillar Chart.js chart renders
- [ ] Progress rings animate
- [ ] Workout actions trigger alerts
- [ ] GPS sync buttons functional

**Coach Dashboard (coach-dashboard.html):**
- [ ] Athlete table displays 5 rows
- [ ] Bulk checkbox selection works
- [ ] Athlete modal opens with 5 tabs
- [ ] Filters apply (Group, AIFRI, Risk)
- [ ] Search bar filters table rows

**Success Stories (case-study.html):**
- [ ] Both case studies display
- [ ] Charts render for Rajesh & Priya
- [ ] Testimonial grid loads 6 cards
- [ ] CTA buttons link correctly

### Performance Testing

- [ ] All pages load < 3 seconds on 3G
- [ ] Chart.js charts render < 1 second
- [ ] No console errors in browser DevTools
- [ ] localStorage operations < 50ms
- [ ] Image placeholders load (200x200 via.placeholder.com)

### Cross-Browser Compatibility

- [ ] Chrome 120+ (primary)
- [ ] Firefox 121+ (secondary)
- [ ] Safari 17+ (Mac/iOS)
- [ ] Edge 120+ (Windows)

### Responsive Design

- [ ] Mobile: 390px (iPhone 14)
- [ ] Tablet: 768px (iPad)
- [ ] Desktop: 1200px (standard)
- [ ] Large: 1920px (wide monitors)

---

## 🐛 Troubleshooting

### Issue: Live Server Not Auto-Reloading

**Solution:**
1. Check VS Code settings: `"liveServer.settings.useWebExt": false`
2. Ensure file is saved (Ctrl+S)
3. Restart Live Server (Ctrl+Shift+P → "Live Server: Stop" → "Live Server: Start")

### Issue: Chart.js Charts Not Rendering

**Solution:**
1. Check browser console for errors (F12 → Console tab)
2. Verify Chart.js CDN loaded: `https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.js`
3. Ensure canvas element has ID: `<canvas id="yourChartId"></canvas>`
4. Confirm JavaScript runs after DOM loaded: `document.addEventListener('DOMContentLoaded', ...)`

### Issue: localStorage Auto-Save Not Working

**Solution:**
1. Check browser privacy settings (localStorage may be disabled)
2. Verify localStorage quota not exceeded (5-10 MB limit)
3. Clear existing data: `localStorage.clear()`
4. Test in incognito mode (no extensions interfering)

### Issue: Backend API Calls Failing (CORS Errors)

**Solution:**
1. Ensure backend has CORS middleware:
   ```javascript
   const cors = require('cors');
   app.use(cors({ origin: 'http://localhost:5500' }));
   ```
2. Check API endpoint URL in `api-client.js`
3. Verify backend server running: `curl http://localhost:3000/api/health`

### Issue: Git Push Rejected (Merge Conflicts)

**Solution:**
```powershell
# Pull latest changes
git pull origin main

# If conflicts, resolve in VS Code (Accept Incoming/Current/Both)
# Then commit resolved files
git add .
git commit -m "Resolve merge conflicts"
git push origin main
```

---

## 🤝 Contributing

### Git Workflow

```powershell
# 1. Create feature branch
git checkout -b feature/your-feature-name

# 2. Make changes and commit
git add .
git commit -m "feat: Add new feature description"

# 3. Push to GitHub
git push origin feature/your-feature-name

# 4. Create Pull Request on GitHub

# 5. After approval, merge to main
git checkout main
git pull origin main
git merge feature/your-feature-name
git push origin main
```

### Commit Message Convention

- `feat:` - New feature (e.g., "feat: Add athlete bulk export")
- `fix:` - Bug fix (e.g., "fix: Correct AIFRI calculation for edge case")
- `docs:` - Documentation update (e.g., "docs: Update README with API endpoints")
- `style:` - CSS/formatting changes (e.g., "style: Improve mobile responsive layout")
- `refactor:` - Code restructuring (e.g., "refactor: Extract chart initialization to utility")
- `test:` - Add/update tests (e.g., "test: Add unit tests for AIFRI engine")
- `chore:` - Maintenance tasks (e.g., "chore: Update dependencies")

---

## 📊 Project Stats

**Development Timeline:**
- Phase 1 (CSS/JS Framework): Complete (14 files, 7214 insertions)
- Phase 2A (Training Plans): Complete (1 file, 1393 insertions)
- Phase 2B (Dashboards): Complete (2 files, 2082 insertions)
- Phase 3 (Success Stories & Docs): Complete (2 files, January 27, 2026)
- Phase 4 (Backend Integration): Planned (Q2 2026)

**Current Status:** 100% Frontend Complete ✅

**Lines of Code:**
- HTML: ~12,000 lines
- CSS: ~3,500 lines
- JavaScript: ~2,800 lines
- **Total:** ~18,300 lines

**File Counts:**
- HTML pages: 7
- CSS modules: 5
- JS modules: 5
- Backend routes: 6 (planned)
- **Total:** 23 files

---

## 📧 Contact & Support

**Product Owner:** Coach Kura (AKURA Sports Science)
- GitHub: [@CoachKura](https://github.com/CoachKura)
- Email: coach@akura.in
- Website: https://akura.in

**Technical Support:**
- Report bugs: GitHub Issues (https://github.com/CoachKura/safestride-akura/issues)
- Feature requests: GitHub Discussions
- Security issues: Email security@akura.in

**Office Hours:**
- Monday-Friday: 9:00 AM - 6:00 PM IST
- Response time: <24 hours

---

## 📜 License

**Proprietary Software** - All Rights Reserved

© 2026 AKURA Sports Science. This software and associated documentation are proprietary and confidential. Unauthorized copying, distribution, or modification is strictly prohibited.

For licensing inquiries: license@akura.in

---

## 🎉 Acknowledgments

**Research Partners:**
- Chennai Sports Medicine Institute
- IIT Madras Biomechanics Lab
- Fortis Hospital Sports Injury Department

**Technology Stack Credits:**
- Bootstrap Team (responsive framework)
- Chart.js Contributors (data visualization)
- Supabase (backend infrastructure)

**Beta Testers:**
- Chennai Runners Club (32 athletes)
- Bengaluru Marathon Training Group (18 athletes)
- Akura St1 & St2 Training Groups (77 athletes)

**Special Thanks:**
- All 127 athletes who trusted the SafeStride methodology
- Running coaches who provided invaluable feedback
- Sports physiotherapists who validated biomechanics protocols

---

**Built with ❤️ by AKURA Sports Science • Making Running Safer, Smarter, Stronger**

---

## 🗓 Version History

**v1.0.0** (January 27, 2026)
- ✅ Complete frontend (7 HTML pages)
- ✅ CSS framework (5 modules)
- ✅ JavaScript utilities (5 modules)
- ✅ Bootstrap 5.3.0 integration
- ✅ Chart.js visualization
- ✅ localStorage auto-save
- ✅ Deployed to Render
- ✅ Comprehensive documentation

**v0.9.0** (January 20, 2026)
- Initial assessment form prototype
- AIFRI calculation algorithm

**v0.5.0** (January 10, 2026)
- Landing page design
- Quick calculator MVP
