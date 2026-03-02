# 🔍 COMPLETE PROJECT AUDIT - WEBAPP CLEANUP PLAN

**Date**: March 2, 2026  
**Location**: `/home/user/webapp/`  
**Total Size**: 38MB  
**Status**: ⚠️ **CLUTTERED** - Contains duplicates, test files, and documentation overload

---

## 🎯 **MAIN FINDINGS**

### ✅ **PRODUCTION FILES** (Keep These)
These are the ONLY files needed for the live website at https://www.akura.in

#### **Core HTML Pages** (5 files):
```
/home/user/webapp/public/
├── strava-dashboard.html          ✅ Main athlete dashboard
├── training-plan-builder.html     ✅ Training plan generator
├── strava-callback.html           ✅ OAuth redirect handler
├── login.html                     ✅ Authentication page
└── index.html                     ✅ Homepage/redirect
```

#### **Core JavaScript** (3 files):
```
/home/user/webapp/public/
├── config.js                      ✅ Supabase configuration
├── strava-session-persistence.js  ✅ Session management (NEW - just added)
└── strava-dashboard.js            ✅ Dashboard logic
```

#### **Supabase Edge Functions** (3 files):
```
/home/user/webapp/supabase/functions/
├── strava-oauth/index.ts          ✅ OAuth token exchange
├── strava-sync-activities/index.ts✅ Activity sync
└── strava-refresh-token/index.ts  ✅ Token refresh (NEW - just added)
```

#### **Configuration** (2 files):
```
/home/user/webapp/
├── vercel.json                    ✅ Vercel deployment config
└── README.md                      ✅ Project documentation
```

**Total Production Files**: **14 files** (absolutely essential)

---

## ⚠️ **DUPLICATE/REDUNDANT FILES** (Delete or Archive)

### 🗑️ **Root Level Duplicates** (Delete These):
```bash
# These exist in /public/ AND in root - DUPLICATES!
./aisri-dashboard.html           ❌ DELETE (use public/aisri-dashboard.html)
./coach-dashboard.html           ❌ DELETE (use public/dashboard.html or remove)
./index.html                     ❌ DELETE (use public/index.html)
./login.html                     ❌ DELETE (use public/login.html)
./training-plan-builder.html     ❌ DELETE (use public/training-plan-builder.html)
```

### 🗑️ **Duplicate JavaScript** (Delete These):
```bash
# Files in /js/ that duplicate /public/
./js/ai-training-generator.js    ❌ DELETE (duplicate of public/)
./js/aifri-engine.js             ❌ DELETE (duplicate of public/)
./js/aisri-engine-v2.js          ❌ DELETE (duplicate of public/)
./js/aisri-ml-analyzer.js        ❌ DELETE (duplicate of public/)
./js/device-aifri-connector.js   ❌ DELETE (duplicate of public/)
```

### 📚 **Documentation Overload** (Archive Most):
```bash
# 24 markdown files - TOO MANY!
# Keep only: README.md
# Archive the rest to /docs/archive/

COMPLETE_PROJECT_STATUS_2026-02-18.md           📦 ARCHIVE
COMPLETE_PROJECT_STATUS_2026-02-19.md           📦 ARCHIVE
CRITICAL_FIX_GUIDE.md                           📦 ARCHIVE
DEPLOYMENT_CHECKLIST.md                         📦 ARCHIVE
DEPLOYMENT_GUIDE_2026-02-19.md                  📦 ARCHIVE
DEPLOYMENT_READY_SUMMARY.md                     ✅ KEEP (current guide)
DEPLOY_GITHUB_PAGES.md                          📦 ARCHIVE
DEPLOY_TODAY_ACTION_PLAN.md                     📦 ARCHIVE
IMPLEMENTATION_COMPLETE_SUMMARY.md              📦 ARCHIVE
INTEGRATION_SCRIPTS.md                          📦 ARCHIVE
PRODUCTION_FIXES_GUIDE.md                       📦 ARCHIVE
PROJECT_SUMMARY.md                              📦 ARCHIVE
QUICK_DEPLOYMENT_CHECKLIST.md                   📦 ARCHIVE
QUICK_START_DEPLOY.md                           📦 ARCHIVE
STRAVA_AUTOFILL_IMPLEMENTATION_SUMMARY.md       📦 ARCHIVE
STRAVA_AUTOFILL_SETUP_GUIDE.md                  📦 ARCHIVE
STRAVA_AUTOFILL_VISUAL_GUIDE.md                 📦 ARCHIVE
STRAVA_CREDENTIALS_FIX.md                       📦 ARCHIVE
STRAVA_DASHBOARD_IMPLEMENTATION.md              📦 ARCHIVE
STRAVA_DASHBOARD_INTEGRATION_GUIDE.md           📦 ARCHIVE
STRAVA_ML_AI_INTEGRATION_GUIDE.md               📦 ARCHIVE
STRAVA_SESSION_PERSISTENCE_IMPLEMENTATION.md    ✅ KEEP (current implementation)
STRAVA_SESSION_PERSISTENCE_SOLUTION.md          📦 ARCHIVE
VISUAL_PROJECT_SUMMARY.md                       📦 ARCHIVE
```

### 🧪 **Test/Development Files** (Archive These):
```bash
./public/test-autofill.html                     📦 ARCHIVE (test file)
./public/oauth-debugger.html                    📦 ARCHIVE (debug tool)
./public/thursday-workout-generator.html        📦 ARCHIVE (old feature)
./public/athlete-assessment-csv-upload.html     📦 ARCHIVE (not used)
./public/calculator.html                        📦 ARCHIVE (standalone tool)
./public/assessment.html                        📦 ARCHIVE (old version)
./public/deploy-aisri.html                      📦 ARCHIVE (deployment page)
./public/integrated-dashboard.html              📦 ARCHIVE (old dashboard)
```

### 🗂️ **Unused Subdirectories**:
```bash
./frontend/                      📦 ARCHIVE (old frontend attempt)
./js/                            ❌ DELETE (all duplicates of public/)
./public/sql/                    📦 ARCHIVE (SQL files, keep in supabase/migrations)
```

---

## 📊 **FILE COUNT SUMMARY**

| Category | Current | Should Be | Action |
|----------|---------|-----------|--------|
| **Production HTML** | 18 files | 5 files | Delete 8 duplicates, archive 5 test files |
| **Production JS** | 13 files | 3 files | Delete 5 duplicates, archive 5 unused |
| **Documentation** | 24 MD files | 3 MD files | Archive 21 old docs |
| **Edge Functions** | 3 files | 3 files | ✅ Keep all |
| **Config** | 2 files | 2 files | ✅ Keep all |
| **Total Files** | ~60 files | ~16 files | **Remove 44 files!** |

---

## 🗂️ **RECOMMENDED CLEAN STRUCTURE**

```
/home/user/webapp/
├── .git/                          ✅ Keep (version control)
├── supabase/
│   ├── functions/
│   │   ├── strava-oauth/          ✅ Keep
│   │   ├── strava-sync-activities/ ✅ Keep
│   │   └── strava-refresh-token/   ✅ Keep
│   └── migrations/                 ✅ Keep (SQL schema files)
├── public/
│   ├── index.html                  ✅ Keep
│   ├── login.html                  ✅ Keep
│   ├── strava-dashboard.html       ✅ Keep
│   ├── training-plan-builder.html  ✅ Keep
│   ├── strava-callback.html        ✅ Keep
│   ├── config.js                   ✅ Keep
│   ├── strava-session-persistence.js ✅ Keep
│   └── strava-dashboard.js         ✅ Keep
├── docs/
│   ├── archive/                    📦 Move all old .md files here
│   └── current/
│       ├── README.md               ✅ Keep
│       ├── DEPLOYMENT_READY_SUMMARY.md ✅ Keep
│       └── STRAVA_SESSION_PERSISTENCE_IMPLEMENTATION.md ✅ Keep
├── archive/
│   ├── old-html-files/             📦 Move root .html duplicates here
│   ├── test-files/                 📦 Move test/debug HTML here
│   ├── old-js/                     📦 Move /js/ folder here
│   └── old-frontend/               📦 Move /frontend/ folder here
├── vercel.json                     ✅ Keep
└── README.md                       ✅ Keep
```

---

## 🚀 **CLEANUP SCRIPT**

I'll create a safe cleanup script that:
1. ✅ Creates `/archive/` and `/docs/archive/` folders
2. ✅ Moves (not deletes) all redundant files
3. ✅ Keeps all production files untouched
4. ✅ Creates a manifest of what was moved
5. ✅ Can be reverted if needed

---

## ⚠️ **BEFORE CLEANUP - VERIFY**

### Critical Questions:
1. **Are you using coach-dashboard.html?** (I see it at root but not in public/)
2. **Are any of the test files actively used?** (oauth-debugger, test-autofill, etc.)
3. **Do you need any of the standalone tools?** (calculator.html, assessment.html)
4. **Is the /frontend/ folder part of a different project?**

---

## 🎯 **RECOMMENDED ACTION PLAN**

### Option A: **Safe Cleanup** (Recommended)
```
1. Create /archive/ and /docs/archive/ folders
2. Move all redundant files (not delete)
3. Update git (commit the cleanup)
4. Test website still works
5. If all good → delete /archive/ in 30 days
```

### Option B: **Aggressive Cleanup** (Risky)
```
1. Delete all duplicates immediately
2. Archive only test files
3. Keep minimal documentation
4. Risk: harder to recover if something breaks
```

### Option C: **Do Nothing** (Current State)
```
1. Keep current mess
2. Risk: confusion, accidental edits to wrong files
3. Harder to maintain
```

---

## 🔥 **MY RECOMMENDATION**

**Do Option A: Safe Cleanup**

### Why:
- ✅ No data loss (everything moved to /archive/)
- ✅ Easy to revert if needed
- ✅ Clean production structure
- ✅ Git tracks all changes
- ✅ Website keeps working

### Timeline:
- **Cleanup**: 5 minutes
- **Testing**: 10 minutes
- **Commit**: 2 minutes
- **Total**: ~17 minutes

---

## 🤔 **WHAT SHOULD I DO?**

Reply with:

**Option A**: "Yes, do safe cleanup (Option A)"  
→ I'll create the script and execute it

**Option B**: "Tell me more about [specific files]"  
→ I'll explain what each file does

**Option C**: "Just show me duplicates vs production files"  
→ I'll create a detailed comparison

**Option D**: "I need to check which files are actually used"  
→ I'll help you identify dependencies

---

**Current Status**: Waiting for your decision before proceeding with cleanup.

**Note**: The Strava session persistence implementation (just added) will NOT be affected by cleanup!
