# SafeStride Training Calendar - Web Version

A professional training calendar with **V.O2-inspired design** featuring drag-and-drop workout management, Strava integration, and comprehensive workout planning capabilities.

## ✨ Features

### 📅 Calendar Interface

- **Monthly grid view** with week rows
- **Workout cards** with type badges (Easy Run, Quality Session, Race, etc.)
- **Today highlighting** with visual indicators
- **Responsive design** for desktop and mobile

### 🎯 Workout Management

- **Drag-and-drop** workout reordering
- **Bulk edit mode** for multi-select operations
- **Clone week** functionality to duplicate training schedules
- **Add/Edit/Delete** workouts with comprehensive form
- **Workout types**: Easy Run, Quality Session, Long Run, Tempo, Intervals, Race, Cross Training, Rest Day, Day Off

### 🏃 Strava Integration

- **Automatic activity sync** from Strava API
- **GPS activity badges** showing completed workouts
- **Real-time mileage tracking** (planned vs. completed)
- **Progress visualization** with circular charts

### ⭐ Favorites & Templates

- **Workout templates** for quick scheduling
- **Folder organization** (Easy Runs, Quality Sessions, Long Runs)
- **Search functionality** across saved workouts
- **One-click apply** to any date

### 📊 Week Summary

- **Weekly mileage calculator** (completed vs. planned)
- **Progress circle** with completion percentage
- **Workout statistics** (total workouts, completed count)
- **Clone week button** for easy schedule duplication

### 🎨 Design Features

- **V.O2-inspired UI** with gradients and shadows
- **Smooth animations** for drag-drop and interactions
- **Color-coded workout types** for visual clarity
- **Professional styling** with Inter font family

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ and npm
- Supabase account with SafeStride database

### Installation

```bash
# Navigate to web calendar directory
cd web_calendar

# Install dependencies
npm install

# Start development server
npm run dev
```

The calendar will open automatically at `http://localhost:3000`

### Build for Production

```bash
npm run build
npm run preview
```

## 🗄️ Database Setup

The calendar connects to your existing SafeStride Supabase database and requires these tables:

- **`athlete_calendar`**: Scheduled workouts
- **`ai_workouts`**: Workout definitions and details
- **`gps_activities`**: Strava/Garmin activities
- **`workout_templates`**: Favorite workout templates (optional)

### Supabase Configuration

Update credentials in `src/lib/supabase.js`:

```javascript
const supabaseUrl = "YOUR_SUPABASE_URL";
const supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY";
```

## 📂 Project Structure

```
web_calendar/
├── src/
│   ├── components/
│   │   ├── CalendarGrid.jsx       # Main calendar grid
│   │   ├── CalendarHeader.jsx     # Top navigation bar
│   │   ├── WorkoutCard.jsx        # Individual workout display
│   │   ├── WeekSummary.jsx        # Weekly stats sidebar
│   │   ├── WorkoutModal.jsx       # Add/Edit workout form
│   │   ├── BulkEditToolbar.jsx    # Multi-select actions
│   │   ├── FavoritesSidebar.jsx   # Templates sidebar
│   │   └── WeekTabs.jsx           # Week navigation tabs
│   ├── lib/
│   │   └── supabase.js            # Supabase client
│   ├── styles/
│   │   ├── index.css              # Base styles
│   │   └── App.css                # Component styles
│   ├── App.jsx                    # Main app component
│   └── main.jsx                   # Entry point
├── index.html
├── package.json
└── vite.config.js
```

## 🎯 Key Components

### CalendarGrid

- Renders monthly calendar with week rows
- Handles drag-and-drop using `react-beautiful-dnd`
- Displays workouts and Strava activities
- Manages bulk selection state

### WorkoutCard

- Color-coded workout type badges
- Shows distance, duration, pace zone
- Completion status indicators
- Drag handle for reordering

### WeekSummary

- Circular progress chart (SVG)
- Mileage comparison (planned vs. completed)
- Clone week button
- Workout statistics

### WorkoutModal

- Comprehensive workout form
- Dynamic fields based on workout type
- Interval/set configuration for quality sessions
- Pace zone selection

## 🔌 Strava Integration

The calendar automatically pulls Strava activities when:

1. User is authenticated with SafeStride
2. Strava account is connected
3. Activities are synced to `gps_activities` table

Activities display alongside planned workouts with:

- 🏃 Activity icon
- Distance and duration
- Strava orange gradient styling

## 📱 Mobile Support

The calendar is fully responsive with:

- **Single-column layout** on mobile (< 768px)
- **Touch-friendly** drag-and-drop
- **Fixed sidebars** for favorites
- **Collapsible week summaries**

## 🎨 Customization

### Workout Type Colors

Edit colors in `WorkoutCard.jsx`:

```javascript
const workoutTypeConfig = {
  easy_run: { color: "#4A90E2", label: "Easy Run", icon: "🏃" },
  quality_session: { color: "#9B59B6", label: "Quality", icon: "⚡" },
  // ... add more types
};
```

### Theme Colors

Modify CSS variables in `styles/index.css`:

```css
:root {
  --primary-color: #4A90E2;
  --secondary-color: #50C878;
  --danger-color: #E74C3C;
  // ... more colors
}
```

## 🐛 Troubleshooting

### Calendar not loading workouts

- Check Supabase credentials
- Verify `athlete_calendar` table exists
- Ensure user is authenticated

### Drag-and-drop not working

- Check `react-beautiful-dnd` is installed
- Disable bulk edit mode (drag disabled in bulk mode)
- Try refreshing the page

### Strava activities not showing

- Ensure Strava OAuth is connected
- Check `gps_activities` table has data
- Verify date range matches current month

## 📊 Performance

- **Initial load**: < 2 seconds
- **Month navigation**: Instant
- **Drag-and-drop**: 60fps smooth animations
- **Database queries**: Optimistic UI updates

## 🔐 Security

- Supabase Row Level Security (RLS) enforces user isolation
- Client-side validation before server mutations
- Secure token storage via Supabase Auth

## 🚧 Roadmap

- [ ] Export calendar to PDF
- [ ] VDOT pace calculator integration
- [ ] Workout video tutorials
- [ ] Coach notes and comments
- [ ] Multi-athlete view (for coaches)
- [ ] Training plan templates library

## 📄 License

Part of SafeStride - AI Running Coach Platform

## 🤝 Contributing

This is a production component of SafeStride. For issues or feature requests, contact the development team.

---

Built with ⚡ Vite + ⚛️ React + 🎨 Love
