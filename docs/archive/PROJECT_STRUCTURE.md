# SafeStride AI System - Project Structure

## 📁 Complete Directory Layout

```
safestride/
│
├── 📱 FLUTTER APP
│   ├── lib/                          # Flutter app source code
│   ├── assets/                       # Images, fonts, resources
│   ├── android/                      # Android build config
│   ├── pubspec.yaml                  # Flutter dependencies
│   └── analysis_options.yaml         # Dart linting rules
│
├── 🤖 AI AGENTS BACKEND
│   └── ai_agents/
│       │
│       ├── 🔴 CORE SERVER
│       │   ├── main.py               # FastAPI server with 5 AI endpoints
│       │   ├── requirements.txt      # Python dependencies
│       │   └── .env                  # Supabase credentials
│       │
│       ├── 🔄 AUTOMATION SCRIPTS
│       │   ├── daily_runner.py       # Full automation (logs, DB, errors)
│       │   ├── simple_daily_cycle.py # Minimal automation (18 lines)
│       │   └── check_status.py       # Database status viewer
│       │
│       └── 🧠 AI AGENT MODULES
│           ├── commander/            # Athlete management
│           │   └── commander.py      # List athletes, manage data
│           │
│           ├── ai_engine_agent/      # Autonomous decisions
│           │   └── ai_engine_agent.py # Training recommendations
│           │
│           ├── injury_risk_predictor/ # Injury prediction
│           │   └── injury_risk_predictor.py # Risk assessment
│           │
│           ├── workout_generator/    # Workout creation
│           │   └── workout_generator.py # Personalized workouts
│           │
│           └── race_predictor/       # Race performance
│               └── race_predictor.py # Pace/time predictions
│
└── 📚 DOCUMENTATION
    ├── START_HERE.md                 # Quick start guide
    ├── DAILY_RUNNER_SETUP.md         # Automation setup
    ├── STRAVA_INTEGRATION_STATUS.md  # Strava features
    └── [40+ other docs]              # Implementation guides
```

## 🎯 Key Components

### 1. FastAPI Server (`main.py`)
**Endpoints:**
- `POST /agent/commander` - List/manage athletes
- `POST /agent/autonomous-decision` - Get training recommendations
- `POST /agent/predict-injury-risk` - Predict injury risk
- `POST /agent/generate-workout` - Generate personalized workouts
- `POST /agent/predict-race-performance` - Predict race times

**Start server:**
```bash
cd C:\safestride\ai_agents
python main.py
```

### 2. Daily Automation

**Option 1: Full Version (daily_runner.py)**
- 329 lines
- Saves to database (3 tables)
- Timestamped logging
- Error handling
- Summary reports

**Option 2: Simple Version (simple_daily_cycle.py)**
- 18 lines
- No database saving
- No logging
- Pure API calls

**Scheduled Tasks:**
- `SafeStrideAIDaily` - Runs daily_runner.py at 4:00 AM
- `SafeStrideSimple` - Runs simple_daily_cycle.py at 4:00 AM

### 3. AI Agent Modules

Each agent is a self-contained module with:
- Business logic for its domain
- Supabase database queries
- Data processing and analysis
- Response formatting

## 🔌 Data Flow

```
Flutter App
    ↓
FastAPI Server (main.py)
    ↓
AI Agent Modules
    ↓
Supabase Database
```

## 📊 Database Tables

**Supabase PostgreSQL:**
- `profiles` - Athlete information
- `AISRI_assessments` - Injury risk scores
- `training_load_metrics` - Training data
- `workouts` - Workout history
- `ai_decisions` - Daily coaching decisions
- `injury_risk_predictions` - Injury predictions
- `race_predictions` - Race performance predictions

## ⚙️ Environment Configuration

**`.env` file contains:**
```
SUPABASE_URL=https://bdisppaxbvygsspcuymb.supabase.co
SUPABASE_SERVICE_KEY=eyJ...
SUPABASE_ANON_KEY=eyJ...
```

## 🚀 Quick Start

**1. Start FastAPI backend:**
```bash
cd C:\safestride\ai_agents
python main.py
```

**2. Run daily cycle manually:**
```bash
python daily_runner.py        # Full version
# or
python simple_daily_cycle.py  # Simple version
```

**3. Check database status:**
```bash
python check_status.py
```

**4. View scheduled tasks:**
```powershell
Get-ScheduledTask | Where-Object {$_.TaskName -like "*SafeStride*"}
```

## 📦 Dependencies

**Python packages (requirements.txt):**
- fastapi - Web framework
- uvicorn - ASGI server
- supabase - Database client
- requests - HTTP client
- python-dotenv - Environment variables
- pydantic - Data validation

**Install:**
```bash
pip install -r requirements.txt
```

## 🎨 Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    FLUTTER APP                          │
│              (Mobile UI - Athletes)                     │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓ HTTP/REST
┌─────────────────────────────────────────────────────────┐
│               FastAPI Server (main.py)                  │
│                  Port 8001 (local)                      │
├─────────────────────────────────────────────────────────┤
│        5 AI Endpoints → 5 Agent Modules                 │
├─────────────────────────────────────────────────────────┤
│  commander → ai_engine → injury_risk → workout → race   │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓ SQL Queries
┌─────────────────────────────────────────────────────────┐
│            Supabase PostgreSQL Database                 │
│         7 Tables (profiles, metrics, etc.)              │
└─────────────────────────────────────────────────────────┘

                AUTOMATION (Scheduled)
┌─────────────────────────────────────────────────────────┐
│  Windows Task Scheduler (4:00 AM Daily)                │
│       ↓                                                 │
│  daily_runner.py or simple_daily_cycle.py               │
│       ↓                                                 │
│  Calls FastAPI → Processes all athletes                 │
│       ↓                                                 │
│  Saves results to database                              │
└─────────────────────────────────────────────────────────┘
```

## 💡 Current Status

✅ **Backend:** FastAPI running with 5 AI agents  
✅ **Database:** Supabase connected with 7 tables  
✅ **Automation:** 2 scheduled tasks (4:00 AM daily)  
✅ **Testing:** All endpoints verified working  
✅ **Integration:** Strava OAuth implemented  

## 📝 Notes

- FastAPI must be running for automation scripts to work
- Database saves happen automatically with full version
- Simple version is faster but doesn't save to DB
- All 5 AI agents use the same Supabase connection
- Scheduled tasks run even if computer is asleep (starts on wake)

---

**Last Updated:** February 22, 2026
