# SafeStride - Strava OAuth Testing Guide

## 🎯 Complete Setup for Local Testing

### Step 1: Update Strava App Callback URL

1. Open Strava API settings: https://www.strava.com/settings/api
2. Find your "SafeStride" app (Client ID: 162971)
3. Click "Edit" or update the **Authorization Callback Domain** field
4. Add: `localhost` (just the domain, no protocol or path)
5. Click "Update"

**Important**: Strava only allows the domain, not the full path. They automatically accept:

- `http://localhost/strava-callback-local.html`
- `http://localhost:8002/callback`
- etc.

### Step 2: Test the Flow

1. **API Server is Running** ✅
   - URL: http://localhost:8002
   - Status: Active

2. **Open the Test Signup Page**:

   ```powershell
   Start-Process "C:\safestride\web\signup-local.html"
   ```

3. **Click "Sign Up with Strava"**
   - Redirects to Strava OAuth
   - You authorize the app
   - Strava redirects back to: `http://localhost/strava-callback-local.html?code=...`
   - Page calls your API at `http://localhost:8002/api/strava-signup`
   - Profile created!

### Step 3: What Happens

1. **Signup Page** (`signup-local.html`)
   - Displays the SafeStride signup UI
   - "Sign Up with Strava" button redirects to Strava OAuth

2. **Strava OAuth** (on Strava's website)
   - User logs in and authorizes
   - Strava redirects back with authorization code

3. **Callback Page** (`strava-callback-local.html`)
   - Receives the authorization code
   - Calls your API: `POST http://localhost:8002/api/strava-signup`
   - API exchanges code for access token
   - API creates profile in Supabase
   - Shows success message with athlete data

### Current File Locations

- **Signup Page**: `C:\safestride\web\signup-local.html`
- **Callback Page**: `C:\safestride\web\strava-callback-local.html`
- **API Server**: Running on `http://localhost:8002`

### Testing Commands

```powershell
# Open signup page
Start-Process "C:\safestride\web\signup-local.html"

# Check API status
Invoke-WebRequest -Uri http://localhost:8002/health -UseBasicParsing | Select-Object -ExpandProperty Content

# View API docs
Start-Process "http://localhost:8002/docs"
```

### Troubleshooting

**Issue: "No authorization code received"**

- Make sure you added `localhost` to Strava app callback domains
- Check the URL after Strava redirects - should include `?code=...`

**Issue: "Failed to exchange code for token"**

- Verify `STRAVA_CLIENT_SECRET` in `.env` is correct
- Check API terminal for error messages

**Issue: "Failed to create profile"**

- Verify `SUPABASE_SERVICE_ROLE_KEY` in `.env` is correct
- Check if the profiles table has the strava columns (from migration)

### Need Migration Again?

If you skipped the database migration earlier:

```powershell
# Copy migration SQL
Get-Content supabase/migrations/20240115_strava_signup_stats.sql -Raw | Set-Clipboard

# Then paste in: https://app.supabase.com/project/xzxnnswggwqtctcgpocr/sql/new
```

---

**🚀 Ready to test? Run the command below:**
