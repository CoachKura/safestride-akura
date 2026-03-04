# 🔧 URGENT FIX: Config Loading Error

## ❌ Error You're Experiencing

```
onboarding:550 Uncaught SyntaxError: missing ) after argument list
onboarding:309 Uncaught ReferenceError: nextStep is not defined
```

## 🔍 Root Cause

The issue is that you're opening HTML files using `file://` protocol:
- **Your URL**: `file:///C:/safestride/akurain/public/onboarding`
- **Problem 1**: Missing `.html` extension
- **Problem 2**: `config.js` doesn't load properly with `file://` protocol

## ✅ IMMEDIATE SOLUTION (Choose One)

### 🥇 **Solution 1: Use Local Web Server** (RECOMMENDED)

Instead of opening files directly, run a local web server:

#### Option A: Python (if installed)
```powershell
# Open PowerShell in C:\safestride\akurain\public
cd C:\safestride\akurain\public
python -m http.server 8000
```
Then open: **http://localhost:8000/onboarding.html**

#### Option B: Node.js http-server (if installed)
```powershell
npm install -g http-server
cd C:\safestride\akurain\public
http-server -p 8000
```
Then open: **http://localhost:8000/onboarding.html**

#### Option C: VS Code Live Server
1. Install "Live Server" extension in VS Code
2. Right-click `onboarding.html`
3. Click "Open with Live Server"

---

### 🥈 **Solution 2: Use Fixed Files** (Quick Fix)

I've already fixed the files in the sandbox. Download the backup and replace:

**Download**: https://www.genspark.ai/api/files/s/qnp1eLks

**Fixed files**:
- ✅ `onboarding.html` - Inline config, no external file needed
- ✅ `signup.html` - Inline config, no external file needed

**Extract and replace** these files in your `C:\safestride\akurain\public\` folder.

---

### 🥉 **Solution 3: Manual Fix** (If you want to fix locally)

Edit each HTML file and replace:

**FIND:**
```html
<!-- Config -->
<script src="config.js"></script>
```

**REPLACE WITH:**
```html
<!-- Config -->
<script>
    // Inline config to avoid file loading issues
    const SAFESTRIDE_CONFIG = {
        supabase: {
            url: 'https://swzlxlfprtpxrttfscvf.supabase.co',
            anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN3emx4bGZwcnRweHJ0dGZzY3ZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ2MTU4NjcsImV4cCI6MjA1MDE5MTg2N30.Gq6j8Qu5yiWgzpzwqKa3zg9wZAqmY_FZeOVsPtdI5cs'
        },
        strava: {
            clientId: '139446',
            clientSecret: 'b58cec58bcc28f5ce8b05f6ee69d98b1ec2f8c55',
            redirectUri: window.location.origin + '/public/strava-callback.html',
            scope: 'read,activity:read_all,profile:read_all'
        },
        aisri: {
            weights: {
                running: 0.40,
                strength: 0.15,
                rom: 0.12,
                balance: 0.13,
                alignment: 0.10,
                mobility: 0.10
            }
        }
    };
</script>
```

**Files to fix**:
1. `onboarding.html` ✅ (Already fixed in sandbox)
2. `signup.html` ✅ (Already fixed in sandbox)
3. `strava-callback.html`
4. `strava-dashboard.html`
5. `training-plan-builder.html`

---

## 🎯 QUICK START (Recommended Path)

1. **Download fixed backup**: https://www.genspark.ai/api/files/s/qnp1eLks
2. **Extract** to `C:\safestride\akurain\`
3. **Open PowerShell** in `C:\safestride\akurain\public\`
4. **Run**: `python -m http.server 8000`
5. **Open browser**: http://localhost:8000/onboarding.html
6. **✅ It will work!**

---

## 🔥 Why `file://` Protocol Doesn't Work

When you open HTML files directly with `file://`:
- ❌ External scripts (`config.js`) may not load
- ❌ CORS restrictions prevent API calls
- ❌ Relative paths can break
- ❌ Browser security blocks many features

**Solution**: Always use a web server (even locally)!

---

## 📝 Test After Fix

After implementing any solution above:

1. **Open**: http://localhost:8000/onboarding.html
2. **Fill form**: Name, email, age, gender, weight, height, heart rates
3. **Click "Next"**: Should move to Step 2 without errors
4. **Check console**: No errors about `SAFESTRIDE_CONFIG` or `nextStep`

---

## 🆘 If Still Not Working

### Check 1: Browser Console
Press **F12** → Console tab → Look for:
- ✅ No red errors
- ✅ `SAFESTRIDE_CONFIG` is defined

### Check 2: Network Tab
Press **F12** → Network tab → Reload → Check:
- ✅ All scripts loaded (green 200 status)
- ✅ No 404 errors

### Check 3: File Path
Make sure you're accessing:
- ✅ `http://localhost:8000/onboarding.html`
- ❌ NOT `file:///C:/safestride/...`

---

## 📦 Files Already Fixed in Sandbox

The following files have been updated in the sandbox with inline config:

1. ✅ `/home/user/webapp/public/onboarding.html`
2. ✅ `/home/user/webapp/public/signup.html`

**To get them**: Download the backup link above!

---

## 🚀 Next Steps After Fix

Once working:
1. Complete onboarding flow
2. Test athlete dashboard
3. Generate sample training data
4. View training calendar
5. Deploy to GitHub Pages (no `file://` issues there!)

---

## 💡 Pro Tip

**For development**, always use one of these:
- Python: `python -m http.server 8000`
- Node.js: `npx http-server -p 8000`
- VS Code: Live Server extension
- Chrome: Web Server for Chrome extension

**Never open HTML files directly** when they use:
- External JavaScript files
- API calls (Supabase, Strava)
- Modern web features

---

## ✅ Summary

**Your Error**: Config file not loading + wrong file access method  
**Quick Fix**: Use local web server instead of `file://`  
**Download**: https://www.genspark.ai/api/files/s/qnp1eLks  
**Command**: `python -m http.server 8000`  
**Access**: http://localhost:8000/onboarding.html  

**Status**: 🎯 READY TO TEST!

---

Created: March 4, 2026  
Error: `onboarding:550` syntax error, `nextStep` undefined  
Solution: Local web server + inline config  
Files Fixed: `onboarding.html`, `signup.html`
