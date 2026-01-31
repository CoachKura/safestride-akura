# GitHub Copilot Instructions for Akura SafeStride

## Project Context

You are working on **Akura SafeStride**, an AI-powered injury prevention platform for runners. This is a comprehensive web application with:

- **Frontend**: HTML, CSS (Tailwind via CDN), Vanilla JavaScript
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **Deployment**: Vercel (automatic from GitHub main branch)
- **Development**: VS Code with custom tasks and snippets

---

## Tech Stack

### Frontend
- **HTML5** with semantic markup
- **Tailwind CSS** via CDN (`https://cdn.tailwindcss.com`)
- **Vanilla JavaScript** (no frameworks - keep it lightweight)
- **Chart.js** for visualizations (`https://cdn.jsdelivr.net/npm/chart.js@4.4.0`)
- **Font Awesome** for icons (`https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6.4.0`)

### Backend & Database
- **Supabase** (https://yawxlwcniqfspcgefuro.supabase.co)
- **PostgreSQL** via Supabase
- **Supabase JS Client** v2 via CDN
- **Row Level Security (RLS)** enabled on all tables

### Deployment
- **Production**: https://www.akura.in
- **Platform**: Vercel
- **Auto-deploy**: Push to `main` branch triggers deployment

---

## Database Schema

### Core Tables

#### `profiles`
```sql
- id: UUID (primary key, references auth.users)
- email: TEXT (unique)
- full_name: TEXT
- role: TEXT ('athlete' | 'coach')
- assessment_completed: BOOLEAN
- created_at: TIMESTAMP
- updated_at: TIMESTAMP
```

#### `assessments`
```sql
- id: UUID (primary key)
- athlete_id: UUID (foreign key → profiles.id)
- aifri_score: INTEGER (0-100)
- risk_level: TEXT ('LOW' | 'MODERATE' | 'HIGH' | 'VERY HIGH')
- age: INTEGER
- gender: TEXT
- running_experience: TEXT
- weekly_mileage: DECIMAL
- height_cm: DECIMAL
- weight_kg: DECIMAL
- assessment_data: JSONB (detailed scores)
- raw_form_data: JSONB
- metadata: JSONB
- created_at: TIMESTAMP
```

#### `activity_logs`
```sql
- id: UUID (primary key)
- athlete_id: UUID (foreign key → profiles.id)
- activity_date: DATE
- distance_km: DECIMAL
- duration_minutes: INTEGER
- rpe: INTEGER (1-10, Rate of Perceived Exertion)
- activity_type: TEXT
- notes: TEXT
- created_at: TIMESTAMP
```

#### `workouts`
```sql
- id: UUID (primary key)
- athlete_id: UUID (foreign key → profiles.id)
- workout_type: TEXT
- scheduled_date: DATE
- duration_minutes: INTEGER
- distance_km: DECIMAL
- target_rpe: INTEGER
- status: TEXT ('scheduled' | 'completed' | 'skipped')
- location: TEXT
- notes: TEXT
- created_at: TIMESTAMP
```

#### `training_plans`
```sql
- id: UUID (primary key)
- athlete_id: UUID (foreign key → profiles.id)
- start_date: DATE
- end_date: DATE
- weekly_distance_goal: DECIMAL
- status: TEXT ('active' | 'completed' | 'paused')
- created_at: TIMESTAMP
```

#### `pillar_progress`
```sql
- id: UUID (primary key)
- athlete_id: UUID (foreign key → profiles.id)
- week_number: INTEGER
- mobility_score: INTEGER (0-100)
- stability_score: INTEGER (0-100)
- strength_score: INTEGER (0-100)
- endurance_score: INTEGER (0-100)
- technique_score: INTEGER (0-100)
- recovery_score: INTEGER (0-100)
- recorded_at: TIMESTAMP
```

#### `injury_reports`
```sql
- id: UUID (primary key)
- athlete_id: UUID (foreign key → profiles.id)
- injury_type: TEXT
- body_part: TEXT
- severity: INTEGER (1-10)
- onset_date: DATE
- recovery_date: DATE
- status: TEXT ('active' | 'recovering' | 'resolved')
- notes: TEXT
- created_at: TIMESTAMP
```

---

## Supabase Connection Pattern

### Always use this pattern for Supabase:

```javascript
// Initialize Supabase Client
const supabaseUrl = 'https://yawxlwcniqfspcgefuro.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlhd3hsd2NuaXFmc3BjZ2VmdXJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcwODIzNjcsImV4cCI6MjA1MjY1ODM2N30.TUoLNdN3xEhvVqPiR5sTIq8oeHhLm0wPxYe5PzB5qRo';
const supabase = window.supabase.createClient(supabaseUrl, supabaseKey);

// Check authentication
const { data: { user }, error: authError } = await supabase.auth.getUser();
if (authError || !user) {
    window.location.href = '/login.html';
    return;
}

// Query data
const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single();

if (error) {
    console.error('Error:', error);
    return;
}

// Use data
console.log('Profile:', data);
```

---

## Code Style Guidelines

### HTML
- Use semantic HTML5 tags (`<header>`, `<main>`, `<section>`, `<article>`)
- Always include proper meta tags (viewport, charset, description)
- Load scripts at end of `<body>` or use `defer`
- Use descriptive IDs and classes

### CSS (Tailwind)
- Use Tailwind utility classes primarily
- Custom CSS only when necessary
- Follow this color palette:
  - Primary: `#667eea` (purple)
  - Secondary: `#764ba2` (darker purple)
  - Accent: `#f093fb` (pink)
  - Success: `#4CAF50` (green)
  - Warning: `#FF9500` (orange)
  - Danger: `#FF6B6B` (red)

### JavaScript
- Use `async/await` for async operations
- Always handle errors with try-catch
- Use template literals for strings
- Prefer `const` and `let` over `var`
- Use destructuring where appropriate
- Add meaningful console.log messages for debugging

### Error Handling Pattern
```javascript
try {
    const { data, error } = await supabase
        .from('table_name')
        .select('*');
    
    if (error) throw error;
    
    // Process data
    console.log('✅ Data loaded:', data);
    
} catch (error) {
    console.error('❌ Error:', error.message);
    showToast('Error loading data', 'error');
}
```

---

## Common Patterns

### Authentication Check
```javascript
async function checkAuth() {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error || !user) {
        window.location.href = '/login.html';
        return null;
    }
    return user;
}
```

### Load User Profile
```javascript
async function loadProfile(userId) {
    const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();
    
    if (error) {
        console.error('Profile error:', error);
        return null;
    }
    
    return data;
}
```

### Load Latest Assessment
```javascript
async function loadLatestAssessment(athleteId) {
    const { data, error } = await supabase
        .from('assessments')
        .select('*')
        .eq('athlete_id', athleteId)
        .order('created_at', { ascending: false })
        .limit(1)
        .single();
    
    if (error) {
        console.error('Assessment error:', error);
        return null;
    }
    
    return data;
}
```

### Calculate Streak
```javascript
async function calculateStreak(athleteId) {
    const { data, error } = await supabase
        .from('activity_logs')
        .select('activity_date')
        .eq('athlete_id', athleteId)
        .order('activity_date', { ascending: false });
    
    if (error || !data || data.length === 0) return 0;
    
    let streak = 0;
    let currentDate = new Date();
    currentDate.setHours(0, 0, 0, 0);
    
    for (const log of data) {
        const logDate = new Date(log.activity_date);
        logDate.setHours(0, 0, 0, 0);
        
        const diffDays = Math.floor((currentDate - logDate) / (1000 * 60 * 60 * 24));
        
        if (diffDays === streak || (streak === 0 && diffDays === 0)) {
            streak++;
            currentDate = logDate;
        } else if (diffDays > streak + 1) {
            break;
        }
    }
    
    return streak;
}
```

### Toast Notification
```javascript
function showToast(message, type = 'info') {
    // Remove existing toasts
    document.querySelectorAll('.toast').forEach(t => t.remove());
    
    // Create toast
    const toast = document.createElement('div');
    toast.className = `toast fixed top-4 right-4 px-6 py-4 rounded-lg shadow-lg text-white z-50 ${
        type === 'success' ? 'bg-green-500' :
        type === 'error' ? 'bg-red-500' :
        type === 'warning' ? 'bg-yellow-500' :
        'bg-blue-500'
    }`;
    toast.textContent = message;
    
    document.body.appendChild(toast);
    
    // Remove after 3 seconds
    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transition = 'opacity 0.3s';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}
```

---

## UI/UX Guidelines

### Design Principles
1. **Mobile-first**: Design for mobile, enhance for desktop
2. **Progressive disclosure**: Show only what's needed
3. **Clear CTAs**: Primary actions should be obvious
4. **Loading states**: Always show loading indicators
5. **Error states**: Clear error messages with actionable solutions
6. **Empty states**: Helpful messages when no data exists

### Color Usage
- **Primary actions**: Purple gradient (`bg-gradient-to-r from-purple-500 to-pink-500`)
- **Success states**: Green (`bg-green-500`)
- **Warnings**: Orange (`bg-orange-500`)
- **Errors**: Red (`bg-red-500`)
- **Info**: Blue (`bg-blue-500`)

### Typography
- **Headings**: `text-3xl font-bold text-gray-800`
- **Subheadings**: `text-xl font-semibold text-gray-700`
- **Body**: `text-base text-gray-600`
- **Small text**: `text-sm text-gray-500`

### Cards
```html
<div class="bg-white rounded-xl shadow-lg p-6 hover:shadow-xl transition-shadow duration-300">
    <!-- Card content -->
</div>
```

### Buttons
```html
<!-- Primary Button -->
<button class="bg-gradient-to-r from-purple-500 to-pink-500 text-white px-6 py-3 rounded-lg font-semibold hover:scale-105 transition-transform duration-200">
    Click Me
</button>

<!-- Secondary Button -->
<button class="bg-gray-200 text-gray-700 px-6 py-3 rounded-lg font-semibold hover:bg-gray-300 transition-colors duration-200">
    Cancel
</button>
```

---

## Page-Specific Guidelines

### Dashboard (athlete-dashboard-pro.html)
- Load user data on page load
- Show AIFRI score prominently
- Display today's workout
- Show 7-day activity summary
- Calculate and display streak
- Render 6-Pillar Chart.js visualization
- All cards should be clickable (with "Coming Soon" toasts for incomplete features)

### Workout Tracker (track-workout.html)
- Pre-fill workout info from database
- RPE slider (1-10)
- Pain level slider (0-10)
- Sleep hours input
- Nutrition calories input
- Stress level slider (1-10)
- Submit to `activity_logs` table
- Update workout status to 'completed'

### Assessment (assessment-intake.html)
- 9-step form with progress indicator
- Validate each step before proceeding
- Store data in sessionStorage during form
- Calculate AIFRI score on completion
- Save to `assessments` table
- Update `profiles.assessment_completed = true`
- Redirect to dashboard

---

## Common Tasks

### When creating a new page:
1. Copy structure from existing page
2. Include Supabase CDN script
3. Add auth check at page load
4. Use consistent header/footer
5. Add to navigation menus

### When adding a form:
1. Add validation on submit
2. Show loading state during submission
3. Display success/error messages
4. Clear form after successful submission
5. Disable submit button during processing

### When displaying data:
1. Show loading skeleton/spinner
2. Handle empty state
3. Handle error state
4. Format dates consistently
5. Use meaningful default values

### When using Chart.js:
```javascript
const ctx = document.getElementById('myChart').getContext('2d');
const chart = new Chart(ctx, {
    type: 'radar', // or 'line', 'bar', etc.
    data: {
        labels: ['Mobility', 'Stability', 'Strength', 'Endurance', 'Technique', 'Recovery'],
        datasets: [{
            label: '6-Pillar Progress',
            data: [65, 58, 72, 68, 55, 62],
            backgroundColor: 'rgba(102, 126, 234, 0.2)',
            borderColor: 'rgba(102, 126, 234, 1)',
            borderWidth: 2
        }]
    },
    options: {
        scales: {
            r: {
                beginAtZero: true,
                max: 100
            }
        }
    }
});
```

---

## Testing Checklist

Before committing code:
- [ ] Test on desktop (Chrome, Firefox, Safari)
- [ ] Test on mobile (responsive design)
- [ ] Test auth flow (login, logout, protected routes)
- [ ] Test all forms (validation, submission, errors)
- [ ] Test data loading (loading states, empty states, errors)
- [ ] Check console for errors
- [ ] Verify Supabase queries work
- [ ] Test navigation (all links work)
- [ ] Verify images/icons load
- [ ] Check accessibility (keyboard navigation, screen readers)

---

## Deployment Workflow

1. **Local Development**
   ```bash
   # Start local server
   python3 -m http.server 3000
   # Or use VS Code task: Ctrl+Shift+P → "🚀 Start Development Server"
   ```

2. **Test Locally**
   - Open http://localhost:3000
   - Test all features
   - Check console for errors

3. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: descriptive commit message"
   ```

4. **Push to GitHub**
   ```bash
   git push origin main
   ```

5. **Verify Production**
   - Wait 2 minutes for Vercel deployment
   - Test at https://www.akura.in
   - Check Vercel dashboard for deployment logs

---

## Environment Variables

### Development (.env.local - DO NOT COMMIT)
```
SUPABASE_URL=https://yawxlwcniqfspcgefuro.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Production (Vercel Environment Variables)
- Set in Vercel dashboard
- Same values as development

---

## Debugging Tips

### Supabase Errors
- Check RLS policies if queries fail
- Verify user is authenticated
- Check table permissions
- Use Supabase dashboard to test queries

### JavaScript Errors
- Check browser console (F12)
- Use `console.log` liberally
- Use `console.table` for arrays of objects
- Use `debugger` statement for breakpoints

### CSS Issues
- Use browser DevTools to inspect elements
- Check Tailwind classes are correct
- Verify CDN is loading
- Check for CSS conflicts

---

## Resources

- **Supabase Docs**: https://supabase.com/docs
- **Tailwind Docs**: https://tailwindcss.com/docs
- **Chart.js Docs**: https://www.chartjs.org/docs
- **MDN Web Docs**: https://developer.mozilla.org

---

## Contact & Support

- **Production**: https://www.akura.in
- **Supabase**: https://supabase.com/dashboard/project/yawxlwcniqfspcgefuro
- **GitHub**: https://github.com/CoachKura/safestride-akura

---

**Last Updated**: January 31, 2026
**Version**: 1.0.0
