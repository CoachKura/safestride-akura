# 🔧 SUPABASE AUTHENTICATION FIX GUIDE

## ❌ Problem

Your mobile app shows: **"Invalid API key, statusCode: 401"**

This is because:

1. ❌ Supabase Anon Key is truncated in `.env` file
2. ❌ Mobile redirect URLs not configured in Supabase

---

## ✅ Solution (3 Steps)

### **Step 1: Get Complete Supabase Anon Key**

1. Open Supabase Dashboard:

   ```
   https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/settings/api
   ```

2. Find the **"anon public"** key

3. Click **"Copy"** button (should be ~300 characters long)

4. Open your `.env` file:

   ```powershell
   notepad c:\safestride\.env
   ```

5. Replace the existing SUPABASE_ANON_KEY line with the complete key:

   ```env
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkaXNwcGF4YnZ5Z3NzcGN1eW1iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzU2NDY5NTQsImV4cCI6MjA1MTIyMjk1NH0.u9gU0dVkGQGNJqV9YtKPVWaYprxQ4YB4vQsj-VTh8Lo
   ```

   ☝️ **Use the COMPLETE key you copied from Supabase dashboard**

6. Save the file (Ctrl+S)

---

### **Step 2: Configure Mobile Redirect URLs in Supabase**

1. Open Authentication Configuration:

   ```
   https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/auth/url-configuration
   ```

2. **Site URL** section:
   - Current: `http://localhost:3000` ❌
   - Change to: `akura://` ✅
   - Click **"Save changes"**

3. **Redirect URLs** section:
   - Click **"Add URL"** button
   - Add these 3 URLs (one at a time):
     ```
     akura://login-callback
     akura://register-callback
     com.akura.safestride.akura_mobile://login-callback
     ```
   - Click **"Save changes"** after each

4. Your configuration should look like:

   ```
   Site URL: akura://

   Redirect URLs:
   - akura://login-callback
   - akura://register-callback
   - com.akura.safestride.akura_mobile://login-callback
   ```

---

### **Step 3: Rebuild and Test App**

1. Stop the current running app:

   ```powershell
   # In terminal, press: q (then Enter)
   ```

2. Clean and rebuild:

   ```powershell
   flutter clean
   flutter pub get
   flutter run -d RZ8MB17DJKV
   ```

3. Test sign up again:
   - Open app on phone
   - Tap "Sign Up"
   - Fill form
   - Tap "Create Account"
   - ✅ Should work without 401 error!

---

## 🎯 Verification

After fixing, you should see:

- ✅ No "Invalid API key" error
- ✅ Account creates successfully
- ✅ Redirects to evaluation form
- ✅ Can proceed with assessment

---

## 🐛 If Still Not Working

### Check 1: Verify .env Key is Complete

```powershell
# Count characters in your SUPABASE_ANON_KEY:
$content = Get-Content .env | Select-String "SUPABASE_ANON_KEY"
$key = $content.ToString().Split('=')[1]
Write-Host "Key length: $($key.Length) characters"
```

**Expected:** 200-400 characters
**If less than 200:** Key is still truncated, copy again from Supabase

### Check 2: Verify Supabase URL is Correct

```powershell
# Check URL in .env:
Get-Content .env | Select-String "SUPABASE_URL"
```

**Expected:** `SUPABASE_URL=https://bdisppaxbvygsspcuymb.supabase.co`

### Check 3: Terminal Output

When app starts, you should see:

```
I/flutter (16468): supabase.supabase_flutter: INFO: ***** Supabase init completed *****
```

If you see errors here, check the keys again.

---

## 📋 Quick Copy-Paste Commands

**Open .env file:**

```powershell
notepad c:\safestride\.env
```

**Stop running app:**

```powershell
# In Flutter terminal: q
```

**Clean + Rebuild:**

```powershell
flutter clean; flutter pub get; flutter run -d RZ8MB17DJKV
```

**Check Supabase dashboard:**

- API Settings: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/settings/api
- URL Config: https://supabase.com/dashboard/project/bdisppaxbvygsspcuymb/auth/url-configuration

---

## ✅ Success Looks Like This:

**Before (Current):**

```
AuthApiException(message: Invalid API key, statusCode: 401, code: null)
❌ Can't create account
❌ Stuck on sign up screen
```

**After (Fixed):**

```
✅ Account created successfully!
✅ "Welcome to SafeStride"
✅ Redirected to evaluation form
✅ Can complete assessment
```

---

## 🚀 Ready to Fix?

1. Open Supabase Dashboard → Copy complete anon key
2. Update `.env` file with complete key
3. Configure mobile redirect URLs in Supabase
4. Rebuild app
5. Test sign up again!

**Total time: 5 minutes** ⏱️
