# AKURA SafeStride - Authentication System Deployment Guide

## 🚀 Quick Start (15 Minutes)

This guide will help you deploy the complete authentication system to your AKURA SafeStride project.

---

## 📋 Prerequisites

Before starting, make sure you have:

- ✅ **Supabase project** created and configured
- ✅ **VS Code** installed on your computer
- ✅ **Git** installed and configured
- ✅ **Project path**: `E:\Akura Safe Stride\safestride`
- ✅ **Supabase credentials** ready (URL and Anon Key)

---

## 🔧 STEP 1: Configure Supabase Credentials (2 minutes)

### 1.1 Get Your Supabase Credentials

1. Go to: https://supabase.com/dashboard
2. Select your AKURA project
3. Go to: **Settings** → **API**
4. Copy these values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon/public key**: `eyJhbGc...` (long string)

### 1.2 Update js/auth.js

Open `E:\Akura Safe Stride\safestride\frontend\js\auth.js` in VS Code.

Find lines 13-14:
```javascript
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

Replace with your actual values:
```javascript
const SUPABASE_URL = 'https://YOUR-PROJECT-ID.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'; // Your actual key
```

**Save the file** (Ctrl+S).

---

## 📦 STEP 2: Verify File Structure (1 minute)

Make sure all files are in the correct locations:

```
E:\Akura Safe Stride\safestride\frontend\
├── login.html
├── register.html
├── forgot-password.html
├── reset-password.html
├── profile-setup.html
├── css/
│   └── auth.css
└── js/
    ├── auth.js
    └── auth-guard.js
```

---

## 🔨 STEP 3: Deploy to GitHub (5 minutes)

### 3.1 Open Terminal in VS Code

1. Open VS Code
2. Open folder: `E:\Akura Safe Stride\safestride`
3. Open Terminal: **Terminal** → **New Terminal** (or Ctrl+`)

### 3.2 Stage All Authentication Files

Run these commands one by one:

```bash
# Navigate to project directory (if not already there)
cd "E:\Akura Safe Stride\safestride"

# Add HTML files
git add frontend/login.html
git add frontend/register.html
git add frontend/forgot-password.html
git add frontend/reset-password.html
git add frontend/profile-setup.html

# Add CSS
git add frontend/css/auth.css

# Add JavaScript
git add frontend/js/auth.js
git add frontend/js/auth-guard.js
```

### 3.3 Commit Changes

```bash
git commit -m "feat: add complete authentication system with Supabase

- Add login, register, forgot/reset password, and profile setup pages
- Add authentication CSS with AKURA branding
- Add Supabase authentication integration
- Add auth guard for protected pages
- Add session management and auto-refresh
- Add role-based access control (athlete/coach)"
```

### 3.4 Push to GitHub

```bash
git push origin main
```

**Wait 1-2 minutes for the push to complete.**

---

## 🌐 STEP 4: Vercel Auto-Deploy (2-3 minutes)

### 4.1 Monitor Deployment

1. Go to: https://vercel.com/dashboard
2. Select your **akura-safestride** project
3. You should see a new deployment starting automatically
4. Wait for the deployment to complete (~30-60 seconds)
5. Look for: **"Deployment Ready"** ✅

### 4.2 Verify Deployment

Once deployed, your auth system will be live at:
- Login: https://www.akura.in/login.html
- Register: https://www.akura.in/register.html
- Forgot Password: https://www.akura.in/forgot-password.html

---

## ✅ STEP 5: Test Authentication Flow (5 minutes)

### Test 1: Registration Flow

1. Open: https://www.akura.in/register.html
2. Fill in the form:
   - Full Name: **Test User**
   - Email: **YOUR_EMAIL@gmail.com** (use a real email you can access)
   - Password: **Test123!**
   - Confirm Password: **Test123!**
   - Role: **Athlete**
   - Check "I agree to Terms..."
3. Click **"Create Account"**
4. Expected result:
   - ✅ Success message: "Account created! Check your email..."
   - ✅ You receive an email from Supabase
   - ✅ Page redirects to login.html after 3 seconds

### Test 2: Email Verification

1. Check your email inbox
2. Look for email from Supabase (check spam folder if needed)
3. Click **"Confirm Email"** button in email
4. Expected result:
   - ✅ Redirects to profile-setup.html
   - ✅ You are now logged in

### Test 3: Profile Setup

1. On profile-setup.html page
2. Fill optional fields (or skip)
3. Click **"Save & Continue"** or **"Skip for Now"**
4. Expected result:
   - ✅ Redirects to athlete-dashboard.html

### Test 4: Login Flow

1. Open: https://www.akura.in/login.html
2. Enter your registered email and password
3. Click **"Sign In"**
4. Expected result:
   - ✅ Success message
   - ✅ Redirects to athlete-dashboard.html

### Test 5: Password Reset Flow

1. Open: https://www.akura.in/forgot-password.html
2. Enter your email
3. Click **"Send Reset Link"**
4. Check email for reset link
5. Click reset link
6. Should open: https://www.akura.in/reset-password.html
7. Enter new password
8. Click **"Update Password"**
9. Expected result:
   - ✅ Password updated
   - ✅ Redirects to login.html
   - ✅ Can log in with new password

---

## 🛡️ STEP 6: Protect Your Dashboard Pages (3 minutes)

To protect pages that require authentication (e.g., athlete-dashboard.html, coach-dashboard.html):

### 6.1 Add Auth Guard to Protected Pages

Open any page that requires authentication (e.g., `athlete-dashboard.html`) and add these two script tags **before the closing `</body>` tag**:

```html
<!-- Add these at the end, before </body> -->
<script src="js/auth.js"></script>
<script src="js/auth-guard.js"></script>
</body>
```

### 6.2 Add Logout Button

Add this logout button to your dashboard navigation:

```html
<button onclick="handleLogout()" class="logout-btn">
    Logout
</button>
```

### 6.3 Display User Info

Add this to show logged-in user's name:

```html
<div class="user-info">
    <span data-user-name>Loading...</span>
    <span class="user-role" data-user-role></span>
</div>

<script>
    // Call this when page loads
    document.addEventListener('DOMContentLoaded', () => {
        displayUserInfo();
    });
</script>
```

---

## 🔍 Troubleshooting

### Issue 1: "Authentication system is initializing"

**Cause**: Supabase credentials not configured or incorrect.

**Fix**:
1. Check `js/auth.js` lines 13-14
2. Verify SUPABASE_URL and SUPABASE_ANON_KEY are correct
3. Make sure there are no extra quotes or spaces
4. Re-deploy after fixing

### Issue 2: "Invalid login credentials"

**Cause**: User not registered or email not verified.

**Fix**:
1. Register a new account
2. Check email and click verify link
3. Try logging in again

### Issue 3: "Email not confirmed"

**Cause**: User didn't verify email after registration.

**Fix**:
1. Check email inbox (and spam folder)
2. Click "Confirm Email" button
3. Try logging in again

### Issue 4: Not receiving verification emails

**Cause**: Supabase email settings or email provider issue.

**Fix**:
1. Go to Supabase Dashboard → Authentication → Email Templates
2. Click "Send test email" to verify email is working
3. Check your email spam folder
4. Try with a different email address

### Issue 5: Redirects not working

**Cause**: Redirect URLs not configured in Supabase.

**Fix**:
1. Go to: Supabase Dashboard → Authentication → URL Configuration
2. Add these redirect URLs:
   ```
   https://www.akura.in/**
   https://www.akura.in/login.html
   https://www.akura.in/profile-setup.html
   https://www.akura.in/athlete-dashboard.html
   https://www.akura.in/coach-dashboard.html
   ```
3. Click "Save"
4. Try again

---

## 📊 Deployment Checklist

Use this checklist to track your progress:

- [ ] **Supabase Configuration**
  - [ ] Email provider enabled
  - [ ] Email templates customized
  - [ ] Redirect URLs added
  - [ ] Site URL set to https://www.akura.in

- [ ] **Code Configuration**
  - [ ] SUPABASE_URL updated in js/auth.js
  - [ ] SUPABASE_ANON_KEY updated in js/auth.js
  - [ ] Files in correct directory structure

- [ ] **Git Deployment**
  - [ ] All files staged (git add)
  - [ ] Changes committed (git commit)
  - [ ] Pushed to GitHub (git push)

- [ ] **Vercel Deployment**
  - [ ] Deployment triggered automatically
  - [ ] Deployment completed successfully
  - [ ] Auth pages accessible online

- [ ] **Testing**
  - [ ] Registration works
  - [ ] Email verification works
  - [ ] Login works
  - [ ] Password reset works
  - [ ] Profile setup works
  - [ ] Auth guard protects pages
  - [ ] Logout works

---

## 🎉 Success!

If all tests pass, your authentication system is now:

✅ **Fully deployed** at https://www.akura.in  
✅ **Connected to Supabase** for user management  
✅ **Email verification** working  
✅ **Password reset** functional  
✅ **Role-based access** (athlete/coach) implemented  
✅ **Session management** with auto-refresh  
✅ **Protected pages** with auth guard  

---

## 🚀 Next Steps

1. **Protect all dashboard pages** with auth guard
2. **Customize email templates** in Supabase (optional)
3. **Add user profile pages** with additional settings
4. **Implement role-specific features** for athletes and coaches
5. **Set up user analytics** in Vercel
6. **Launch beta testing** with real users

---

## 📞 Need Help?

If you encounter issues:

1. Check the browser console for error messages (F12)
2. Verify Supabase credentials are correct
3. Check Supabase Dashboard → Logs for API errors
4. Review this deployment guide step-by-step
5. Ensure all files are committed and pushed to GitHub

---

## 📚 Additional Resources

- **Supabase Auth Docs**: https://supabase.com/docs/guides/auth
- **Vercel Deployment**: https://vercel.com/docs
- **Git Basics**: https://git-scm.com/docs

---

**🎯 You're ready to launch your beta with a complete authentication system!**
