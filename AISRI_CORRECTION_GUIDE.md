# AISRI Terminology Correction Guide

**Date**: February 10, 2026  
**Status**: Ready to Execute  
**Priority**: High (User-Facing Terminology)

---

## 📋 Quick Start

### Run Automated Correction:

```powershell
cd C:\safestride
.\Fix-AISRI-Terminology.ps1
```

This will automatically replace all instances of AISRI with AISRI throughout the codebase.

---

## 🎯 What Gets Corrected

### Terminology Changes:
- **AISRI** → **AISRI** (uppercase)
- **AISRI** → **aisri** (lowercase)
- **AISRI** → **Aisri** (title case)

### Full Term:
**AISRI** = **AI-powered Sports Running Intelligence**

---

## 📂 Files Affected

### Dart Files (~40 files):
- `lib/screens/*.dart` - All UI screens
- `lib/services/*.dart` - All services
- `lib/models/*.dart` - All data models
- `lib/widgets/*.dart` - All widgets

### Database Files (~15 files):
- `database/*.sql` - All migrations
- Table names: `AISRI_assessments` → `aisri_assessments`
- Column names: `AISRI_score` → `aisri_score`, `AISRI_zone` → `aisri_zone`

### Documentation Files (~20 files):
- All `.md` files
- Comments in code
- README files
- Testing guides

---

## 🔧 Step-by-Step Process

### Step 1: Run Automated Script ✅

```powershell
.\Fix-AISRI-Terminology.ps1
```

**What it does:**
- Searches all `.dart`, `.sql`, `.md`, `.yaml`, `.json` files
- Replaces all AISRI variations with AISRI
- Excludes build directories (.dart_tool, build, .git, etc.)
- Shows progress and statistics

**Expected Output:**
```
✓ Files modified: 50+
✓ Total replacements: 200+
```

---

### Step 2: Rename Service File 🔄

**Manual action required:**

1. In VS Code, navigate to: `lib/services/`
2. Right-click `AISRI_calculator_service.dart`
3. Select "Rename"
4. Change to: `aisri_calculator_service.dart`

**Or use PowerShell:**
```powershell
Rename-Item "lib\services\AISRI_calculator_service.dart" "aisri_calculator_service.dart"
```

---

### Step 3: Deploy Database Migration 🗄️

**File**: `database/migration_fix_aisri_terminology.sql`

**Deployment Options:**

#### Option A: Supabase Dashboard (Recommended)
1. Open https://app.supabase.com
2. Go to SQL Editor
3. Copy contents of `migration_fix_aisri_terminology.sql`
4. Paste and click "Run"
5. Verify success message

#### Option B: PowerShell Script
```powershell
cd database
.\deploy-aisri-migration.ps1
```

**What the migration does:**
- Renames table: `AISRI_assessments` → `aisri_assessments`
- Renames columns: `AISRI_score` → `aisri_score`
- Renames columns: `AISRI_zone` → `aisri_zone`
- Updates JSONB content in `structured_workouts`
- Recreates indexes with new names
- Updates table/column comments

---

### Step 4: Verify Changes ✓

#### Check Compilation:
```powershell
flutter analyze
```

**Expected**: 0 errors (or same count as before)

#### Check Imports:
```powershell
# Search for remaining "AISRI" references
Get-ChildItem -Path lib -Filter "*.dart" -Recurse | Select-String -Pattern "AISRI" -CaseSensitive
```

**Expected**: Only `aisri_calculator_service.dart` file name

#### Check Database:
Run in Supabase SQL Editor:
```sql
-- Check tables
SELECT table_name FROM information_schema.tables 
WHERE table_name LIKE '%aisri%';

-- Check columns
SELECT table_name, column_name FROM information_schema.columns 
WHERE column_name LIKE '%aisri%';
```

**Expected**: 
- Table: `aisri_assessments`
- Columns: `aisri_score`, `aisri_zone`

---

### Step 5: Test Application 📱

#### Compile and Run:
```powershell
flutter run -d RZ8MB17DJKV
```

#### Test These Screens:
- [ ] **Dashboard** - Shows "AISRI Score" (not "AISRI")
- [ ] **Assessment Results** - Says "AISRI Assessment"
- [ ] **Evaluation Form** - Title says "AISRI Evaluation"
- [ ] **Workout Creator** - Shows "AISRI Zones"
- [ ] **Structured Workouts** - Zone labels say "AISRI"
- [ ] **Kura Coach Calendar** - Workouts show "AISRI Zones"

#### Check Data:
- [ ] Existing assessments still load correctly
- [ ] AISRI scores display properly
- [ ] Zone calculations work
- [ ] Historical data intact

---

### Step 6: Commit Changes 📝

```powershell
# Stage all changes
git add .

# Commit with descriptive message
git commit -m "Fix: Correct AISRI to AISRI terminology

BREAKING CHANGE: Database schema updated

- Renamed table: AISRI_assessments → aisri_assessments
- Renamed columns: AISRI_score → aisri_score, AISRI_zone → aisri_zone
- Renamed service: AISRI_calculator_service.dart → aisri_calculator_service.dart
- Updated all UI text: AISRI → AISRI throughout app
- Updated documentation and code comments
- Deployed database migration

AISRI = AI-powered Sports Running Intelligence

Changes affect:
- 50+ code files
- 15+ database migrations
- 20+ documentation files
- UI labels in all screens
"

# Push changes
git push origin main
```

---

## 🔍 Verification Checklist

### Code Verification:
- [ ] `flutter analyze` shows no new errors
- [ ] All imports updated correctly
- [ ] Service file renamed (`aisri_calculator_service.dart`)
- [ ] No "AISRI" string in user-facing text
- [ ] All zone references say "AISRI"

### Database Verification:
- [ ] Migration deployed successfully
- [ ] Table `aisri_assessments` exists
- [ ] Columns renamed correctly
- [ ] Indexes updated
- [ ] JSONB content updated
- [ ] No query errors

### UI Verification:
- [ ] Dashboard shows "AISRI Score"
- [ ] Assessment screens say "AISRI"
- [ ] Workout zones labeled "AISRI"
- [ ] No "AISRI" visible anywhere
- [ ] Historical data displays correctly

### Documentation Verification:
- [ ] README updated
- [ ] All guides updated
- [ ] Code comments updated
- [ ] Database schema docs updated
- [ ] API documentation updated

---

## 🐛 Troubleshooting

### Issue 1: Import Errors After Service Rename

**Symptom**: 
```
Error: 'AISRI_calculator_service.dart' not found
```

**Solution**:
Search for old imports and update manually:
```powershell
Get-ChildItem -Path lib -Filter "*.dart" -Recurse | 
    Select-String -Pattern "AISRI_calculator_service" | 
    ForEach-Object { Write-Host $_.Path -ForegroundColor Yellow }
```

Update each file:
```dart
// Old
import '../services/AISRI_calculator_service.dart';

// New
import '../services/aisri_calculator_service.dart';
```

---

### Issue 2: Database Query Errors

**Symptom**:
```
ERROR: column "AISRI_score" does not exist
```

**Solution**:
1. Verify migration was deployed:
   ```sql
   SELECT column_name FROM information_schema.columns 
   WHERE table_name = 'athlete_goals';
   ```
2. If old column still exists, run migration again
3. Check for any cached queries in code

---

### Issue 3: JSONB Still Contains "AISRIZone"

**Symptom**:
Structured workouts don't load or show wrong zones

**Solution**:
Run JSONB update manually:
```sql
UPDATE structured_workouts
SET steps = replace(steps::text, 'AISRIZone', 'aisriZone')::jsonb
WHERE steps::text LIKE '%AISRIZone%';
```

---

### Issue 4: App Shows "AISRI" After Update

**Symptom**:
UI still shows old "AISRI" text

**Solution**:
1. Hard refresh the app (restart)
2. Clear app cache:
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```
3. Check if text is hardcoded or from database

---

## 📊 Impact Summary

### Statistics:
- **Files Modified**: 50+
- **Lines Changed**: 200+
- **Database Tables**: 1 renamed
- **Database Columns**: 3 renamed
- **Estimated Time**: 1-2 hours

### Breaking Changes:
- ✅ Database schema updated (migration required)
- ✅ Service file renamed (imports must update)
- ✅ API field names changed (if exposed externally)

### Non-Breaking:
- ✅ UI text changes (visual only)
- ✅ Documentation updates
- ✅ Code comments

---

## 🎯 Success Criteria

### Deployment Successful When:
1. ✅ Script reports 50+ files modified
2. ✅ `flutter analyze` passes
3. ✅ Database migration succeeds
4. ✅ App compiles and runs
5. ✅ All UI shows "AISRI" not "AISRI"
6. ✅ No console errors related to missing columns
7. ✅ Historical data loads correctly
8. ✅ Git commit pushed successfully

---

## 📞 Support

### If You Need Help:
1. Check error messages in console
2. Verify database migration status in Supabase
3. Search codebase for remaining ` AISRI` references
4. Review git diff to see what changed

### Rollback if Needed:
```sql
-- Run rollback section from migration file
BEGIN;
ALTER TABLE aisri_assessments RENAME TO AISRI_assessments;
ALTER TABLE athlete_goals RENAME COLUMN aisri_score TO AISRI_score;
-- ... (see migration file for complete rollback)
COMMIT;
```

---

## ✅ Final Steps

After successful correction:

1. **Test thoroughly** - Run through all app flows
2. **Document changes** - Update changelog
3. **Notify team** - If working with others
4. **Update .env** - If any environment variables reference AISRI
5. **Check CI/CD** - Update any build scripts if needed

---

**Correction Script**: `Fix-AISRI-Terminology.ps1`  
**Database Migration**: `migration_fix_aisri_terminology.sql`  
**Status**: Ready to Execute  
**Priority**: High

---

Generated: February 10, 2026  
SafeStride Version: 6.1 - Data Object Edition
