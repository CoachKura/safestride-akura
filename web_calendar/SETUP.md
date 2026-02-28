# SafeStride Web Calendar - Setup Instructions

## Quick Start (Development)

```bash
# 1. Navigate to web calendar directory
cd web_calendar

# 2. Install dependencies
npm install

# 3. Start development server
npm run dev
```

The calendar will automatically open at http://localhost:3000

## Database Connection

The calendar is pre-configured to connect to SafeStride's production Supabase:

```
URL: https://bdisppaxbvygsspcuymb.supabase.co
```

**No additional configuration needed** - it uses the same database as your Flutter app!

## Features Ready Out-of-the-Box

✅ **Monthly calendar grid** with week rows  
✅ **Drag-and-drop** workout reordering  
✅ **Strava activities** automatically displayed  
✅ **Bulk edit mode** for multi-select  
✅ **Clone week** functionality  
✅ **Add/Edit workouts** with comprehensive form  
✅ **Week summary** with mileage tracking  
✅ **Favorites sidebar** for workout templates

## Testing the Calendar

### 1. Open in Browser

After running `npm run dev`, the calendar opens at http://localhost:3000

### 2. Sign In

The calendar uses SafeStride's authentication system. Sign in with your existing account.

### 3. Add a Workout

1. Click the **+** button on any day
2. Select workout type (Easy Run, Quality Session, etc.)
3. Enter distance and duration
4. Click "Add Workout"

### 4. Drag-and-Drop

- Click and hold a workout card
- Drag to a different day
- Release to drop

### 5. Clone a Week

1. Scroll to the week summary (right side)
2. Click "📋 Clone Week"
3. Week duplicates to next 7 days

### 6. Bulk Edit

1. Click **☑️** in header to enable bulk edit mode
2. Click workouts to select multiple
3. Click "🗑️ Delete Selected" or "⭐ Save as Template"

### 7. View Strava Activities

If you've connected Strava, activities automatically appear on the calendar with:

- 🏃 Strava icon
- Distance and duration
- Orange gradient styling

## Build for Production

```bash
# Build optimized production bundle
npm run build

# Preview production build locally
npm run preview
```

Production files output to: `web_calendar/dist/`

## Deploy to Web Server

After building, deploy the `dist/` folder to:

### Option 1: Vercel (Recommended)

```bash
npm install -g vercel
vercel --prod
```

### Option 2: Netlify

```bash
npm install -g netlify-cli
netlify deploy --prod --dir=dist
```

### Option 3: Railway

```bash
# Railway automatically detects Vite and deploys
railway up
```

### Option 4: GitHub Pages

```bash
# Update vite.config.js:
base: '/safestride-calendar/',

# Build and deploy:
npm run build
npx gh-pages -d dist
```

## Integrating with Flutter App

To link from Flutter to the web calendar:

```dart
// In Flutter, add a button to open web calendar
ElevatedButton(
  onPressed: () async {
    const url = 'http://localhost:3000'; // or production URL
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  },
  child: Text('Open Training Calendar'),
)
```

## Troubleshooting

### "Module not found" errors

```bash
npm install --legacy-peer-deps
```

### Calendar won't load

1. Check browser console (F12) for errors
2. Verify Supabase is accessible (check network tab)
3. Try clearing browser cache

### Drag-and-drop not working

- Disable bulk edit mode (drag disabled during bulk editing)
- Check that `react-beautiful-dnd` is installed
- Try a different browser

### No workouts showing

1. Sign in with your SafeStride account
2. Add a test workout using the + button
3. Check Supabase database has `athlete_calendar` table

## Next Steps

1. ✅ **Test all features** in development
2. 🚀 **Deploy to production** (Vercel/Netlify)
3. 📱 **Link from Flutter app** for easy access
4. 🎨 **Customize colors** to match your brand
5. ⭐ **Add favorite workouts** for quick scheduling

## Support

For issues or questions:

- Check the README.md for detailed documentation
- Review component files in `src/components/`
- Test with browser DevTools (F12)

---

**Ready to launch!** The calendar is production-ready with all V.O2 features implemented. 🎉
