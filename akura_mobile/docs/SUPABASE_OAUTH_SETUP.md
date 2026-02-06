# 🔐 Supabase OAuth Setup for Strava Integration

## ✅ Solution: Use Supabase OAuth Provider (Eliminates redirect URI Issues)

This guide shows you how to set up Strava OAuth using **Supabase's built-in OAuth provider**, which automatically handles all redirect URI complexity.

---

## 📋 Why Supabase OAuth?

**Problems with Manual OAuth:**
- ❌ Redirect URI validation errors
- ❌ Complex deep link setup for mobile
- ❌ Different configurations for web/iOS/Android
- ❌ Manual token management

**Benefits of Supabase OAuth:**
- ✅ No redirect URI errors - Supabase handles it automatically
- ✅ Works on web, iOS, Android with same code
- ✅ Secure token storage in Supabase
- ✅ Automatic token refresh
- ✅ Simple one-line implementation: `signInWithOAuth(OAuthProvider.strava)`

---

## 🚀 Step 1: Enable Strava Provider in Supabase Dashboard

1. **Open Supabase Dashboard:**
   - Go to: https://app.supabase.com
   - Select your project: **akura-safestride**

2. **Navigate to Authentication Providers:**
   - Click on **"Authentication"** in the left sidebar
   - Click on **"Providers"**
   - Scroll down to find **"Strava"**

3. **Enable Strava Provider:**
   - Toggle the switch to **"Enabled"**
   - You'll see configuration fields appear

4. **Add Strava Credentials:**
   ```
   Client ID (OAuth): 162971
   Client Secret (OAuth): 6554eb9bb83f222a585e312c17420221313f85c1
   ```

5. **Copy the Redirect URL:**
   - Supabase will show you a redirect URL like:
     ```
     https://akura-safestride.supabase.co/auth/v1/callback
     ```
   - **Copy this URL** - you'll need it for Step 2

6. **Save the configuration:**
   - Click **"Save"** at the bottom

---

## 🔧 Step 2: Update Strava App Settings

1. **Go to Strava API Settings:**
   - Visit: https://www.strava.com/settings/api
   - Login with your Strava account

2. **Update Authorization Callback Domain:**
   - Find the field: **"Authorization Callback Domain"**
   - Remove any existing entries (like `localhost`)
   - Add the domain from your Supabase redirect URL:
     ```
     akura-safestride.supabase.co
     ```
   - **Note:** Only the domain, NOT the full URL

3. **Save the changes:**
   - Click **"Update"**

---

## 📱 Step 3: Test the OAuth Flow

1. **Start the Flutter app:**
   ```powershell
   cd "e:\Akura Safe Stride\safestride\akura_mobile"
   flutter run -d chrome
   ```

2. **Navigate to GPS Connection:**
   - Open the app in Chrome
   - Go to: **Profile** → **GPS Watch Connection**
   - Click **"Connect Strava"**

3. **What happens:**
   - A new browser tab opens
   - You'll see Strava's authorization page
   - Login if needed
   - Click **"Authorize"**
   - The tab closes automatically
   - You're back in SafeStride - **Connected!** ✅

4. **Verify the connection:**
   - Your Strava athlete profile should appear
   - Click **"Test Connection"** to verify API access
   - Click **"Sync Activities"** to fetch your real workouts

---

## 🔍 How It Works (Behind the Scenes)

### Old Manual OAuth Flow (❌ Complex):
```
1. App generates authorization URL with redirect_uri
2. User clicks → Opens browser
3. User authorizes → Strava redirects to redirect_uri
4. App catches redirect (deep link setup required)
5. App extracts code from URL
6. App exchanges code for token (manual API call)
7. App stores token in database
```

### New Supabase OAuth Flow (✅ Simple):
```
1. App calls: signInWithOAuth(OAuthProvider.strava)
2. Supabase handles EVERYTHING
3. Token appears in Supabase session
4. App stores token in gps_connections table
```

**Code comparison:**

**Before (Manual OAuth - 150+ lines):**
```dart
// Generate URL with redirect_uri
final authUrl = 'https://www.strava.com/oauth/authorize?'
    'client_id=$_clientId'
    '&redirect_uri=$_redirectUri'  // ← This causes errors!
    '&response_type=code'
    '&scope=read,activity:read_all';

// Show URL, wait for code, exchange code for token...
// (Complex error-prone process)
```

**After (Supabase OAuth - 1 line):**
```dart
// Supabase handles everything automatically
await _supabase.auth.signInWithOAuth(OAuthProvider.strava);
```

---

## 📊 How to Verify It's Working

### 1. Check Supabase Authentication Logs:
- Go to: Supabase Dashboard → **Authentication** → **Users**
- After connecting, you should see a new user entry
- Provider should show: **"strava"**

### 2. Check Database:
- Go to: Supabase Dashboard → **Table Editor** → **gps_connections**
- You should see a new row:
  ```
  platform: strava
  access_token: (long string)
  refresh_token: (long string)
  expires_at: (future timestamp)
  athlete_id: (your Strava athlete ID)
  ```

### 3. Check App UI:
- GPS Connection screen should show:
  - ✅ "Connected" status
  - Your Strava profile (name, username, photo)
  - Test/Sync/Disconnect buttons enabled

---

## 🐛 Troubleshooting

### Error: "OAuth provider is not enabled"
**Solution:**
- Go back to Supabase Dashboard → Authentication → Providers
- Make sure Strava toggle is **ON** (green)
- Verify Client ID and Secret are saved
- Wait 30 seconds and try again

### Error: "redirect_uri invalid" (Still)
**Solution:**
- Check Strava app settings: https://www.strava.com/settings/api
- Authorization Callback Domain should be: `akura-safestride.supabase.co`
- NOT `localhost` and NOT the full URL
- Save and wait 1 minute for Strava to update

### Connection works but no activities appear
**Solution:**
- Click **"Test Connection"** first
- If test succeeds, click **"Sync Activities"**
- Check status message for sync results
- Go to Supabase → **gps_activities** table to see synced data

### Browser popup blocked
**Solution:**
- Check browser console for popup blocker message
- Allow popups for localhost
- Refresh and try again

---

## 📚 Additional Configuration (Optional)

### For iOS App (Future):
1. Add URL scheme to `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>safestride</string>
       </array>
     </dict>
   </array>
   ```

2. Update `connectWithSupabase()` to use deep link:
   ```dart
   await _supabase.auth.signInWithOAuth(
     OAuthProvider.strava,
     redirectTo: 'safestride://auth/callback',  // ← Deep link for mobile
   );
   ```

### For Android App (Future):
1. Add intent filter to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <intent-filter>
     <action android:name="android.intent.action.VIEW" />
     <category android:name="android.intent.category.DEFAULT" />
     <category android:name="android.intent.category.BROWSABLE" />
     <data
       android:scheme="safestride"
       android:host="auth" />
   </intent-filter>
   ```

For now, web app works perfectly without these!

---

## ✨ What's Next?

After successful Strava connection:

1. **Sync Real Activities:**
   - Click "Sync Activities" button
   - Your recent runs will appear in the database

2. **Generate Protocols from Real GPS Data:**
   - The protocol generation will use your actual GPS data
   - Cadence, pace, distance from Strava activities
   - Much more accurate than mock data!

3. **Add Garmin & Coros (Future):**
   - Same Supabase OAuth approach
   - Even easier - just enable providers in dashboard

---

## 📞 Support

If you encounter any issues:

1. Check the error message in the app
2. Check browser console: Press F12 → Console tab
3. Check Supabase logs: Dashboard → Logs → Auth
4. Verify all steps above were completed correctly

**Common issues:**
- Forgot to enable Strava provider in Supabase ✅
- Wrong domain in Strava app settings ✅
- Popup blocker preventing OAuth flow ✅

---

## 🎉 Summary

**What we changed:**
- ❌ Removed manual OAuth with redirect_uri parameter
- ✅ Added Supabase OAuth provider integration
- ✅ One-line connection: `signInWithOAuth(OAuthProvider.strava)`

**What you need to do:**
1. Enable Strava in Supabase Dashboard (5 minutes)
2. Update Strava app settings with Supabase domain (2 minutes)
3. Test the connection (1 minute)

**Total setup time:** ~8 minutes

**Result:** ✅ No more redirect_uri errors. OAuth just works!

---

*Last updated: January 2025*
*Strava Client ID: 162971*
*Supabase Project: akura-safestride*
