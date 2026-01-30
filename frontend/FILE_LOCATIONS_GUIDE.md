# 📂 AKURA SafeStride - Exact File Locations Guide

## 🎯 WHERE TO PLACE EACH FILE

---

## ✅ FILES CREATED - COPY TO THESE EXACT LOCATIONS

### **1. HTML Files** (Place in frontend/ folder)

```
E:\Akura Safe Stride\safestride\frontend\index.html
                                        ├── login.html
                                        └── register.html
```

**What each file does:**
- `index.html` - Homepage (public, no auth required)
- `login.html` - Login page (public)
- `register.html` - Registration page (public)

---

### **2. CSS Files** (Place in frontend/css/ folder)

```
E:\Akura Safe Stride\safestride\frontend\css\homepage.css
                                              └── auth.css
```

**What each file does:**
- `homepage.css` - Styling for index.html
- `auth.css` - Styling for login.html and register.html

---

### **3. JavaScript Files** (Place in frontend/js/ folder)

```
E:\Akura Safe Stride\safestride\frontend\js\homepage.js
                                            ├── auth.js
                                            └── auth-guard.js
```

**What each file does:**
- `homepage.js` - Interactive features for homepage (smooth scrolling, animations, mobile menu)
- `auth.js` - Supabase authentication engine (register, login, logout, session management, redirect logic)
- `auth-guard.js` - Route protection (blocks unauthorized access, enforces access levels)

---

### **4. Documentation Files** (Place in frontend/ folder)

```
E:\Akura Safe Stride\safestride\frontend\IMPLEMENTATION_GUIDE.md
                                        └── COMPLETE_SUMMARY.md
```

**What each file does:**
- `IMPLEMENTATION_GUIDE.md` - Step-by-step implementation guide
- `COMPLETE_SUMMARY.md` - Complete project overview and summary

---

## 🔧 FILES TO UPDATE (Already exist in your project)

### **Dashboard Files** (Add auth protection)

Add these two lines **before `</body>`** in each file:

```html
<script src="js/auth.js"></script>
<script src="js/auth-guard.js"></script>
</body>
```

**Files to update:**
```
E:\Akura Safe Stride\safestride\frontend\athlete-dashboard.html
                                        ├── coach-dashboard.html
                                        ├── training-plans.html
                                        ├── workout-tracking.html
                                        └── progress-charts.html
```

---

## ⚙️ CONFIGURATION REQUIRED

### **Update Supabase Credentials**

**File to edit:** `E:\Akura Safe Stride\safestride\frontend\js\auth.js`

**Lines 7-8:**
```javascript
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

**Change to:**
```javascript
const SUPABASE_URL = 'https://your-project-id.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...your-actual-key';
```

**Where to get these values:**
1. Visit: https://supabase.com/dashboard
2. Select your AKURA SafeStride project
3. Go to: Settings → API
4. Copy:
   - **Project URL** → SUPABASE_URL
   - **anon public** key → SUPABASE_ANON_KEY

---

## 📊 COMPLETE FILE TREE (After Adding New Files)

```
E:\Akura Safe Stride\safestride\
│
├── backend/
│   └── (existing backend files)
│
├── database/
│   └── (existing database files)
│
└── frontend/
    │
    ├── index.html ⭐ NEW (Homepage)
    ├── login.html ⭐ NEW (Login page)
    ├── register.html ⭐ NEW (Registration page)
    │
    ├── forgot-password.html ⏳ (To be created later)
    ├── reset-password.html ⏳ (To be created later)
    ├── aifri-assessment.html ⏳ (To be created later)
    ├── demo-dashboard.html ⏳ (To be created later)
    │
    ├── athlete-dashboard.html ✏️ (Add auth protection)
    ├── coach-dashboard.html ✏️ (Add auth protection)
    ├── training-plans.html ✏️ (Add auth protection)
    ├── workout-tracking.html ✏️ (Add auth protection)
    ├── progress-charts.html ✏️ (Add auth protection)
    │
    ├── aifri-calculator.html (existing)
    ├── assessment-intake.html (existing)
    ├── case-study.html (existing)
    ├── ... (other existing HTML files)
    │
    ├── css/
    │   ├── homepage.css ⭐ NEW
    │   ├── auth.css ⭐ NEW
    │   ├── cards.css (existing)
    │   ├── charts.css (existing)
    │   ├── forms.css (existing)
    │   ├── responsive.css (existing)
    │   ├── tables.css (existing)
    │   └── ... (other existing CSS files)
    │
    ├── js/
    │   ├── homepage.js ⭐ NEW
    │   ├── auth.js ⭐ NEW (⚠️ Update Supabase credentials!)
    │   ├── auth-guard.js ⭐ NEW
    │   ├── aifri-engine.js (existing)
    │   ├── api-client.js (existing)
    │   ├── calculator.js (existing)
    │   ├── chart-utils.js (existing)
    │   ├── charts.js (existing)
    │   ├── form-validator.js (existing)
    │   ├── main.js (existing)
    │   └── ... (other existing JS files)
    │
    ├── images/
    │   └── (existing images)
    │
    ├── IMPLEMENTATION_GUIDE.md ⭐ NEW
    └── COMPLETE_SUMMARY.md ⭐ NEW
```

---

## 🚀 QUICK START CHECKLIST

### **Before You Start:**
- [ ] All new files downloaded from AI Developer
- [ ] VS Code open with project: `E:\Akura Safe Stride\safestride`
- [ ] Git installed and configured
- [ ] Supabase credentials ready (Project URL and anon key)

---

### **Step 1: Copy New Files** (5 minutes)

**Method A: Using File Explorer**
1. Extract downloaded files to Desktop
2. Copy these files:
   ```
   index.html → E:\Akura Safe Stride\safestride\frontend\
   login.html → E:\Akura Safe Stride\safestride\frontend\
   register.html → E:\Akura Safe Stride\safestride\frontend\
   homepage.css → E:\Akura Safe Stride\safestride\frontend\css\
   auth.css → E:\Akura Safe Stride\safestride\frontend\css\
   homepage.js → E:\Akura Safe Stride\safestride\frontend\js\
   auth.js → E:\Akura Safe Stride\safestride\frontend\js\
   auth-guard.js → E:\Akura Safe Stride\safestride\frontend\js\
   IMPLEMENTATION_GUIDE.md → E:\Akura Safe Stride\safestride\frontend\
   COMPLETE_SUMMARY.md → E:\Akura Safe Stride\safestride\frontend\
   ```

**Method B: Using VS Code**
1. Open VS Code
2. Open folder: `E:\Akura Safe Stride\safestride`
3. Drag and drop files into correct folders in VS Code Explorer

---

### **Step 2: Configure Supabase** (2 minutes)

1. Open: `E:\Akura Safe Stride\safestride\frontend\js\auth.js` in VS Code
2. Press `Ctrl+F` and search for: `YOUR_SUPABASE_URL`
3. Replace with your actual Supabase URL: `https://your-project-id.supabase.co`
4. Search for: `YOUR_SUPABASE_ANON_KEY`
5. Replace with your actual anon key: `eyJhbGc...`
6. Save file (`Ctrl+S`)

---

### **Step 3: Protect Dashboard Pages** (5 minutes)

For each of these files:
- athlete-dashboard.html
- coach-dashboard.html
- training-plans.html
- workout-tracking.html
- progress-charts.html

**Do this:**
1. Open file in VS Code
2. Press `Ctrl+F` and search for: `</body>`
3. Add **before** `</body>`:
   ```html
   <!-- Authentication Protection -->
   <script src="js/auth.js"></script>
   <script src="js/auth-guard.js"></script>
   ```
4. Save file

**Example:**
```html
    <!-- Your existing content -->
    
    <!-- Authentication Protection -->
    <script src="js/auth.js"></script>
    <script src="js/auth-guard.js"></script>
</body>
</html>
```

---

### **Step 4: Git Commit & Push** (5 minutes)

Open **Terminal** in VS Code (`Ctrl+``) and run:

```bash
# Navigate to project
cd "E:\Akura Safe Stride\safestride"

# Stage all new files
git add frontend/index.html
git add frontend/login.html
git add frontend/register.html
git add frontend/css/homepage.css
git add frontend/css/auth.css
git add frontend/js/homepage.js
git add frontend/js/auth.js
git add frontend/js/auth-guard.js
git add frontend/IMPLEMENTATION_GUIDE.md
git add frontend/COMPLETE_SUMMARY.md

# Stage updated dashboard files
git add frontend/athlete-dashboard.html
git add frontend/coach-dashboard.html
git add frontend/training-plans.html
git add frontend/workout-tracking.html
git add frontend/progress-charts.html

# Check what will be committed
git status

# Commit
git commit -m "feat: complete homepage and authentication system

- Add Strava-inspired homepage with success stories
- Add split-screen auth pages with runner images
- Add enhanced Supabase authentication
- Add role-based access control
- Add auth guard for protected pages
- Add social media integration
- Add session management
- Protect dashboard pages"

# Push to GitHub
git push origin main
```

---

### **Step 5: Wait for Vercel Deployment** (1-2 minutes)

1. Go to: https://vercel.com/dashboard
2. Select your **akura-safestride** project
3. Watch for new deployment
4. Wait for status: **"Deployment Ready"** ✅

---

### **Step 6: Test Your Site** (10 minutes)

**Test 1: Homepage**
- Visit: https://www.akura.in
- Check: All sections load, navigation works, social links work

**Test 2: Registration**
- Visit: https://www.akura.in/register.html
- Fill form with your email
- Submit
- Check email for verification link

**Test 3: Login**
- Visit: https://www.akura.in/login.html
- Enter credentials
- Should redirect (based on user status)

**Test 4: Auth Guard**
- Open incognito browser
- Try: https://www.akura.in/athlete-dashboard.html
- Should redirect to login

---

## ✅ VERIFICATION CHECKLIST

After deployment, verify:

- [ ] Homepage loads at https://www.akura.in
- [ ] Login page loads at https://www.akura.in/login.html
- [ ] Register page loads at https://www.akura.in/register.html
- [ ] Social media links work in footer
- [ ] Mobile menu works on mobile devices
- [ ] Registration creates user in Supabase
- [ ] Login redirects based on user status
- [ ] Protected pages require authentication
- [ ] Auth guard blocks unauthorized access
- [ ] Password strength indicator works
- [ ] Form validation shows errors correctly

---

## 🐛 TROUBLESHOOTING

### **Issue: Can't find files after download**
**Solution:** Check your Downloads folder, extract ZIP first

### **Issue: Supabase not connecting**
**Solution:** 
1. Check credentials in auth.js (lines 7-8)
2. Verify Supabase project is active
3. Check browser console for errors (F12)

### **Issue: Git push fails**
**Solution:**
```bash
git pull origin main
git push origin main
```

### **Issue: Vercel not deploying**
**Solution:**
1. Check Vercel dashboard for errors
2. Verify GitHub connection
3. Check build logs

### **Issue: Auth guard not working**
**Solution:**
1. Check if auth.js and auth-guard.js are loaded
2. Open browser console (F12) and look for errors
3. Verify files are in correct locations

---

## 📞 NEXT STEPS

**What would you like to do?**

**A)** Guide me through copying files step-by-step  
**B)** Help me configure Supabase credentials  
**C)** Walk me through Git commit and push  
**D)** Test the authentication flow with me  
**E)** Create remaining pages (forgot/reset password, AIFRI assessment, demo dashboard)  
**F)** Something else (specify)

---

## 🎉 YOU'RE ALMOST THERE!

Just follow the checklist above, and your complete AKURA SafeStride platform will be live! 🚀

**Your platform now includes:**
- ✅ Professional Strava-inspired homepage
- ✅ Beautiful split-screen authentication
- ✅ Smart redirect logic
- ✅ Role-based access control
- ✅ Session management
- ✅ Social media integration
- ✅ Mobile-responsive design

**Ready to launch your beta! 💙💚**