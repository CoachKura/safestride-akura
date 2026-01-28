# AKURA SafeStride - Authentication Testing Checklist

## 🎯 Purpose

This checklist ensures all authentication features work correctly before launching your beta program.

---

## ✅ Pre-Testing Setup

Before running tests, ensure:

- [ ] Supabase project is configured
- [ ] Authentication system is deployed to https://www.akura.in
- [ ] You have access to a test email account
- [ ] Browser console is open (F12) to monitor for errors
- [ ] Supabase Dashboard is open to verify database entries

---

## 📝 Test Suite

### TEST 1: User Registration (Athlete)

**Objective**: Verify athlete registration flow works end-to-end

**Steps**:
1. Open https://www.akura.in/register.html
2. Fill form with:
   - Full Name: `Test Athlete`
   - Email: `test.athlete@example.com`
   - Password: `TestPass123!`
   - Confirm Password: `TestPass123!`
   - Role: `Athlete / Runner`
   - Check "I agree to Terms..."
3. Click "Create Account"

**Expected Results**:
- [ ] Form validates correctly
- [ ] Password strength indicator shows
- [ ] Success message appears: "Account created! Check your email..."
- [ ] No console errors
- [ ] Page redirects to login.html after 3 seconds
- [ ] Email sent to test.athlete@example.com

**Verify in Supabase**:
- [ ] Open Supabase Dashboard → Authentication → Users
- [ ] New user appears with email `test.athlete@example.com`
- [ ] User status shows "Unconfirmed" (yellow badge)
- [ ] User metadata contains: `role: "athlete"`, `full_name: "Test Athlete"`

---

### TEST 2: Email Verification

**Objective**: Verify email confirmation flow

**Steps**:
1. Check email inbox for verification email
2. Open email from Supabase
3. Click "Confirm Email" button

**Expected Results**:
- [ ] Email received within 1 minute
- [ ] Email has AKURA branding (if custom templates configured)
- [ ] Click redirects to: https://www.akura.in/profile-setup.html
- [ ] User is automatically logged in

**Verify in Supabase**:
- [ ] User status changes to "Confirmed" (green badge)
- [ ] `email_confirmed_at` timestamp populated
- [ ] User has an active session

---

### TEST 3: Profile Setup (Optional Fields)

**Objective**: Verify profile setup page and data saving

**Steps**:
1. On profile-setup.html, fill in:
   - Age: `30`
   - Gender: `Male`
   - Fitness Level: `Intermediate`
   - Weekly Mileage: `40`
   - Primary Goal: `Half Marathon`
   - Injuries: `None`
2. Click "Save & Continue"

**Expected Results**:
- [ ] Form accepts all inputs
- [ ] Success message appears
- [ ] Redirects to athlete-dashboard.html
- [ ] No console errors

**Verify in Supabase**:
- [ ] User metadata updated with profile data
- [ ] All fields saved correctly

---

### TEST 4: User Login (Athlete)

**Objective**: Verify login flow and session management

**Steps**:
1. Open https://www.akura.in/login.html
2. Enter credentials:
   - Email: `test.athlete@example.com`
   - Password: `TestPass123!`
3. Click "Sign In"

**Expected Results**:
- [ ] Form validates
- [ ] Success message: "Welcome back!"
- [ ] Redirects to athlete-dashboard.html
- [ ] No console errors

**Verify in Browser**:
- [ ] Open DevTools → Application → Local Storage
- [ ] Check `akura_session` exists and contains session data
- [ ] Check `akura_user_role` = "athlete"
- [ ] Check `akura_user_name` = "Test Athlete"

---

### TEST 5: Auth Guard (Protected Pages)

**Objective**: Verify auth guard protects dashboard pages

**Steps**:
1. Log out (if logged in)
2. Try to access: https://www.akura.in/athlete-dashboard.html directly
3. Should redirect to login.html

**Expected Results**:
- [ ] Cannot access athlete-dashboard.html without login
- [ ] Redirected to login.html
- [ ] URL shows: `login.html?redirect=/athlete-dashboard.html`
- [ ] After login, redirected back to athlete-dashboard.html

---

### TEST 6: User Registration (Coach)

**Objective**: Verify coach registration and role-based redirect

**Steps**:
1. Open https://www.akura.in/register.html
2. Fill form with:
   - Full Name: `Test Coach`
   - Email: `test.coach@example.com`
   - Password: `CoachPass123!`
   - Confirm Password: `CoachPass123!`
   - Role: `Coach / Trainer`
   - Check "I agree to Terms..."
3. Click "Create Account"
4. Verify email
5. Log in

**Expected Results**:
- [ ] Registration successful
- [ ] Email verified
- [ ] Login successful
- [ ] Redirects to **coach-dashboard.html** (not athlete-dashboard.html)

**Verify in Supabase**:
- [ ] User metadata contains: `role: "coach"`

---

### TEST 7: Role-Based Access Control

**Objective**: Verify coaches cannot access athlete dashboard and vice versa

**Steps**:
1. Log in as coach (`test.coach@example.com`)
2. Try to access: https://www.akura.in/athlete-dashboard.html
3. Should redirect to coach-dashboard.html
4. Log out
5. Log in as athlete (`test.athlete@example.com`)
6. Try to access: https://www.akura.in/coach-dashboard.html
7. Should redirect to athlete-dashboard.html

**Expected Results**:
- [ ] Coach cannot access athlete dashboard
- [ ] Athlete cannot access coach dashboard
- [ ] Appropriate redirects happen automatically
- [ ] No errors in console

---

### TEST 8: Password Reset Request

**Objective**: Verify password reset email flow

**Steps**:
1. Open https://www.akura.in/forgot-password.html
2. Enter email: `test.athlete@example.com`
3. Click "Send Reset Link"

**Expected Results**:
- [ ] Success message: "Password reset link sent!"
- [ ] Email received within 1 minute
- [ ] Email contains "Reset Your Password" button
- [ ] Page redirects to login.html after 3 seconds

---

### TEST 9: Password Reset Update

**Objective**: Verify password change functionality

**Steps**:
1. Check email for password reset link
2. Click "Reset Password" button in email
3. Should open: https://www.akura.in/reset-password.html
4. Enter new password:
   - New Password: `NewPass123!`
   - Confirm: `NewPass123!`
5. Click "Update Password"

**Expected Results**:
- [ ] Password strength indicator works
- [ ] Passwords must match
- [ ] Success message: "Password updated successfully!"
- [ ] Redirects to login.html
- [ ] Can log in with NEW password
- [ ] Cannot log in with OLD password

---

### TEST 10: Invalid Login Attempts

**Objective**: Verify error handling for invalid credentials

**Test 10a: Wrong Password**
1. Open login.html
2. Enter:
   - Email: `test.athlete@example.com`
   - Password: `WrongPassword123`
3. Click "Sign In"

**Expected Results**:
- [ ] Error message: "Invalid email or password"
- [ ] User not logged in
- [ ] Form remains visible

**Test 10b: Non-Existent User**
1. Enter:
   - Email: `nonexistent@example.com`
   - Password: `SomePassword123`
2. Click "Sign In"

**Expected Results**:
- [ ] Error message: "Invalid email or password"
- [ ] User not logged in

**Test 10c: Unverified Email**
1. Register new user but don't verify email
2. Try to log in

**Expected Results**:
- [ ] Error message: "Please check your email to confirm your account"
- [ ] User not logged in

---

### TEST 11: Form Validation

**Objective**: Verify client-side validation works

**Test 11a: Email Validation**
1. Open register.html
2. Enter invalid email: `notanemail`
3. Tab out of field

**Expected Results**:
- [ ] Red error message: "Please enter a valid email address"
- [ ] Input border turns red

**Test 11b: Password Strength**
1. Enter weak password: `123`
2. Check password strength indicator

**Expected Results**:
- [ ] Strength bar shows red
- [ ] Text shows "Weak"
- [ ] Error on submit: "Password must be at least 6 characters"

**Test 11c: Password Match**
1. Password: `Test123!`
2. Confirm Password: `Test456!`
3. Tab out

**Expected Results**:
- [ ] Error message: "Passwords do not match"
- [ ] Form cannot submit

**Test 11d: Required Fields**
1. Try to submit form with empty fields

**Expected Results**:
- [ ] Browser shows "Please fill out this field"
- [ ] Form does not submit

---

### TEST 12: Session Persistence

**Objective**: Verify sessions persist across page reloads and browser reopening

**Test 12a: Page Reload**
1. Log in as athlete
2. Navigate to athlete-dashboard.html
3. Reload page (F5)

**Expected Results**:
- [ ] User remains logged in
- [ ] No redirect to login
- [ ] User info still displayed

**Test 12b: Browser Reopen**
1. Log in as athlete
2. Close browser completely
3. Reopen browser
4. Navigate to athlete-dashboard.html

**Expected Results**:
- [ ] User remains logged in (if "Remember me" was checked)
- [ ] Session restored from localStorage

---

### TEST 13: Logout Functionality

**Objective**: Verify logout clears session correctly

**Steps**:
1. Log in as athlete
2. Click "Logout" button
3. Confirm logout

**Expected Results**:
- [ ] Confirmation dialog appears
- [ ] After confirmation, redirects to login.html
- [ ] Session cleared from localStorage
- [ ] Cannot access athlete-dashboard.html without logging in again

**Verify in Browser**:
- [ ] Local Storage cleared (no `akura_session`, `akura_user_role`, `akura_user_name`)

---

### TEST 14: Concurrent Sessions

**Objective**: Verify behavior with multiple browser tabs

**Steps**:
1. Log in as athlete in Tab 1
2. Open Tab 2, navigate to athlete-dashboard.html
3. Log out in Tab 1
4. Switch to Tab 2 and reload

**Expected Results**:
- [ ] Tab 2 detects session is invalid
- [ ] Tab 2 redirects to login.html
- [ ] Session monitoring works across tabs

---

### TEST 15: Mobile Responsiveness

**Objective**: Verify auth pages work on mobile devices

**Steps**:
1. Open login.html on mobile (or use DevTools mobile view)
2. Test all form interactions:
   - Input focus
   - Password toggle
   - Button clicks
   - Form submission

**Expected Results**:
- [ ] Page layout adjusts for mobile
- [ ] Forms are fully usable
- [ ] No horizontal scrolling
- [ ] Touch targets are large enough
- [ ] Virtual keyboard doesn't break layout

---

### TEST 16: Password Toggle

**Objective**: Verify show/hide password functionality

**Steps**:
1. Open login.html
2. Enter password
3. Click eye icon

**Expected Results**:
- [ ] Password toggles between hidden (•••) and visible
- [ ] Eye icon changes (👁️ ↔ 🙈)
- [ ] Works on all password fields (register, reset, etc.)

---

### TEST 17: Loading States

**Objective**: Verify loading indicators during async operations

**Steps**:
1. Open register.html
2. Fill form and submit
3. Observe button during submission

**Expected Results**:
- [ ] Button shows spinner and "Creating account..." text
- [ ] Button is disabled during loading
- [ ] Form inputs remain filled
- [ ] After completion, button returns to normal

---

## 📊 Test Results Summary

### Pass/Fail Tracking

| Test # | Test Name | Status | Notes |
|--------|-----------|--------|-------|
| 1 | Athlete Registration | ⬜ Pass / ⬜ Fail | |
| 2 | Email Verification | ⬜ Pass / ⬜ Fail | |
| 3 | Profile Setup | ⬜ Pass / ⬜ Fail | |
| 4 | Athlete Login | ⬜ Pass / ⬜ Fail | |
| 5 | Auth Guard | ⬜ Pass / ⬜ Fail | |
| 6 | Coach Registration | ⬜ Pass / ⬜ Fail | |
| 7 | Role-Based Access | ⬜ Pass / ⬜ Fail | |
| 8 | Password Reset Request | ⬜ Pass / ⬜ Fail | |
| 9 | Password Reset Update | ⬜ Pass / ⬜ Fail | |
| 10 | Invalid Login Attempts | ⬜ Pass / ⬜ Fail | |
| 11 | Form Validation | ⬜ Pass / ⬜ Fail | |
| 12 | Session Persistence | ⬜ Pass / ⬜ Fail | |
| 13 | Logout | ⬜ Pass / ⬜ Fail | |
| 14 | Concurrent Sessions | ⬜ Pass / ⬜ Fail | |
| 15 | Mobile Responsiveness | ⬜ Pass / ⬜ Fail | |
| 16 | Password Toggle | ⬜ Pass / ⬜ Fail | |
| 17 | Loading States | ⬜ Pass / ⬜ Fail | |

---

## ✅ Sign-Off

**Tested By**: ___________________  
**Date**: ___________________  
**Total Passed**: ___ / 17  
**Total Failed**: ___ / 17  

**Ready for Beta Launch**: ⬜ YES / ⬜ NO (needs fixes)

---

## 🐛 Issues Found

Document any issues discovered during testing:

| Issue # | Test # | Description | Severity | Status |
|---------|--------|-------------|----------|--------|
| 1 | | | High/Med/Low | Open/Fixed |
| 2 | | | High/Med/Low | Open/Fixed |
| 3 | | | High/Med/Low | Open/Fixed |

---

## 📋 Re-Test After Fixes

After fixing issues, re-run failed tests:

- [ ] All issues fixed
- [ ] Failed tests re-run
- [ ] All tests now passing
- [ ] System ready for beta launch

---

**🎉 Once all tests pass, your authentication system is production-ready!**
