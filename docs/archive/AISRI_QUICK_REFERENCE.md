# AISRI Correction - Quick Reference

**What**: Fix all "AISRI" → "AISRI"  
**Why**: Correct branding (AI-powered Sports Running Intelligence)  
**When**: Now  
**Time**: ~30 minutes

---

## 🚀 Quick Start (3 Steps)

### Step 1: Run PowerShell Script (5 minutes)

```powershell
# Open PowerShell in c:\safestride
cd c:\safestride

# Download script from sandbox (if needed)
# Then run:
.\Fix-AISRI-Terminology.ps1

# Or run dry-run first to preview:
.\Fix-AISRI-Terminology.ps1 -DryRun
```

**Expected Output**:
```
✅ Correction Complete!
Files modified: 45+
Total replacements: 200+
```

---

### Step 2: Rename Service File (1 minute)

In VS Code:
1. Navigate to `lib/services/`
2. Right-click `AISRI_calculator_service.dart`
3. Select "Rename"
4. Type: `aisri_calculator_service.dart`
5. Press Enter
6. VS Code will update all imports automatically ✅

---

### Step 3: Deploy Database Migration (5 minutes)

1. Open Supabase Dashboard: https://app.supabase.com
2. Go to SQL Editor (left sidebar)
3. Click "New Query"
4. Copy `migration_fix_aisri_terminology.sql`
5. Paste into editor
6. Click "Run" (Ctrl+Enter)
7. Wait for success message

**Expected Output**:
```
AISRI Terminology Correction Migration Complete!
✅ Tables renamed
✅ Columns renamed
✅ Indexes recreated
```

---

## ✅ Verification (2 minutes)

### Check Code
```powershell
# Search for any remaining AISRI references
cd c:\safestride
Select-String -Path "lib\**\*.dart" -Pattern "AISRI" -SimpleMatch

# Should return 0 results
```

### Check Database
Run in Supabase SQL Editor:
```sql
-- Find any remaining AISRI columns
SELECT table_name, column_name 
FROM information_schema.columns 
WHERE column_name LIKE '%AISRI%';

-- Should return 0 rows
```

### Check App
1. Run app on phone
2. Open Dashboard → Check shows "AISRI Score" ✅
3. Open Assessment → Check shows "AISRI" ✅
4. Open Structured Workouts → Check shows "AISRI Zones" ✅

---

## 🎯 What Gets Changed

### Code (45+ files)
- All `.dart` files
- All `.md` documentation
- All `.sql` migrations
- Service file renamed

### Database (5 items)
- Table: `AISRI_assessments` → `aisri_assessments`
- Column: `AISRI_score` → `aisri_score`
- Column: `AISRI_zone` → `aisri_zone`
- JSONB: `AISRIZone` → `aisriZone`
- Indexes and policies updated

### User Interface
- Dashboard: "AISRI Score" → "AISRI Score"
- Assessment: "AISRI Assessment" → "AISRI Assessment"
- Workouts: "AISRI Zones" → "AISRI Zones"
- All tooltips and help text

---

## 🐛 Troubleshooting

### Issue: Script finds 0 files
**Solution**: Check `$ProjectRoot` path is correct

### Issue: Service rename breaks imports
**Solution**: Let VS Code auto-update, or manually update:
```dart
// Change this:
import '../services/AISRI_calculator_service.dart';

// To this:
import '../services/aisri_calculator_service.dart';
```

### Issue: Database migration fails
**Solution**: Check if tables already renamed (migration is idempotent, safe to re-run)

### Issue: App shows cached "AISRI"
**Solution**: 
1. Stop app
2. Clear app data
3. Rebuild: `flutter clean && flutter run`

---

## 📊 Expected Statistics

| Metric | Count |
|--------|-------|
| Files Modified | 45-50 |
| Text Replacements | 200-250 |
| Database Tables | 1 |
| Database Columns | 3-5 |
| Service Files Renamed | 1 |
| Total Time | 30 min |

---

## 🎉 Success Criteria

- ✅ No "AISRI" in code (search returns 0 results)
- ✅ No "AISRI" columns in database
- ✅ Service file renamed successfully
- ✅ App compiles without errors
- ✅ Dashboard shows "AISRI Score"
- ✅ All tests pass

---

## 📝 Commit

After verification:

```bash
git add .
git commit -m "Fix: Correct AISRI to AISRI terminology

BREAKING CHANGE: Database columns renamed
- AISRI_score → aisri_score
- AISRI_zone → aisri_zone
- AISRI_assessments → aisri_assessments

Changes:
- Renamed service file
- Updated all UI text
- Updated all database queries
- Deployed migration

AISRI = AI-powered Sports Running Intelligence"

git push origin main
```

---

**Total Time**: ~30 minutes  
**Difficulty**: Easy  
**Impact**: High (branding consistency)  
**Risk**: Low (changes are straightforward)

**Date**: 2026-02-09  
**Ready to execute!** 🚀
