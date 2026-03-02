# ✅ STRAVA SESSION PERSISTENCE - IMPLEMENTATION CHECKLIST

**Status**: Ready to implement
**Files Ready**: 3 files created/modified
**Time to Deploy**: ~10 minutes

---

## 📦 **WHAT WAS CREATED**

✅ **supabase/functions/strava-refresh-token/index.js** - Edge Function for token refresh
✅ **docs/STRAVA_SESSION_PERSISTENCE_TESTING.md** - Complete testing guide
📝 **Code snippets** - Ready to paste into training-plan-builder.html

---

## 🚀 **IMPLEMENTATION STEPS**

### **Step 1: Update training-plan-builder.html** ⏱️ 5 min

📍 **Location**: C:\safestride\web\training-plan-builder.html

1. Find line ~775 (existing checkStravaConnection function)
2. **REPLACE** with the new functions provided above:
   - checkExistingStravaConnection()
   - updateStravaConnectionUI()
   - loadStravaActivities()
   - loadAISRIScores()
   - calculateStravaStats()
   - refreshStravaToken()

3. Find line ~970 (window.addEventListener("load"))
4. **REPLACE** with the updated version (calls checkExistingStravaConnection first)

💡 **Key Change**: Query strava_connections table instead of profiles table

---

### **Step 2: Deploy Edge Function** ⏱️ 3 min

📍 **Dashboard**: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/functions

1. Click "**Deploy new function**"
2. Name: strava-refresh-token
3. Upload: C:\safestride\supabase\functions\strava-refresh-token\index.js
4. Click **Deploy**
5. Verify function appears in list with green dot

---

### **Step 3: Test Implementation** ⏱️ 2 min

📍 **Test URL**: https://www.akura.in/training-plan-builder.html

1. Open in YOUR browser (already connected with 908 activities)
2. Open DevTools Console (F12)
3. Look for: "✅ Found existing Strava connection"
4. Button should be **GREEN** "Strava Connected"
5. Activities should auto-load (NO clicking needed)

**Screenshot these**:
- Console output
- Green button
- Activity count

---

## ✅ **VERIFICATION CHECKLIST**

Before testing:
- [ ] training-plan-builder.html updated with new functions
- [ ] strava-refresh-token deployed to Supabase
- [ ] Browser DevTools open to Console tab

After testing (Test 2):
- [ ] Button is GREEN on page load (not orange)
- [ ] Console shows "Found existing Strava connection"
- [ ] Activities auto-load (908 activities)
- [ ] Clicking green button SYNCS (doesn't open OAuth)

After testing (Test 5 - logout/login):
- [ ] Logout from SafeStride
- [ ] Close browser completely
- [ ] Login again
- [ ] Button STILL green, activities STILL load automatically

---

## 🎯 **EXPECTED RESULTS**

### **BEFORE (Current Bug)**
```
User logs in → Training Plan Builder → 🟠 "Connect Strava" → Click → OAuth → Data loads
User logs out → Login again → 🟠 "Connect Strava" → MUST RECONNECT ❌
```

### **AFTER (Fixed)**
```
User logs in → Training Plan Builder → 🟢 "Strava Connected" → Data auto-loads ✅
User logs out → Login again → 🟢 "Strava Connected" → Data auto-loads ✅
```

---

## 📊 **FILE LOCATIONS**

| File | Path | Status |
|------|------|--------|
| **HTML** | web/training-plan-builder.html | ⏳ To be updated |
| **Edge Function** | supabase/functions/strava-refresh-token/index.js | ✅ Created |
| **Testing Guide** | docs/STRAVA_SESSION_PERSISTENCE_TESTING.md | ✅ Created |

---

## 🚨 **ROLLBACK PLAN** (if something breaks)

If testing fails:
1. Git stash changes: git stash
2. Reload page - should revert to old behavior
3. Debug using console logs
4. Check strava_connections table exists:
   ```sql
   SELECT * FROM strava_connections LIMIT 1;
   ```

---

## 📞 **READY TO IMPLEMENT?**

Reply "**GO**" and I'll walk you through each step with screenshots! 🚀

