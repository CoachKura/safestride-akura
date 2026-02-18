# Deploy Strava OAuth Callback Edge Function

This Edge Function handles Strava OAuth callbacks and redirects back to the mobile app.

## Deploy to Supabase

1. **Install Supabase CLI** (if not already installed):
   ```bash
   npm install -g supabase
   ```

2. **Login to Supabase**:
   ```bash
   supabase login
   ```

3. **Link to your project**:
   ```bash
   supabase link --project-ref yawxlwcniqfspcgefuro
   ```

4. **Deploy the function**:
   ```bash
   supabase functions deploy strava-callback
   ```

5. **Verify deployment**:
   - Go to Supabase Dashboard → Edge Functions
   - You should see `strava-callback` function listed
   - Test URL: https://yawxlwcniqfspcgefuro.supabase.co/functions/v1/strava-callback

## Update Strava API Settings

1. Go to: https://www.strava.com/settings/api
2. Find your SafeStride application
3. Update **"Authorization Callback Domain"**:
   ```
   yawxlwcniqfspcgefuro.supabase.co
   ```
4. Click **Update**

## How It Works

1. User clicks "Connect to Strava" in mobile app
2. Browser opens Strava authorization page
3. User authorizes the app
4. Strava redirects to: `https://yawxlwcniqfspcgefuro.supabase.co/functions/v1/strava-callback?code=ABC123`
5. Edge Function receives the code
6. Edge Function redirects back to app using deep link: `safestride://strava-callback?code=ABC123`
7. App receives the code via deep link and exchanges it for access token

## Testing

After deployment, test the full flow:
1. Open SafeStride mobile app
2. Go to Profile → Connect to Strava
3. Authorize on Strava's website
4. You should be redirected back to the app automatically
5. Check app logs for "Strava connection successful"
