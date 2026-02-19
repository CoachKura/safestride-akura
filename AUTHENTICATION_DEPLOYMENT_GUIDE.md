# AKURA SafeStride Authentication System Deployment Guide

## 📋 Overview

This guide will help you deploy the complete authentication system for AKURA SafeStride, including user roles, login, password management, and role-based dashboards.

## 🎯 What's Been Created

### Frontend Pages (All Deployed to GitHub)

✅ **login.html** - Main login page with:
- Email/password authentication
- Remember me functionality
- Password visibility toggle
- Error/success alerts
- Automatic redirection based on user role

✅ **change-password.html** - Password change page with:
- Current password verification
- New password strength indicator
- Password requirements checklist
- Real-time validation

✅ **athlete-dashboard.html** - Athlete dashboard with:
- AISRI score display
- Strava integration status
- Training plan builder integration
- Recent activities feed
- Quick actions

✅ **coach-dashboard.html** - Coach dashboard (placeholder)
✅ **admin-dashboard.html** - Admin dashboard (placeholder)

### Git Commits

- **Main Project (master)**: Commit `26f01fb` - 5 files, 1459 insertions
- **Web Project (gh-pages)**: Commit `bff457f` - 5 files, 1448 insertions

## 🚀 Deployment Steps

### Step 1: Deploy Authentication Schema to Supabase

You need to deploy the authentication schema that you shared earlier. This schema includes:

**Tables:**
- `user_roles` - Admin, Coach, Athlete roles with permissions
- `users` - User accounts with bcrypt password hashing
- `profiles` - Extended user profiles with athlete UID
- `audit_log` - Track all user actions
- `user_sessions` - Session management

**Functions:**
- `authenticate_user()` - Validates credentials and returns user info
- `change_password()` - Updates user password with validation
- `create_athlete_account()` - Creates new athlete accounts
- `get_coach_athletes()` - Lists athletes assigned to a coach

**Default Accounts:**
- Admin: `admin@akura.in` / `Admin@123`
- Coach: `coach@akura.in` / `Coach@123`

#### How to Deploy:

1. Open Supabase Dashboard: https://app.supabase.com/project/bdisppaxbvygsspcuymb
2. Navigate to: **SQL Editor**
3. Click: **New Query**
4. Copy the entire authentication schema SQL (700+ lines)
5. Paste into the SQL editor
6. Click: **Run** (or press Ctrl+Enter)
7. Verify success: Check for "Success. No rows returned"

#### Expected Output:
```
Success. No rows returned
```

#### Verification Queries:

After deployment, run these queries to verify:

```sql
-- Check if roles exist
SELECT * FROM user_roles;
-- Should return: admin, coach, athlete

-- Check if default users exist
SELECT email, full_name FROM users WHERE email LIKE '%@akura.in';
-- Should return: admin@akura.in, coach@akura.in

-- Check if functions exist
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' AND routine_name IN (
    'authenticate_user', 'change_password', 'create_athlete_account'
);
-- Should return all 3 functions
```

### Step 2: Test Authentication Flow

#### Test Login:

1. Open: https://www.akura.in/login.html
2. Try admin credentials:
   - Email: `admin@akura.in`
   - Password: `Admin@123`
3. Expected: Redirect to `/admin-dashboard.html`

4. Try coach credentials:
   - Email: `coach@akura.in`
   - Password: `Coach@123`
5. Expected: Redirect to `/coach-dashboard.html`

#### Test Password Change:

For default accounts (first login requires password change):

1. Login with default credentials
2. Should redirect to `/change-password.html`
3. Enter current password
4. Create new password (requirements will be validated)
5. Successful change redirects to appropriate dashboard

### Step 3: Integrate Strava with Authentication

**Current State:**
- Strava integration uses TEXT athlete_id (temporary)
- Authentication system uses UUID user_id
- **These are NOT integrated yet**

**Required Changes:**

You need to choose an integration approach:

#### Option 1: Unified UUID Approach (Recommended)

Modify Strava tables to use `user_id` UUID:

```sql
-- Drop existing Strava tables
DROP TABLE IF EXISTS strava_activities CASCADE;
DROP TABLE IF EXISTS strava_connections CASCADE;
DROP TABLE IF EXISTS aisri_scores CASCADE;

-- Recreate with UUID foreign keys
CREATE TABLE strava_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  strava_athlete_id BIGINT NOT NULL UNIQUE,
  access_token TEXT NOT NULL,
  refresh_token TEXT NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  athlete_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

CREATE TABLE strava_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  strava_activity_id BIGINT NOT NULL UNIQUE,
  activity_data JSONB NOT NULL,
  aisri_score NUMERIC(5,2),
  ml_insights JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Integrate with existing AISRI scores
-- (Use existing aisri_scores table with athlete_id → profiles.id)
```

#### Option 2: Bridge Table Approach

Keep Strava tables separate, create mapping:

```sql
CREATE TABLE athlete_strava_mapping (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  strava_athlete_id TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id),
  UNIQUE(strava_athlete_id)
);
```

### Step 4: Update Edge Functions for Authentication

After integrating the database schemas, update Edge Functions:

#### strava-oauth/index.js Changes:

```javascript
// Accept user_id from authenticated session
const { user_id } = await req.json();

// Verify user exists
const { data: user } = await supabase
  .from('users')
  .select('id')
  .eq('id', user_id)
  .single();

if (!user) {
  return new Response(JSON.stringify({ error: 'User not authenticated' }), {
    status: 401
  });
}

// Save connection with user_id instead of temporary athlete_id
const { data, error } = await supabase
  .from('strava_connections')
  .upsert({
    user_id: user_id,
    strava_athlete_id: stravaAthlete.id,
    // ... rest of the data
  });
```

#### strava-sync-activities/index.js Changes:

```javascript
// Accept user_id from authenticated session
const { user_id, daysBack } = await req.json();

// Get Strava tokens for this user
const { data: connection } = await supabase
  .from('strava_connections')
  .select('*')
  .eq('user_id', user_id)
  .single();

// ... rest remains the same, but use user_id instead of athlete_id
```

### Step 5: Update Frontend for Authentication

#### training-plan-builder.html Updates:

Add authentication check at the top:

```javascript
// Check if user is authenticated
const currentUser = localStorage.getItem('akura_user') || sessionStorage.getItem('akura_user');
if (!currentUser) {
  window.location.href = '/login.html';
}

const user = JSON.parse(currentUser);

// Pass user_id to Edge Functions instead of generating temporary IDs
const athleteId = user.user_id;  // Instead of `athlete_${Date.now()}`
```

## 📊 Current Status

### Completed ✅

- [x] Login page created and deployed
- [x] Password change page created and deployed
- [x] Athlete dashboard created and deployed
- [x] Coach dashboard placeholder created
- [x] Admin dashboard placeholder created
- [x] All pages committed to GitHub (master + gh-pages)
- [x] Role-based routing implemented
- [x] Session management (localStorage/sessionStorage)

### Pending ⏳

- [ ] Deploy authentication schema to Supabase
- [ ] Create Strava-Auth integration migration
- [ ] Update Edge Functions to use authenticated user_id
- [ ] Update training-plan-builder.html with auth check
- [ ] Test complete authenticated Strava flow
- [ ] Develop coach dashboard features
- [ ] Develop admin dashboard features

## 🔐 Security Considerations

1. **Password Storage**: Uses bcrypt hashing (implemented in SQL function)
2. **Session Management**: Stored in localStorage (persistent) or sessionStorage (temporary)
3. **RLS Policies**: Enabled on authentication tables
4. **Token Expiration**: Strava tokens auto-refresh before expiration
5. **Audit Logging**: All authentication events logged to `audit_log` table

## 🎨 UI Features

### Login Page:
- Responsive design with Tailwind CSS
- FontAwesome icons
- Password visibility toggle
- Remember me checkbox
- Error/success alerts with auto-hide
- Loading spinner during authentication
- Test credentials printed to console

### Change Password Page:
- Real-time password strength indicator
- Visual requirements checklist
- Progressive validation (changes icon color as requirements are met)
- Secure password entry with toggle visibility
- Automatic redirect after successful change

### Athlete Dashboard:
- Sidebar navigation with gradient background
- Stats cards for AISRI score, distance, activities, Strava status
- Quick actions for Training Plan, Strava Connection, AISRI Analysis
- Recent activities feed
- Embedded training plan builder (iframe)
- Time-based greeting (Good Morning/Afternoon/Evening)
- Responsive design (hamburger menu on mobile)

## 🐛 Troubleshooting

### Issue: "authenticate_user function does not exist"

**Solution:**
- Authentication schema not deployed
- Go to Supabase SQL Editor and run the authentication schema SQL

### Issue: "Invalid email or password"

**Solution:**
- Check if default accounts exist:
  ```sql
  SELECT * FROM users WHERE email = 'admin@akura.in';
  ```
- If not found, deploy authentication schema

### Issue: "Redirect loop after login"

**Solution:**
- Dashboard page not found (404)
- Check if dashboard HTML files are deployed to www.akura.in/web/
- Verify file names match: `admin-dashboard.html`, `coach-dashboard.html`, `athlete-dashboard.html`

### Issue: "Strava data not loading in dashboard"

**Solution:**
- Integration not complete yet (expected)
- Follow Step 3 to integrate Strava with authentication
- Update Edge Functions to use user_id instead of temporary athlete_id

## 📝 Next Steps

### Immediate (Deploy Auth):

1. Deploy authentication schema to Supabase SQL Editor
2. Test login with default credentials
3. Verify role-based routing works

### Short-term (Integrate Strava):

1. Choose integration approach (Option 1 or 2)
2. Create integration migration SQL
3. Update Edge Functions
4. Update training-plan-builder.html
5. Test authenticated Strava flow

### Long-term (Enhance):

1. Create athlete onboarding flow
2. Develop coach dashboard (view athlete data)
3. Develop admin dashboard (user management)
4. Add forgot password functionality
5. Add email verification
6. Add athlete self-registration

## 📞 Support

If you encounter issues:

1. Check browser console for JavaScript errors
2. Check Supabase logs for Edge Function errors
3. Verify database schema deployed correctly
4. Test default credentials in SQL Editor:
   ```sql
   SELECT * FROM authenticate_user('admin@akura.in', 'Admin@123', '127.0.0.1');
   ```

## 🎉 Conclusion

The authentication system frontend is complete and deployed. The next critical step is deploying the authentication schema to Supabase to enable login functionality.

After deploying the schema, you'll be able to:
- ✅ Log in with admin/coach credentials
- ✅ Change passwords
- ✅ Navigate role-based dashboards
- ✅ Prepare for Strava integration with proper user IDs

**Ready to deploy the authentication schema? Follow Step 1 above!**

---

Generated: February 19, 2026
Commits: 26f01fb (master), bff457f (gh-pages)
Files: login.html, change-password.html, athlete-dashboard.html, coach-dashboard.html, admin-dashboard.html
