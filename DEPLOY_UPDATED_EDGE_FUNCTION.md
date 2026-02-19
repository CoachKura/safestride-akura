# Deploy Updated Strava Sync Edge Function

## Changes Made
✅ Fetches ALL historical Strava activities (from day 1 to present)
✅ Calculates personal bests for 12 distances
✅ Tracks total distance across all activities
✅ Enhanced athlete profile display with avatar and AISRI score
✅ Personal bests table with times, paces, and dates

## Deployment Steps

### 1. Go to Supabase Dashboard
Navigate to: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/functions

### 2. Deploy Updated Function
```bash
# Option A: Deploy via Supabase CLI (if installed)
supabase functions deploy strava-sync-activities

# Option B: Manual deployment via Dashboard
# 1. Click on "strava-sync-activities" function
# 2. Click "Deploy new version"
# 3. Copy contents from: c:\safestride-web\supabase\functions\strava-sync-activities\index.js
# 4. Paste into editor
# 5. Click "Deploy"
```

### 3. Testing the Updated Function

After deployment:

1. **Wait 2 minutes** for GitHub Pages to rebuild: www.akura.in
2. **Refresh the page** (Ctrl + Shift + R to hard refresh)
3. **Disconnect Strava** if already connected:
   - Open browser DevTools (F12) → Application tab → Storage → Clear site data
   - Or use incognito window
4. **Click "Connect Strava"** button
5. **Authorize** the connection
6. **Wait for sync** - you'll see:
   ```
   🔵 Starting Strava OAuth...
   🔵 Generated athlete ID: athlete_...
   🔵 OAuth Response: {data: {...}, error: null}
   📥 Fetching complete activity history from Strava...
   📄 Page 1: Fetched X activities (Total: X)
   📄 Page 2: Fetched X activities (Total: Y)
   ✅ Fetched Z total activities from Strava
   🏆 Personal Bests: {...}
   📊 Total Distance: XXX.XX km
   ```

7. **See your athlete profile** appear with:
   - Your Strava avatar
   - **AISRI score displayed prominently below avatar**
   - Total distance stat
   - Activities count
   - Personal bests count
   - Complete personal bests table

### Expected Results

**Athlete Profile Display:**
```
┌─────────────────────────────────────────────┐
│         [Your Avatar Image]                 │
│      🏃 Strava Connected Badge              │
│                                             │
│        ┌─────────────────┐                 │
│        │  AISRI SCORE     │                 │
│        │      85          │ ← Score below avatar
│        │  Low Risk        │                 │
│        └─────────────────┘                 │
├─────────────────────────────────────────────┤
│  👤 Name              🛣️ Total Distance     │
│  John Doe             1,234.56 km          │
│                                             │
│  👟 Activities        🏆 Personal Bests     │
│  156                  12                    │
└─────────────────────────────────────────────┘

Personal Bests Table:
┌──────────────┬──────────┬──────────┬────────────┐
│ Distance     │ Time     │ Pace     │ Date       │
├──────────────┼──────────┼──────────┼────────────┤
│ 100m         │ 0:14     │ 2:20/km  │ 2025-01-15 │
│ 200m         │ 0:30     │ 2:30/km  │ 2025-01-12 │
│ 400m         │ 1:05     │ 2:42/km  │ 2025-02-01 │
│ 800m         │ 2:25     │ 3:01/km  │ 2025-01-20 │
│ 1km          │ 3:10     │ 3:10/km  │ 2024-12-15 │
│ 1 mile       │ 5:20     │ 3:19/km  │ 2025-01-08 │
│ 5km          │ 18:45    │ 3:45/km  │ 2025-02-10 │
│ 10km         │ 40:30    │ 4:03/km  │ 2025-01-25 │
│ 15km         │ 1:05:15  │ 4:21/km  │ 2024-11-30 │
│ Half Marathon│ 1:32:45  │ 4:23/km  │ 2024-10-15 │
│ 20 Miler     │ 2:15:30  │ 4:12/km  │ 2024-09-20 │
│ Marathon     │ 3:15:45  │ 4:38/km  │ 2024-08-12 │
│ 🏆 Longest   │ 45.2 km  │ --       │ 2024-07-04 │
└──────────────┴──────────┴──────────┴────────────┘
```

### Sync Performance

**For typical athletes:**
- 50 activities: ~5 seconds
- 100 activities: ~10 seconds
- 200 activities: ~15 seconds
- 500+ activities: ~30-45 seconds

The console will show pagination progress:
```
📄 Page 1: Fetched 200 activities (Total: 200)
📄 Page 2: Fetched 200 activities (Total: 400)
📄 Page 3: Fetched 150 activities (Total: 550)
✅ Fetched 550 total activities from Strava
```

### Personal Bests Calculation

The system automatically:
- **Finds best times** for each standard distance
- Allows **tolerance** for GPS inaccuracy (e.g., 5k ± 500m)
- Calculates **pace per km** for each performance
- Shows **date achieved** for each record
- Highlights **longest run ever** with crown icon 🏆

### Troubleshooting

**If personal bests don't appear:**
- Check console logs for errors
- Verify activities have `distance` and `moving_time` data
- Ensure activities are type "Run" (not Ride, Walk, etc.)
- GPS inaccuracy may prevent exact distance matches

**If sync is slow:**
- This is normal for 500+ activities
- Watch console for pagination progress
- Each page fetches up to 200 activities
- DO NOT refresh during sync

**If AISRI score is 0:**
- Wait for sync to complete fully
- Check that activities have heart rate data
- Verify ML analysis is running in console logs

### Database Verification

After successful sync, check Supabase tables:

**strava_activities:**
- Should have rows equal to activities synced
- Each row has `ml_insights` with training load, recovery, etc.

**aisri_scores:**
- Should have 1 row for athlete
- `ml_insights` contains `personalBests` and `totalDistance`
- `pillar_scores` has Running score calculated from activities

### Next Steps After Deployment

1. ✅ Connect Strava and verify profile displays
2. ✅ Check personal bests table is populated
3. ✅ Verify AISRI score appears below avatar
4. ✅ Confirm total distance is accurate
5. Fill remaining pillar scores (Strength, ROM, Balance, Alignment, Mobility)
6. Fill athlete info (Age, Resting HR, Name if not from Strava)
7. Click "Continue to Analysis" to see complete AISRI assessment
8. Generate personalized 12-week training plan

## Summary of What Changed

### Backend (Edge Function)
- **Pagination**: Fetches all activities across multiple API calls
- **Personal Bests**: Calculates fastest times for 13 distances
- **Statistics**: Total distance, longest run, PR dates
- **Performance**: Optimized for large activity histories

### Frontend (HTML)
- **Profile Section**: Beautiful card with avatar and stats
- **AISRI Display**: Score and risk category below avatar
- **Stats Cards**: Distance, activities, personal bests counts
- **PB Table**: Sortable table with times, paces, dates
- **Responsive**: Mobile-friendly layout

### User Experience
- **Comprehensive**: See entire Strava history, not just 30 days
- **Motivating**: Personal records displayed with pride
- **Contextual**: AISRI score tied to actual performance
- **Accurate**: Real data drives training recommendations
