# 🚀 QUICK START - SafeStride Training Calendars

## ⚡ Launch Web Calendar (1 minute)

```powershell
# Open PowerShell in safestride directory
cd web_calendar
npm install
npm run dev
```

✅ Calendar opens automatically at **http://localhost:3000**

---

## 📱 Test Mobile Calendar (2 minutes)

```powershell
# Your app is already running on device RZ8MB17DJKV
# Just tap the "Training Plan" button on the dashboard!

# OR redeploy:
cd C:\safestride
flutter run -d RZ8MB17DJKV
```

Navigate: **Dashboard → Training Plan button** (orange icon)

---

## 🎯 First Tasks

### Web Calendar (localhost:3000)

1. **Sign In** - Use your SafeStride account
2. **Add Workout** - Click **+** on any day
3. **Drag Workout** - Click and drag to new day
4. **Clone Week** - Click "📋 Clone Week" in week summary
5. **Bulk Edit** - Click **☑️** in header, select workouts
6. **View Strava** - Activities appear automatically (if connected)

### Mobile Calendar

1. **Open Calendar** - Tap "Training Plan" on dashboard
2. **Swipe Months** - Use month navigation at top
3. **Tap Date** - See workout details in bottom sheet
4. **Pull Refresh** - Pull down to sync latest data

---

## 📂 File Locations

```
web_calendar/                    ← React web calendar
├── src/
│   ├── components/              ← Calendar components
│   ├── styles/                  ← V.O2-inspired CSS
│   └── App.jsx                  ← Main app
├── package.json
└── vite.config.js

lib/screens/calendar_screen.dart ← Flutter mobile calendar
lib/main.dart                    ← Routes (calendar added!)
lib/screens/strava_home_dashboard.dart ← Training Plan button
```

---

## ✅ What's Working

**Web Calendar:**

- ✅ Monthly grid with week rows & summaries
- ✅ Drag-and-drop workout reordering
- ✅ Bulk edit (select multiple, delete, template)
- ✅ Clone week to next 7 days
- ✅ Favorites sidebar with templates
- ✅ Strava activity badges
- ✅ Add/Edit workouts with modal
- ✅ Progress charts & mileage tracking

**Mobile Calendar:**

- ✅ Monthly calendar view
- ✅ Today/Tomorrow/Yesterday cards
- ✅ Workout detail sheets
- ✅ Status indicators
- ✅ Strava GPS activities
- ✅ Pull-to-refresh

---

## 🎨 Screenshots Expected

**Web Calendar:**

- Purple gradient header with month navigation
- Weekly grid with colored workout cards
- Right sidebar showing week summary with progress circle
- Modal form for adding workouts
- Drag handles on workout cards

**Mobile Calendar:**

- TableCalendar month view
- Top cards for today/tomorrow workouts
- Bottom sheet with workout details
- Status badges (pending/completed/skipped)

---

## 🔍 Quick Tests

### Test 1: Add Workout (Web)

1. Open http://localhost:3000
2. Click + on today
3. Type: Easy Run, Distance: 5km, Duration: 30min
4. Click "Add Workout"
5. ✅ Card appears on calendar

### Test 2: Drag Workout (Web)

1. Click and hold any workout
2. Drag to tomorrow
3. Release
4. ✅ Workout moves, database updates

### Test 3: Clone Week (Web)

1. Add 3-4 workouts to this week
2. Scroll to week summary
3. Click "📋 Clone Week"
4. ✅ Next week populates with same workouts

### Test 4: Mobile Navigation

1. Open SafeStride on device
2. Tap "Training Plan" button
3. ✅ Calendar opens
4. Swipe between months
5. Tap any date
6. ✅ Bottom sheet shows details

---

## 🐛 If Something Fails

**Web won't start:**

```powershell
cd web_calendar
rm -rf node_modules
npm install --legacy-peer-deps
npm run dev
```

**Mobile calendar blank:**

```powershell
flutter clean
flutter pub get
flutter run -d RZ8MB17DJKV
```

**No workouts showing:**

- ✅ Sign in with your SafeStride account
- ✅ Check internet connection
- ✅ Verify Supabase is accessible

---

## 📚 Full Documentation

- **Web Calendar**: `web_calendar/README.md`
- **Setup Guide**: `web_calendar/SETUP.md`
- **Complete Guide**: `CALENDAR_IMPLEMENTATION_GUIDE.md`

---

## 🎉 Summary

✅ **React Web Calendar** - Full V.O2 features, drag-drop, bulk edit, clone week  
✅ **Flutter Mobile Calendar** - Native experience, today cards, pull-refresh  
✅ **Strava Integration** - Automatic GPS activity sync  
✅ **Shared Database** - Supabase real-time sync  
✅ **Production Ready** - Deploy to Vercel (web) + App Stores (mobile)

**Both calendars are functional and ready to test! 🚀**

---

_Open http://localhost:3000 and tap "Training Plan" on your phone - let's test!_ 🏃‍♂️
