# AKURA SafeStride - Authentication System

## 📚 Overview

Complete, production-ready authentication system for AKURA SafeStride with Supabase integration.

### ✨ Features

- ✅ **User Registration** with email verification
- ✅ **User Login** with session management
- ✅ **Password Reset** flow (forgot/reset password)
- ✅ **Profile Setup** for new users
- ✅ **Role-Based Access Control** (athlete/coach)
- ✅ **Auth Guard** for protected pages
- ✅ **Session Persistence** with auto-refresh
- ✅ **Mobile-Responsive** design
- ✅ **Real-Time Validation** with user feedback
- ✅ **Password Strength Indicator**
- ✅ **Show/Hide Password** toggle
- ✅ **Loading States** for async operations
- ✅ **Error Handling** with user-friendly messages
- ✅ **AKURA Branding** with blue-green gradient

---

## 📁 File Structure

```
frontend/
├── login.html              # User login page
├── register.html           # User registration page
├── forgot-password.html    # Password reset request
├── reset-password.html     # Set new password
├── profile-setup.html      # Optional profile completion
├── css/
│   └── auth.css           # All authentication styles
└── js/
    ├── auth.js            # Supabase authentication logic
    └── auth-guard.js      # Route protection middleware
```

---

## 🚀 Quick Start

### 1. Configure Supabase

Edit `js/auth.js` (lines 13-14):

```javascript
const SUPABASE_URL = 'https://YOUR-PROJECT-ID.supabase.co';
const SUPABASE_ANON_KEY = 'your-anon-key-here';
```

### 2. Deploy

```bash
git add frontend/
git commit -m "feat: add authentication system"
git push origin main
```

### 3. Test

Visit: https://www.akura.in/register.html

---

## 🔧 Integration Guide

### Protect a Page with Auth Guard

Add these scripts to any page that requires authentication:

```html
<!-- Add before </body> -->
<script src="js/auth.js"></script>
<script src="js/auth-guard.js"></script>
</body>
```

### Add Logout Button

```html
<button onclick="handleLogout()">Logout</button>
```

### Display User Info

```html
<div class="user-info">
    <span data-user-name>Loading...</span>
    <span data-user-role></span>
    <span data-user-email></span>
</div>

<script>
    document.addEventListener('DOMContentLoaded', () => {
        displayUserInfo();
    });
</script>
```

### Check if User is Logged In

```javascript
if (isAuthenticated()) {
    // User is logged in
    const userName = getUserName();
    const userRole = getUserRole();
} else {
    // User is not logged in
    redirectToLogin();
}
```

---

## 📖 API Reference

### Authentication Functions

#### `register(email, password, fullName, role)`
Register a new user.

**Parameters:**
- `email` (string): User email
- `password` (string): Password (min 6 characters)
- `fullName` (string): User's full name
- `role` (string): 'athlete' or 'coach'

**Returns:** `Promise<{success: boolean, error?: string, user?: object}>`

**Example:**
```javascript
const result = await register(
    'user@example.com',
    'SecurePass123!',
    'John Doe',
    'athlete'
);

if (result.success) {
    console.log('Registration successful!');
} else {
    console.error('Error:', result.error);
}
```

---

#### `login(email, password)`
Log in an existing user.

**Parameters:**
- `email` (string): User email
- `password` (string): User password

**Returns:** `Promise<{success: boolean, error?: string, session?: object}>`

**Example:**
```javascript
const result = await login('user@example.com', 'SecurePass123!');

if (result.success) {
    redirectToDashboard();
}
```

---

#### `logout()`
Log out the current user.

**Returns:** `Promise<{success: boolean, error?: string}>`

**Example:**
```javascript
const result = await logout();

if (result.success) {
    window.location.href = 'login.html';
}
```

---

#### `resetPassword(email)`
Send password reset email.

**Parameters:**
- `email` (string): User email

**Returns:** `Promise<{success: boolean, error?: string}>`

**Example:**
```javascript
const result = await resetPassword('user@example.com');

if (result.success) {
    alert('Reset link sent to your email!');
}
```

---

#### `updatePassword(newPassword)`
Update user password (after reset link).

**Parameters:**
- `newPassword` (string): New password (min 6 characters)

**Returns:** `Promise<{success: boolean, error?: string}>`

**Example:**
```javascript
const result = await updatePassword('NewSecurePass123!');

if (result.success) {
    window.location.href = 'login.html';
}
```

---

#### `updateUserProfile(profileData)`
Update user profile metadata.

**Parameters:**
- `profileData` (object): Profile fields (age, gender, fitnessLevel, etc.)

**Returns:** `Promise<{success: boolean, error?: string}>`

**Example:**
```javascript
const result = await updateUserProfile({
    age: 30,
    gender: 'male',
    fitnessLevel: 'intermediate',
    weeklyMileage: 40,
    goals: 'half-marathon'
});
```

---

#### `getCurrentUser()`
Get current logged-in user.

**Returns:** `Promise<{user: object | null}>`

**Example:**
```javascript
const { user } = await getCurrentUser();

if (user) {
    console.log('User email:', user.email);
    console.log('User metadata:', user.user_metadata);
}
```

---

#### `getSession()`
Get current session.

**Returns:** `Promise<{session: object | null}>`

**Example:**
```javascript
const { session } = await getSession();

if (session) {
    console.log('Session expires at:', session.expires_at);
}
```

---

### Utility Functions

#### `isAuthenticated()`
Check if user is logged in.

**Returns:** `boolean`

**Example:**
```javascript
if (isAuthenticated()) {
    showDashboard();
} else {
    showLoginForm();
}
```

---

#### `getUserRole()`
Get current user's role.

**Returns:** `string | null` ('athlete' or 'coach')

**Example:**
```javascript
const role = getUserRole();

if (role === 'coach') {
    showCoachFeatures();
} else {
    showAthleteFeatures();
}
```

---

#### `getUserName()`
Get current user's full name.

**Returns:** `string | null`

**Example:**
```javascript
const name = getUserName();
document.getElementById('welcome-message').textContent = `Welcome, ${name}!`;
```

---

#### `redirectToDashboard()`
Redirect to appropriate dashboard based on role.

**Example:**
```javascript
// After successful login
redirectToDashboard(); // Goes to athlete-dashboard.html or coach-dashboard.html
```

---

#### `redirectToLogin()`
Redirect to login page with current URL as redirect parameter.

**Example:**
```javascript
// If user is not authenticated
if (!isAuthenticated()) {
    redirectToLogin(); // Goes to login.html?redirect=/current-page.html
}
```

---

## 🎨 Customization

### Styling

All styles are in `css/auth.css`. Key CSS variables you can customize:

```css
/* Brand Colors */
--primary-blue: #3B82F6;
--primary-green: #10B981;
--gradient: linear-gradient(135deg, #3B82F6 0%, #10B981 100%);

/* Background */
--bg-light: #F9FAFB;

/* Text */
--text-dark: #111827;
--text-gray: #6B7280;

/* Error/Success */
--error-color: #EF4444;
--success-color: #10B981;
```

### Email Templates

Customize email templates in Supabase Dashboard:
1. Go to **Authentication** → **Email Templates**
2. Edit:
   - Confirm Signup
   - Magic Link
   - Change Email Address
   - Reset Password

---

## 🔒 Security Features

- ✅ **Password Hashing**: Handled by Supabase (bcrypt)
- ✅ **JWT Tokens**: Secure session tokens
- ✅ **Email Verification**: Prevents fake accounts
- ✅ **Session Expiry**: Automatic token refresh
- ✅ **HTTPS Only**: All traffic encrypted
- ✅ **CORS Protection**: Configured in Supabase
- ✅ **SQL Injection Prevention**: Supabase ORM protection
- ✅ **XSS Prevention**: Input sanitization
- ✅ **CSRF Protection**: Token-based authentication

---

## 📱 Mobile Support

The authentication system is fully responsive:

- ✅ Mobile-first design
- ✅ Touch-friendly buttons
- ✅ Virtual keyboard optimization
- ✅ Responsive breakpoints:
  - Mobile: 0-640px
  - Tablet: 641-1024px
  - Desktop: 1025px+

---

## 🐛 Troubleshooting

### Common Issues

**Issue**: "Authentication system is initializing"
- **Cause**: Supabase credentials not set
- **Fix**: Update SUPABASE_URL and SUPABASE_ANON_KEY in `js/auth.js`

**Issue**: "Invalid login credentials"
- **Cause**: Wrong email/password or email not verified
- **Fix**: Check email for verification link

**Issue**: Not receiving emails
- **Cause**: Email provider blocking or Supabase email not configured
- **Fix**: Check spam folder, verify email settings in Supabase Dashboard

**Issue**: Redirects not working
- **Cause**: Redirect URLs not configured in Supabase
- **Fix**: Add URLs in Supabase Dashboard → Authentication → URL Configuration

---

## 📊 Testing

See `TESTING_CHECKLIST.md` for comprehensive testing guide.

**Quick Test**:
1. Register: https://www.akura.in/register.html
2. Verify email
3. Login: https://www.akura.in/login.html
4. Access dashboard
5. Logout

---

## 🔄 Deployment

See `DEPLOYMENT.md` for step-by-step deployment guide.

**Quick Deploy**:
```bash
git add frontend/
git commit -m "feat: authentication system"
git push origin main
```

Vercel auto-deploys in ~60 seconds.

---

## 📈 Analytics

Track authentication metrics in Vercel Analytics:
- Registration conversion rate
- Login success rate
- Email verification rate
- Password reset requests
- User retention

---

## 🚀 Future Enhancements

Potential additions:
- [ ] Social login (Google, Facebook, Apple)
- [ ] Two-factor authentication (2FA)
- [ ] Magic link login (passwordless)
- [ ] Account deletion
- [ ] Email change flow
- [ ] Session management (view active sessions)
- [ ] Login history
- [ ] Account security dashboard

---

## 📞 Support

- **Documentation**: This README + DEPLOYMENT.md + TESTING_CHECKLIST.md
- **Supabase Docs**: https://supabase.com/docs/guides/auth
- **Issues**: Check browser console (F12) for error messages

---

## 📄 License

Part of AKURA SafeStride platform.

---

## ✅ Checklist

Before going live:

- [ ] Supabase credentials configured
- [ ] All tests passing (see TESTING_CHECKLIST.md)
- [ ] Email templates customized
- [ ] Redirect URLs configured
- [ ] Auth guard added to protected pages
- [ ] Logout buttons added
- [ ] User info display implemented
- [ ] Mobile tested
- [ ] Error handling verified
- [ ] Beta testers can register successfully

---

**🎉 Your authentication system is ready for beta launch!**
