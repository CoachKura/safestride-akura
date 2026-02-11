# Deploy Strava Callback to akura.in

## Quick Deploy via Git

### 1. Commit the updated callback file:
```powershell
git add web/strava-callback.html lib/services/strava_service.dart lib/services/strava_oauth_service.dart
git commit -m "Fix Strava OAuth callback - handle hash parameters"
git push origin main
```

### 2. Deploy to akura.in hosting:

**If using Vercel:**
- The file at `web/strava-callback.html` will automatically be available at:
  `https://akura.in/strava-callback.html`
- Vercel auto-deploys on git push to main branch

**If using Render:**
- Same as above - auto-deploys from git
- Check your Render dashboard to confirm deployment status

### 3. Verify the deployment:
Visit: https://akura.in/strava-callback.html

You should see the "Connecting to SafeStride..." page.

### 4. Test the full OAuth flow:
1. Run your Flutter app: `flutter run`
2. Go to GPS/Strava connection screen
3. Tap "Connect to Strava"
4. Authorize on Strava
5. Should redirect back to app ✓

## What Changed:

✅ **Callback now handles both formats:**
- Query parameters: `?code=xxx&scope=yyy`
- Hash parameters: `#code=xxx&scope=yyy`

✅ **Code changes:**
- `web/strava-callback.html` - Updated JavaScript to check both query and hash
- Both Strava services revert to `https://akura.in/strava-callback.html`

## Strava App Settings (Already Configured):
- ✅ Authorization Callback Domain: `akura.in`
- ✅ Client ID: 162971
- ✅ Scopes: read, activity:read_all, profile:read_all

Ready to deploy! 🚀
