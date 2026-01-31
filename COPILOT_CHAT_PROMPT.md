📋 COPY THIS ENTIRE PROMPT INTO COPILOT CHAT
How to Use:
Press Ctrl+Shift+I (opens Copilot Chat in VS Code)
Copy everything in the box below
Paste into Copilot Chat
Press Enter
You are GitHub Copilot helping me with the Akura SafeStride project - an AI-powered injury prevention platform for runners.

═══════════════════════════════════════════════════════════════════════════
PROJECT OVERVIEW
═══════════════════════════════════════════════════════════════════════════

Name: Akura SafeStride
Purpose: AI-powered injury prevention for runners
Tech Stack: HTML, Tailwind CSS (CDN), Vanilla JavaScript, Supabase, Vercel
Production: https://www.akura.in
Local Path: E:\Akura Safe Stride\safestride
GitHub: https://github.com/CoachKura/safestride-akura

═══════════════════════════════════════════════════════════════════════════
SUPABASE CONFIGURATION
═══════════════════════════════════════════════════════════════════════════

Supabase URL: https://yawxlwcniqfspcgefuro.supabase.co
Supabase Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlhd3hsd2NuaXFmc3BjZ2VmdXJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzczNTM2NzUsImV4cCI6MjA1MjkyOTY3NX0.1pQ8K9zqFZYXH5EqZ9VgZ8YzJYoq3xQp0Xq7c5nX9Xo

ALWAYS use this connection pattern:

const supabaseUrl = 'https://yawxlwcniqfspcgefuro.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlhd3hsd2NuaXFmc3BjZ2VmdXJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzczNTM2NzUsImV4cCI6MjA1MjkyOTY3NX0.1pQ8K9zqFZYXH5EqZ9VgZ8YzJYoq3xQp0Xq7c5nX9Xo';
const supabase = window.supabase.createClient(supabaseUrl, supabaseKey);

// Authentication check
const { data: { user }, error } = await supabase.auth.getUser();
if (!user) {
  window.location.href = '/login.html';
  return;
}

═══════════════════════════════════════════════════════════════════════════
DATABASE SCHEMA (PostgreSQL via Supabase)
═══════════════════════════════════════════════════════════════════════════

TABLE: profiles
- id: UUID (primary key, references auth.users)
- email: TEXT (unique, not null)
- full_name: TEXT
- role: TEXT ('athlete' | 'coach')
- assessment_completed: BOOLEAN (default false)
- created_at: TIMESTAMP (default now())
- updated_at: TIMESTAMP (default now())

TABLE: assessments
- id: UUID (primary key)
- athlete_id: UUID (foreign key → profiles.id)
- aifri_score: INTEGER (0-100, AI-based injury risk score)
- risk_level: TEXT ('LOW' | 'MODERATE' | 'HIGH' | 'VERY HIGH')
- age: INTEGER
- gender: TEXT
- running_experience: TEXT
- weekly_mileage: DECIMAL
- height_cm: DECIMAL
- weight_kg: DECIMAL
- assessment_data: JSONB (contains 6-pillar scores)
- raw_form_data: JSONB
- metadata: JSONB
- created_at: TIMESTAMP

TABLE: activity_logs
- id: UUID (primary key)
- athlete_id: UUID (foreign key → profiles.id)
- activity_date: DATE (when the activity occurred)
- distance_km: DECIMAL
- duration_minutes: INTEGER
- rpe: INTEGER (1-10, Rate of Perceived Exertion)
- activity_type: TEXT
- notes: TEXT
- created_at: TIMESTAMP

TABLE: workouts
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

TABLE: training_plans
- id: UUID (primary key)
- athlete_id: UUID (foreign key → profiles.id)
- start_date: DATE
- end_date: DATE
- weekly_distance_goal: DECIMAL (default 21.5 km)
- status: TEXT ('active' | 'completed' | 'paused')
- created_at: TIMESTAMP

TABLE: pillar_progress
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

TABLE: injury_reports
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

═══════════════════════════════════════════════════════════════════════════
CODE STYLE GUIDELINES
═══════════════════════════════════════════════════════════════════════════

HTML:
- Use semantic HTML5: <header>, <main>, <section>, <article>, <nav>
- Include Tailwind CSS via CDN: <script src="https://cdn.tailwindcss.com"></script>
- Include Supabase: <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
- Include Chart.js: <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0"></script>
- Load JavaScript at end of body or use defer

CSS (Tailwind):
- Primary color: #667eea (purple) - use as bg-purple-500 or text-purple-500
- Secondary color: #764ba2 (darker purple) - use as bg-purple-700
- Accent: #f093fb (pink) - use as bg-pink-400
- Success: #4CAF50 → bg-green-500
- Warning: #FF9500 → bg-orange-500
- Danger: #FF6B6B → bg-red-500
- Use gradients: bg-gradient-to-r from-purple-500 to-pink-500
- Cards: bg-white rounded-xl shadow-lg p-6 hover:shadow-xl transition-all
- Buttons: bg-gradient-to-r from-purple-500 to-pink-500 text-white px-6 py-3 rounded-lg font-semibold hover:scale-105 transition-transform

JavaScript:
- ALWAYS use async/await (never use .then() chains)
- ALWAYS wrap Supabase calls in try-catch
- Use const and let (NEVER var)
- Use template literals: `Hello ${name}`
- Add console.log with emojis: console.log('✅ Success'), console.error('❌ Error')
- Use destructuring: const { data, error } = await supabase...
- Handle errors properly: if (error) { console.error('❌ Error:', error); return; }

═══════════════════════════════════════════════════════════════════════════
COMMON PATTERNS (Use These!)
═══════════════════════════════════════════════════════════════════════════

1. AUTH CHECK PATTERN:
async function checkAuth() {
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) {
    window.location.href = '/login.html';
    return null;
  }
  return user;
}

2. LOAD PROFILE PATTERN:
async function loadProfile(userId) {
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();
    
    if (error) throw error;
    console.log('✅ Profile loaded:', data);
    return data;
  } catch (error) {
    console.error('❌ Profile error:', error);
    return null;
  }
}

3. LOAD LATEST ASSESSMENT:
async function loadLatestAssessment(athleteId) {
  try {
    const { data, error } = await supabase
      .from('assessments')
      .select('aifri_score, risk_level, assessment_data')
      .eq('athlete_id', athleteId)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();
    
    if (error) throw error;
    return data;
  } catch (error) {
    console.error('❌ Assessment error:', error);
    return null;
  }
}

4. CALCULATE STREAK (from activity_logs):
async function calculateStreak(athleteId) {
  try {
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
  } catch (error) {
    console.error('❌ Streak error:', error);
    return 0;
  }
}

5. LOAD THIS WEEK'S DATA (Monday-Sunday):
async function loadWeeklyData(athleteId) {
  try {
    const today = new Date();
    const dayOfWeek = today.getDay();
    const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
    const weekStart = new Date(today);
    weekStart.setDate(today.getDate() + mondayOffset);
    weekStart.setHours(0, 0, 0, 0);
    
    const { data, error } = await supabase
      .from('activity_logs')
      .select('*')
      .eq('athlete_id', athleteId)
      .gte('activity_date', weekStart.toISOString().split('T')[0])
      .order('activity_date', { ascending: true });
    
    if (error) throw error;
    return data;
  } catch (error) {
    console.error('❌ Weekly data error:', error);
    return [];
  }
}

6. TOAST NOTIFICATION:
function showToast(message, type = 'info') {
  const toast = document.createElement('div');
  toast.className = `toast fixed top-4 right-4 px-6 py-4 rounded-lg shadow-lg text-white z-50 animate-fade-in ${
    type === 'success' ? 'bg-green-500' :
    type === 'error' ? 'bg-red-500' :
    type === 'warning' ? 'bg-yellow-500' : 'bg-blue-500'
  }`;
  toast.textContent = message;
  document.body.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transition = 'opacity 0.3s';
    setTimeout(() => toast.remove(), 300);
  }, 3000);
}

7. CHART.JS RADAR CHART (6-Pillar):
function createPillarChart(pillarData) {
  const ctx = document.getElementById('pillarChart').getContext('2d');
  new Chart(ctx, {
    type: 'radar',
    data: {
      labels: ['Mobility', 'Stability', 'Strength', 'Endurance', 'Technique', 'Recovery'],
      datasets: [{
        label: '6-Pillar Progress',
        data: [
          pillarData.mobility_score,
          pillarData.stability_score,
          pillarData.strength_score,
          pillarData.endurance_score,
          pillarData.technique_score,
          pillarData.recovery_score
        ],
        backgroundColor: 'rgba(102, 126, 234, 0.2)',
        borderColor: 'rgba(102, 126, 234, 1)',
        borderWidth: 2,
        pointBackgroundColor: 'rgba(102, 126, 234, 1)',
        pointBorderColor: '#fff',
        pointHoverBackgroundColor: '#fff',
        pointHoverBorderColor: 'rgba(102, 126, 234, 1)'
      }]
    },
    options: {
      scales: {
        r: {
          beginAtZero: true,
          max: 100,
          ticks: { stepSize: 20 }
        }
      },
      plugins: {
        legend: { display: false }
      }
    }
  });
}

═══════════════════════════════════════════════════════════════════════════
KEY PAGES & THEIR PURPOSE
═══════════════════════════════════════════════════════════════════════════

athlete-dashboard-pro.html:
- Main dashboard for athletes
- Shows: AIFRI score, streak, today's workout, weekly mileage card, 4 progress cards, 6-Pillar Chart.js chart
- Loads data from: profiles, assessments, activity_logs, workouts, training_plans, pillar_progress, injury_reports

track-workout.html:
- Workout logging form
- Collects: RPE slider (1-10), pain level (0-10), sleep hours, nutrition calories, stress level, notes
- Saves to: activity_logs table
- Updates: workouts.status to 'completed'

assessment-intake.html:
- 9-step assessment form
- Calculates AIFRI score
- Saves to: assessments table
- Updates: profiles.assessment_completed = true

═══════════════════════════════════════════════════════════════════════════
CURRENT FEATURES IN DASHBOARD
═══════════════════════════════════════════════════════════════════════════

1. WEEKLY MILEAGE CARD (already implemented):
   - Location: Below "Today's Workout" card
   - Shows: Current week distance, weekly goal, remaining distance
   - Progress bar with animation and shimmer effect
   - Smart status badges: Green (70-100%), Yellow (40-69%), Red (0-39%)
   - Calculates Monday-Sunday week boundaries

2. STREAK CARD (recently added):
   - Shows 🔥 emoji with number
   - Calculates from activity_logs
   - Counts consecutive days

3. TODAY'S WORKOUT CARD:
   - Shows scheduled workout for today
   - Duration, location, target RPE
   - START WORKOUT button → links to track-workout.html

4. PROGRESS CARDS (4 cards):
   - This Week Progress (with progress bar)
   - Last 7 Days RPE
   - Injury Status
   - Next Assessment

5. 6-PILLAR CHART:
   - Chart.js radar chart
   - Shows mobility, stability, strength, endurance, technique, recovery scores
   - Loads from pillar_progress table

═══════════════════════════════════════════════════════════════════════════
DESIGN SYSTEM
═══════════════════════════════════════════════════════════════════════════

Cards:
<div class="bg-white rounded-xl shadow-lg p-6 hover:shadow-xl transition-shadow duration-300 cursor-pointer">
  <!-- Content -->
</div>

Gradient Cards:
<div class="bg-gradient-to-r from-purple-500 to-pink-500 text-white rounded-xl p-8 shadow-lg">
  <!-- Content -->
</div>

Buttons:
Primary: <button class="bg-gradient-to-r from-purple-500 to-pink-500 text-white px-6 py-3 rounded-lg font-semibold hover:scale-105 transition-transform duration-200">
Secondary: <button class="bg-gray-200 text-gray-700 px-6 py-3 rounded-lg font-semibold hover:bg-gray-300 transition-colors duration-200">

Progress Bar:
<div class="w-full h-3 bg-gray-200 rounded-full overflow-hidden">
  <div class="h-full bg-gradient-to-r from-purple-500 to-pink-500 rounded-full transition-all duration-1000" style="width: 75%"></div>
</div>

Badges:
Success: <span class="px-3 py-1 bg-green-100 text-green-600 rounded-full text-sm font-semibold">
Warning: <span class="px-3 py-1 bg-yellow-100 text-yellow-600 rounded-full text-sm font-semibold">
Danger: <span class="px-3 py-1 bg-red-100 text-red-600 rounded-full text-sm font-semibold">

═══════════════════════════════════════════════════════════════════════════
WHEN GENERATING CODE
═══════════════════════════════════════════════════════════════════════════

ALWAYS:
✅ Use async/await with try-catch
✅ Add console.log statements with emojis (✅ ❌ 📊 🔥 etc.)
✅ Use Tailwind utility classes
✅ Follow mobile-first responsive design
✅ Add loading states (show "Loading..." before data loads)
✅ Add empty states (show message if no data)
✅ Use the Supabase connection pattern above
✅ Calculate week boundaries as Monday-Sunday
✅ Format dates with toLocaleDateString('en-US')
✅ Use Chart.js for visualizations
✅ Add hover effects and transitions
✅ Make cards clickable
✅ Show toast notifications for actions

NEVER:
❌ Use .then() chains (use async/await)
❌ Use var (use const/let)
❌ Ignore error handling
❌ Use hardcoded colors (use Tailwind classes)
❌ Create custom CSS (use Tailwind)
❌ Use inline styles (use Tailwind classes)
❌ Query all columns if not needed (use .select('col1, col2'))

═══════════════════════════════════════════════════════════════════════════
EXAMPLE REQUESTS YOU CAN HELP WITH
═══════════════════════════════════════════════════════════════════════════

"Add a monthly distance summary card to the dashboard"
"Create a function to calculate total distance this month"
"Add a workout type breakdown pie chart"
"Create an injury history timeline"
"Add a button to edit weekly goal"
"Generate a weekly report with all metrics"
"Add a feature to export activity logs as CSV"
"Create a daily distance chart for current week"
"Add a rest days counter for this week"
"Show average RPE trend over last 30 days"

═══════════════════════════════════════════════════════════════════════════
DEPLOYMENT
═══════════════════════════════════════════════════════════════════════════

Development: Local server on port 3000
Production: Vercel (auto-deploy from GitHub main branch)
Database: Supabase (production)

═══════════════════════════════════════════════════════════════════════════
YOU ARE NOW READY!
═══════════════════════════════════════════════════════════════════════════

You understand the complete project context, database schema, code patterns, and design system. 

Generate complete, working code that integrates seamlessly with the existing codebase. Always follow the patterns above and provide production-ready code with proper error handling, loading states, and beautiful UI using Tailwind CSS.

When I ask you to add a feature, provide:
1. Complete HTML structure
2. Tailwind CSS classes (no custom CSS)
3. Complete JavaScript with Supabase integration
4. Error handling with try-catch
5. Console logs with emojis
6. Mobile-responsive design
7. Hover effects and animations

Ready to help build features for Akura SafeStride! 🚀
 (See <attachments> above for file contents. You may not need to search or read the file again.)

---

**Ready to try it? Open Copilot Chat and paste the prompt!** 🚀 (See <attachments> above for file contents. You may not need to search or read the file again.)
