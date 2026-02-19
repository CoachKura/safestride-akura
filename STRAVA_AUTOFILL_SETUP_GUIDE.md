# Strava Auto-Fill Integration Setup Guide

## Overview

This system automatically fills in Strava-style forms with athlete data from the SafeStride platform, integrating with the existing authentication system and Strava API.

## Features

✅ **Auto-Fill System**
- Programmatically generates Strava-style pages with all fields populated
- Fetches data from SafeStride database (athletes, AISRI scores, activities)
- Real-time updates from Strava API
- Role-based access (admin/coach/athlete)

✅ **Integration Points**
- SafeStride authentication system
- Supabase database
- Strava OAuth 2.0
- ML/AI AISRI scoring engine

✅ **Components Created**
1. `strava-autofill-generator.js` - Core auto-fill engine (22KB)
2. `strava-profile.html` - Main profile page with auto-fill (36KB)
3. `strava-callback.html` - OAuth callback handler (13KB)
4. `config.js` - Configuration file (3KB)

## Installation

### 1. Configuration Setup

Edit `/public/config.js` and update:

```javascript
const SAFESTRIDE_CONFIG = {
    supabase: {
        url: 'https://YOUR_PROJECT.supabase.co',
        anonKey: 'YOUR_ANON_KEY',
        functionsUrl: 'https://YOUR_PROJECT.supabase.co/functions/v1'
    },
    
    strava: {
        clientId: 'YOUR_STRAVA_CLIENT_ID',
        clientSecret: 'YOUR_STRAVA_CLIENT_SECRET',
        redirectUri: 'https://www.akura.in/public/strava-callback.html'
    }
};
```

### 2. Strava Application Setup

1. Go to https://www.strava.com/settings/api
2. Create a new application:
   - **Application Name**: SafeStride
   - **Category**: Training
   - **Website**: https://www.akura.in
   - **Authorization Callback Domain**: www.akura.in
   - **Authorization Callback URL**: https://www.akura.in/public/strava-callback.html

3. Copy your Client ID and Client Secret

### 3. Supabase Edge Functions

Deploy the Strava OAuth and sync functions:

```bash
# Navigate to project
cd /home/user/webapp

# Deploy strava-oauth function
supabase functions deploy strava-oauth

# Deploy strava-sync-activities function
supabase functions deploy strava-sync-activities

# Set Strava secrets
supabase secrets set STRAVA_CLIENT_ID=your_client_id
supabase secrets set STRAVA_CLIENT_SECRET=your_client_secret
```

### 4. Database Setup

The following tables are required (already created):
- `athletes` - Athlete profiles
- `strava_connections` - Strava OAuth tokens
- `strava_activities` - Synced activities
- `aisri_scores` - AISRI assessment scores

### 5. Update Existing Pages

Add Strava profile link to navigation in:
- `dashboard.html`
- `coach-dashboard.html`
- `training-plan-builder.html`

```html
<a href="/public/strava-profile.html" class="nav-link">
    <i class="fab fa-strava"></i> Strava Profile
</a>
```

## Usage

### For Athletes

1. **Login** to SafeStride portal
2. **Navigate** to Strava Profile page
3. **Click** "Connect with Strava"
4. **Authorize** SafeStride on Strava
5. **Sync** activities automatically
6. **View** auto-filled profile with:
   - AISRI scores (6 pillars)
   - Activity statistics
   - Recent activities
   - Personal bests
   - Training zones

### For Coaches

1. **Login** as coach
2. **View** all athletes' Strava connections
3. **Monitor** AISRI scores and risk levels
4. **Track** activity compliance
5. **Generate** training plans based on Strava data

### For Admins

1. **Login** as admin
2. **Manage** Strava integration settings
3. **View** system-wide statistics
4. **Monitor** API usage
5. **Configure** AISRI weights and thresholds

## Architecture

### Data Flow

```
Athlete Login
    ↓
Strava Profile Page
    ↓
Auto-Fill Generator
    ↓
├─→ Fetch Athlete Data (Supabase)
├─→ Fetch Strava Connection (Supabase)
├─→ Fetch AISRI Scores (Supabase)
├─→ Fetch Recent Activities (Supabase)
    ↓
Compute Derived Fields
    ↓
Render Page with All Data Filled
```

### OAuth Flow

```
Click "Connect Strava"
    ↓
Redirect to Strava Authorization
    ↓
User Approves
    ↓
Callback to strava-callback.html
    ↓
Exchange Code for Tokens (Edge Function)
    ↓
Store Connection in Database
    ↓
Sync Activities (Edge Function)
    ↓
Calculate AISRI Scores
    ↓
Redirect to Profile (Auto-Filled)
```

### Auto-Fill Process

```javascript
// 1. Initialize Generator
const generator = new StravaAutoFillGenerator();

// 2. Get Athlete Data
const athleteData = { uid: currentSession.uid };

// 3. Generate Auto-Filled Page
const filledHtml = await generator.generatePage(athleteData, {
    pageType: 'profile',
    role: currentSession.role,
    autoFill: true
});

// 4. Render
document.body.innerHTML = filledHtml;
```

## API Reference

### StravaAutoFillGenerator Class

```javascript
// Constructor
const generator = new StravaAutoFillGenerator();

// Generate Page
const html = await generator.generatePage(athleteData, options);
// athleteData: { uid: string }
// options: { pageType: 'profile'|'activities'|'training'|'settings', role: string, autoFill: boolean }

// Get Athlete Info
const athlete = await generator.getAthleteInfo(uid);

// Get Strava Data
const strava = await generator.getStravaData(uid);

// Get AISRI Scores
const aisri = await generator.getAISRIScores(uid);

// Compute Fields
const computed = generator.computeFields(data);
```

### Strava API Endpoints

```javascript
// Connect Strava
POST /functions/v1/strava-oauth
Body: { code: string, athlete_id: string }
Returns: { athlete_id, strava_athlete_id, access_token }

// Sync Activities
POST /functions/v1/strava-sync-activities
Body: { athlete_id: string, full_sync?: boolean }
Returns: { activities_synced, scores_calculated }

// Disconnect Strava
DELETE /rest/v1/strava_connections?athlete_id=eq.{uid}
```

## Customization

### Add New Fields

1. Edit template in `getProfileTemplate()`:
```javascript
<div>{{custom.field}}</div>
```

2. Fetch data in `autoFillFields()`:
```javascript
filled.custom = await this.getCustomData(athleteData.uid);
```

3. Render in `renderPage()`:
```javascript
html = html.replace(/\{\{custom\.field\}\}/g, data.custom?.field || '');
```

### Add New Page Type

1. Create template method:
```javascript
getMyPageTemplate() {
    return `<!-- Your HTML template -->`;
}
```

2. Register in `getPageTemplate()`:
```javascript
const templates = {
    profile: this.getProfileTemplate(),
    mypage: this.getMyPageTemplate()
};
```

3. Use:
```javascript
const html = await generator.generatePage(data, { pageType: 'mypage' });
```

## Troubleshooting

### Strava Connection Fails

**Problem**: "Failed to exchange authorization code"

**Solutions**:
1. Check Strava client ID and secret in config
2. Verify redirect URI matches Strava app settings
3. Check edge function is deployed
4. View edge function logs: `supabase functions logs strava-oauth`

### Auto-Fill Not Working

**Problem**: Fields show "Loading..." or "--"

**Solutions**:
1. Check browser console for errors
2. Verify session token is valid
3. Check Supabase database connection
4. Ensure athlete exists in database
5. Check RLS policies allow access

### AISRI Scores Not Calculating

**Problem**: AISRI shows "--" or "No data"

**Solutions**:
1. Verify athlete has Strava activities synced
2. Check `strava_activities` table for data
3. Run sync manually: click "Sync Activities"
4. Check edge function logs
5. Verify ML analyzer is working

### OAuth Redirect Issues

**Problem**: Callback URL not working

**Solutions**:
1. Check redirect URI matches exactly
2. Verify HTTPS is used
3. Check Strava app callback domain
4. Test with correct URL format
5. Check for query parameter issues

## Testing

### Test Auto-Fill Locally

```javascript
// Open browser console on strava-profile.html

// 1. Check generator loaded
console.log(typeof StravaAutoFillGenerator);
// Should output: "function"

// 2. Test data fetch
const generator = new StravaAutoFillGenerator();
const athlete = await generator.getAthleteInfo('ATH0001');
console.log(athlete);

// 3. Test auto-fill
const filled = await generator.autoFillFields({ uid: 'ATH0001' }, 'profile');
console.log(filled);
```

### Test OAuth Flow

1. **Login** as athlete
2. **Navigate** to strava-profile.html
3. **Click** "Connect with Strava"
4. **Authorize** on Strava
5. **Verify** callback loads correctly
6. **Check** connection status updates
7. **Test** sync button works

### Test Role-Based Access

```javascript
// Test as different roles
const roles = ['admin', 'coach', 'athlete'];

for (const role of roles) {
    const session = { uid: 'ATH0001', role: role };
    sessionStorage.setItem('safestride_session', JSON.stringify(session));
    location.reload();
    // Verify role badge and permissions
}
```

## Performance

### Optimization Tips

1. **Cache athlete data** for 5 minutes
2. **Lazy load activities** (load on scroll)
3. **Debounce API calls** (300ms delay)
4. **Use indexed queries** in Supabase
5. **Compress responses** from edge functions

### Expected Performance

- Page load: < 2 seconds
- Auto-fill: < 1 second
- Strava sync: 2-5 seconds per 100 activities
- AISRI calculation: 1-2 seconds per activity

## Security

### Best Practices

✅ **Never expose** Strava client secret in frontend
✅ **Always use** edge functions for OAuth
✅ **Validate** session tokens on every request
✅ **Implement** RLS policies in Supabase
✅ **Sanitize** all user input
✅ **Use HTTPS** for all connections
✅ **Rotate** access tokens before expiry
✅ **Log** all OAuth attempts

## Deployment Checklist

- [ ] Update `config.js` with production values
- [ ] Deploy Supabase edge functions
- [ ] Set Strava client credentials as secrets
- [ ] Configure Strava app with production callback URL
- [ ] Test OAuth flow end-to-end
- [ ] Verify auto-fill works for all roles
- [ ] Check AISRI scores calculate correctly
- [ ] Test activity sync for multiple athletes
- [ ] Monitor edge function logs
- [ ] Set up error alerting

## Support

For issues or questions:
- Check browser console for errors
- View Supabase edge function logs
- Check Strava API status
- Review troubleshooting section
- Contact SafeStride support

## Next Steps

1. ✅ Created auto-fill generator system
2. ✅ Built Strava profile page with auto-fill
3. ✅ Implemented OAuth callback handler
4. ✅ Added configuration system
5. ⏳ Deploy to production
6. ⏳ Test with real athletes
7. ⏳ Monitor performance and errors
8. ⏳ Gather user feedback
9. ⏳ Iterate and improve

## Related Documentation

- [STRAVA_PROFILE_FEATURE.md](STRAVA_PROFILE_FEATURE.md) - Feature documentation
- [CONFIGURATION_GUIDE.md](CONFIGURATION_GUIDE.md) - Configuration system guide
- [Strava API Documentation](https://developers.strava.com/docs/reference/)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-19  
**Author**: SafeStride Development Team
