# 🚀 AISRi Web Platform

Production-ready SaaS platform for **AISRi** (Artificial Intelligence Sports Risk Intelligence) - AI-powered performance and injury prevention for endurance athletes.

## 📋 Tech Stack

- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS + shadcn/ui
- **Auth**: Supabase Auth (JWT + RLS)
- **Database**: Supabase PostgreSQL
- **AI Engine**: FastAPI (api.akura.in)
- **Deployment**: Vercel (recommended)

---

## 🏗️ **Architecture**

```
┌─────────────────────────────────────────────┐
│  Next.js Web Platform                        │
│  ├── Public Landing Page                    │
│  ├── Auth (Login/Signup)                    │
│  ├── Athlete Dashboard                       │
│  ├── Coach Dashboard                         │
│  └── Admin Dashboard                         │
└──────────────┬──────────────────────────────┘
               │
    ┌──────────┴───────────┬───────────────────┐
    ▼                      ▼                   ▼
┌─────────┐         ┌────────────┐      ┌─────────────┐
│Supabase │◄────────│ FastAPI    │      │ Flutter App │
│Database │         │ AI Engine  │      │  (Mobile)   │
│+ Auth   │         │api.akura.in│      │  (Existing) │
└─────────┘         └────────────┘      └─────────────┘
```

---

## 🚀 **Quick Start**

### **1. Clone and Install**

```bash
cd c:\safestride\aisri-web-platform
npm install
```

### **2. Configure Environment**

Copy and edit `.env.local`:

```bash
cp .env.local.example .env.local
```

Update with your keys:

```env
NEXT_PUBLIC_SUPABASE_URL=https://bdisppaxbvygsspcuymb.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
NEXT_PUBLIC_AISRI_API_URL=https://api.akura.in
```

### **3. Run Database Migration**

1. Open Supabase SQL Editor: https://app.supabase.com/project/bdisppaxbvygsspcuymb/sql
2. Copy content from `database/migrations/01_evaluation_responses.sql`
3. Paste and click **RUN**
4. Verify table created: Dashboard → Table Editor → `evaluation_responses`

### **4. Start Development Server**

```bash
npm run dev
```

Open: http://localhost:3000

---

## 📁 **Project Structure**

```
aisri-web-platform/
├── app/                          # Next.js App Router
│   ├── (auth)/                   # Auth routes
│   │   ├── login/
│   │   └── signup/
│   ├── (dashboard)/              # Protected routes
│   │   ├── athlete/
│   │   │   ├── dashboard/        # Athlete dashboard
│   │   │   ├── evaluation/       # Onboarding form
│   │   │   ├── workouts/         # Workout history
│   │   │   └── chat/             # AI coach chat
│   │   ├── coach/
│   │   │   ├── dashboard/        # Coach dashboard
│   │   │   └── athletes/         # Athletes management
│   │   └── admin/
│   │       └── dashboard/        # Admin dashboard
│   ├── api/                      # API routes
│   │   └── auth/
│   └── page.tsx                  # Landing page
│
├── components/                   # React components
│   ├── ui/                       # shadcn/ui components
│   ├── layout/                   # Header, Sidebar, Footer
│   ├── athlete/                  # Athlete components
│   ├── coach/                    # Coach components
│   └── landing/                  # Landing page sections
│
├── lib/                          # Utility libraries
│   ├── supabase/                 # Supabase clients
│   │   ├── client.ts             # Browser client
│   │   └── server.ts             # Server client
│   ├── api/
│   │   └── aisri-client.ts       # FastAPI client
│   └── hooks/                    # React hooks
│
├── types/                        # TypeScript types
│   ├── database.ts               # Database types
│   └── aisri.ts                  # API types
│
├── database/                     # Database migrations
│   └── migrations/
│       └── 01_evaluation_responses.sql
│
└── public/                       # Static assets
```

---

## 🔐 **Authentication Flow**

### **Role-Based Access Control**

| Role        | Access                                      |
| ----------- | ------------------------------------------- |
| **Athlete** | Own dashboard, evaluation, workouts, chat   |
| **Coach**   | All assigned athletes, messaging, analytics |
| **Admin**   | Full system access, user management         |

### **Supabase Auth Integration**

```typescript
// Sign up
const { data, error } = await supabase.auth.signUp({
  email: "athlete@example.com",
  password: "secure_password",
});

// Login
const { data, error } = await supabase.auth.signInWithPassword({
  email: "athlete@example.com",
  password: "secure_password",
});

// Get session
const {
  data: { session },
} = await supabase.auth.getSession();
```

---

## 🎯 **Implementation Phases**

### **Phase 1: Foundation (Days 1-2)** ✅

- [x] Project setup (Next.js, TypeScript, Tailwind)
- [x] Supabase integration
- [x] FastAPI client wrapper
- [x] Database migration
- [ ] Landing page
- [ ] Auth pages (login/signup)

### **Phase 2: Athlete Experience (Days 3-5)**

- [ ] Evaluation form (multi-step onboarding)
- [ ] Athlete dashboard
  - [ ] Injury risk score card
  - [ ] Performance predictions
  - [ ] Today's workout
  - [ ] Progress charts
- [ ] AI coach chat interface

### **Phase 3: Coach Experience (Days 6-7)**

- [ ] Coach dashboard
  - [ ] Athletes list (sortable, filterable)
  - [ ] Risk alerts
  - [ ] Compliance tracking
- [ ] Athlete detail view
- [ ] Messaging panel

### **Phase 4: Admin & Polish (Days 8-10)**

- [ ] Admin dashboard
- [ ] User management
- [ ] System analytics
- [ ] Error handling
- [ ] Loading states
- [ ] Mobile responsiveness
- [ ] Dark mode

---

## 🗄️ **Database Tables**

### **Existing Tables (Already in Supabase)**

- `profiles` - User accounts
- `athlete_coach_relationships` - Coach-athlete links
- `AISRI_assessments` - Injury risk scores
- `athlete_detailed_profile` - Comprehensive athlete data
- `workout_assignments` - Scheduled workouts
- `workout_results` - Completed workouts
- `ability_progression` - Progress tracking

### **New Table (Added for Web Platform)**

- `evaluation_responses` - Athlete onboarding evaluation data

---

## 🔌 **API Integration**

### **AISRi AI Engine Endpoints**

```typescript
import { aisriClient } from "@/lib/api/aisri-client";

// Predict injury risk
const risk = await aisriClient.predictInjuryRisk(athleteId);
// Returns: { risk_level, risk_score, recommendation }

// Predict performance
const performance = await aisriClient.predictPerformance(athleteId);
// Returns: { vo2_max, predictions: { "5K", "10K", "Half", "Marathon" } }

// Generate training plan
const plan = await aisriClient.generateTrainingPlan(athleteId);
// Returns: { plan: [{ day, workout_type, duration, intensity }] }

// Get autonomous decision
const decision = await aisriClient.getAutonomousDecision(athleteId);
// Returns: { decision, reason, recommendation, aisri_score }
```

---

## 📱 **Multi-Platform Ecosystem**

| Platform              | Status      | Purpose                            |
| --------------------- | ----------- | ---------------------------------- |
| **Web Platform**      | 🚧 Building | Main SaaS interface (this project) |
| **Flutter Mobile**    | ✅ Live     | iOS/Android native app             |
| **Telegram Bot**      | ✅ Live     | Daily check-ins, quick advice      |
| **FastAPI AI Engine** | ✅ Live     | ML models, predictions, decisions  |

---

## 🎨 **Design System**

Using **shadcn/ui** for consistent, accessible components:

```bash
# Install shadcn/ui components
npx shadcn-ui@latest add button
npx shadcn-ui@latest add card
npx shadcn-ui@latest add form
npx shadcn-ui@latest add input
npx shadcn-ui@latest add dialog
```

**Color Palette (Tailwind)**:

- Primary: Blue (`hsl(222.2 47.4% 11.2%)`)
- Secondary: Gray
- Success: Green
- Warning: Yellow
- Danger: Red

---

## 🚀 **Deployment**

### **Vercel (Recommended)**

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Set environment variables in Vercel Dashboard
# Project Settings → Environment Variables
```

### **Environment Variables (Production)**

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (secret)
- `NEXT_PUBLIC_AISRI_API_URL`

---

## 📊 **Scale Target**

**B (1,000-5,000 athletes)**

- Next.js: Handles 10,000+ concurrent users
- Supabase: Auto-scales PostgreSQL
- Vercel: Serverless edge functions
- FastAPI: Horizontal scaling

---

## 🛠️ **Development Commands**

```bash
# Development
npm run dev              # Start dev server (port 3000)

# Build
npm run build            # Production build
npm run start            # Start production server

# Type checking
npm run type-check       # TypeScript type check

# Linting
npm run lint             # ESLint check
```

---

## 📝 **Next Steps**

### **Immediate Actions:**

1. **Install dependencies**: `npm install`
2. **Run database migration**: Execute `01_evaluation_responses.sql` in Supabase
3. **Copy `.env.local.example`** to `.env.local` and add your keys
4. **Start dev server**: `npm run dev`

### **Phase 1 Tasks (Landing Page + Auth):**

1. Create landing page components:
   - Hero section
   - Features section
   - How it works
   - CTA
2. Build auth pages:
   - Login page
   - Signup page (with role selection)
   - Password reset
3. Implement auth middleware
4. Test role-based routing

---

## 🤝 **Contributing**

This is a production platform for AISRi. Code quality standards:

- TypeScript strict mode
- ESLint + Prettier
- Component testing (Jest + React Testing Library)
- E2E testing (Playwright)

---

## 📄 **License**

Proprietary - AKURA SafeStride

---

## 📞 **Support**

- **Documentation**: `/docs`
- **API Docs**: https://api.akura.in/docs
- **Supabase Dashboard**: https://app.supabase.com/project/bdisppaxbvygsspcuymb

---

**Ready to build the future of AI coaching! 🚀🏃‍♂️**
