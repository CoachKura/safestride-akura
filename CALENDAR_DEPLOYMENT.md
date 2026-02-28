# SafeStride Training Calendar - Deployment Guide

## 🚀 Deploy to Vercel (Recommended - 3 minutes)

### Prerequisites

- GitHub account
- Vercel account (free): https://vercel.com/signup

### Steps

1. **Push to GitHub**

   ```bash
   cd C:\safestride
   git add web_calendar/
   git commit -m "Add training calendar web app"
   git push origin main
   ```

2. **Deploy to Vercel**
   - Go to: https://vercel.com/new
   - Click "Import Git Repository"
   - Select: `CoachKura/safestride-akura`
   - **Root Directory**: Select `web_calendar`
   - **Framework Preset**: Vite
   - **Environment Variables**: Already configured in vercel.json
   - Click "Deploy"

3. **Done!**
   - Your calendar will be live at: `https://safestride-calendar.vercel.app`
   - Auto-deploys on every git push

### Alternative: Deploy to Netlify

1. **Push to GitHub** (same as above)

2. **Deploy to Netlify**
   - Go to: https://app.netlify.com/start
   - Select: `CoachKura/safestride-akura`
   - **Base directory**: `web_calendar`
   - **Build command**: `npm run build`
   - **Publish directory**: `web_calendar/dist`
   - Add environment variables:
     - `VITE_SUPABASE_URL`: https://bdisppaxbvygsspcuymb.supabase.co
     - `VITE_SUPABASE_ANON_KEY`: (your anon key)
   - Click "Deploy"

## 📱 Mobile Browser Compatibility

The calendar is already mobile-responsive:

- ✅ Works on iOS Safari
- ✅ Works on Android Chrome
- ✅ Works on all modern mobile browsers
- ✅ Touch-friendly drag-and-drop
- ✅ Responsive grid layout

## 🔒 Security Setup

After deployment, update Supabase CORS:

1. Go to: https://app.supabase.com/project/bdisppaxbvygsspcuymb/settings/api
2. Add your Vercel domain to "Site URL"
3. Add to "Additional Redirect URLs"

## 🎯 Production URL

Once deployed, share this link with users:

- Vercel: `https://safestride-calendar.vercel.app`
- Netlify: `https://safestride-calendar.netlify.app`
- Custom domain: Configure in Vercel/Netlify settings

## 📊 Features Live in Production

All V.O2 features are production-ready:

- ✅ Monthly calendar view
- ✅ Drag & drop workouts
- ✅ Bulk edit mode
- ✅ Clone week
- ✅ Favorites sidebar
- ✅ Week summary with charts
- ✅ Add/Edit workouts
- ✅ Strava integration
- ✅ Mobile responsive
- ✅ Authentication
