# AI Workout Generator System

## Overview
The AI Workout Generator automatically creates personalized training plans based on athlete goals, fitness level, and AISRI scores. Workouts are intelligently scheduled in the calendar and appear as "Today's Workout" and "Tomorrow's Workout" on the dashboard.

## Features

### 1. **Goal-Based Training Plans**
Create comprehensive training plans for various goals:
- 🏃 **Marathon** - 42.2km race preparation
- 🏃 **Half Marathon** - 21.1km race preparation  
- 🏃 **10K Race** - 10km race preparation
- 🏃 **5K Race** - 5km race preparation
- 💪 **General Fitness** - Build overall running fitness
- ⚖️ **Weight Loss** - Cardio-focused training

### 2. **Personalization Factors**
The AI considers multiple factors:
- **Current Weekly Distance** - Your baseline training volume
- **Training Days Per Week** - 3-7 days available
- **Fitness Level** - Beginner, Intermediate, Advanced
- **AISRI Score** - Adjusts intensity based on injury risk
- **Weeks to Goal** - 4-24 week training plans
- **Target Race Date** - Optional specific event date

### 3. **Intelligent Workout Distribution**

#### Workout Types
- **Recovery Run** 🟢 - Easy pace (50-60% max HR)
- **Easy Run** 🟢 - Conversational pace (60-70% max HR)
- **Tempo Run** 🟡 - Comfortably hard (80-87% max HR)
- **Interval Training** 🔴 - High intensity (87-95% max HR)
- **Long Run** 🔵 - Endurance building (65-75% max HR)

#### Training Phases
1. **Base Building** (Weeks 1-70%) - Focus on volume
2. **Peak Training** (Weeks 71-90%) - Maximum load
3. **Taper** (Weeks 91-100%) - Reduced volume before race

### 4. **Progressive Overload**
The AI applies smart progression:
- **Beginner/Low AISRI (<60)**: 8% weekly increase
- **Intermediate**: 10% weekly increase (default)
- **Advanced/High AISRI (>75)**: 12% weekly increase

### 5. **Heart Rate Zones**
Each workout includes target HR zones based on age:
- Max HR = 208 - (0.7 × age)
- Zones automatically calculated and displayed

## How to Use

### Creating a Training Plan

1. **Access the AI Generator**:
   - Dashboard → More Menu (⋮) → "AI Training Plan"
   - OR tap "Generate Plan" button when no workouts scheduled

2. **Set Your Parameters**:
   - Select your goal (5K, 10K, Half, Marathon, etc.)
   - Choose training duration (4-24 weeks)
   - Set current weekly distance
   - Pick training days per week (3-7)
   - Select fitness level

3. **Review the Plan**:
   - View weekly distance progression chart
   - Preview upcoming workouts
   - Check workout distribution

4. **Save to Calendar**:
   - Tap "Save to Calendar"
   - All workouts automatically added
   - Appear in calendar and dashboard

### Getting Today's Workout Suggestion

1. From Dashboard AI card, tap **"Suggest"** button
2. AI analyzes your recent activity:
   - Days since last workout
   - Weekly volume
   - Consistency patterns
3. Provides immediate workout recommendation
4. Tap "Start Workout" to begin

### Viewing AI Workouts

- **Dashboard**: Shows today's and tomorrow's AI workouts
- **Calendar**: All AI workouts marked with ⭐ badge
- **Workout History**: Filter by AI-generated workouts

## Smart Features

### 1. **AISRI Integration**
- Low AISRI (<60): Safer progression, more recovery
- Moderate AISRI (60-75): Standard progression
- High AISRI (>75): Aggressive progression allowed

### 2. **Recent Activity Analysis**
The AI considers:
- Your last workout date
- Weekly distance trends
- Workout frequency
- Suggests appropriate intensity

### 3. **Adaptive Recommendations**
Today's suggestion adapts to:
- **2+ days off**: Easy comeback run
- **Low weekly volume**: Base-building easy runs
- **Consistent training**: Quality tempo/interval work

### 4. **Race Day Focus**
For race goals:
- Peak weeks before race
- Taper in final 2 weeks
- Reduced volume, maintained intensity

## Workout Structure

### Example: 12-Week Marathon Plan
- **Weeks 1-8**: Base Building
  - 50-70km per week
  - Mostly easy runs + 1 tempo
  - Weekly long run progression
  
- **Weeks 9-10**: Peak Training
  - 70-80km per week
  - Add interval sessions
  - Longest long runs (25-30km)
  
- **Weeks 11-12**: Taper
  - 50-60km per week
  - Maintain intensity, reduce volume
  - Race day preparation

### Weekly Schedule Example (4 days/week)
- **Monday**: Easy Run (5km, 35min)
- **Wednesday**: Tempo Run (8km, 48min)
- **Friday**: Intervals (6km, 40min)
- **Sunday**: Long Run (18km, 2h)

## Database Schema

### `calendar_entries` (Extended)
```sql
- is_ai_generated: boolean
- target_hr_min: integer
- target_hr_max: integer
- intensity: varchar (low/moderate/high)
- week_number: integer
- description: text
- notes: text
```

### `ai_training_plans`
```sql
- id: uuid
- user_id: uuid
- goal_type: varchar
- fitness_level: varchar
- weeks_to_goal: integer
- training_days_per_week: integer
- target_race_date: timestamp
- total_workouts: integer
- status: varchar (active/completed/cancelled)
```

## Key Algorithms

### 1. **Weekly Distance Progression**
```dart
targetKm = goalTypeTarget (e.g., 70km for marathon)
startKm = currentWeeklyKm
progressionRate = 1.08 to 1.12 (based on fitness/AISRI)

for each week:
  if buildingPhase: currentKm *= progressionRate
  if peakPhase: currentKm = targetKm
  if taperPhase: currentKm = targetKm * 0.7
```

### 2. **Workout Type Selection**
```dart
3 days/week: [easy, tempo, long]
4 days/week: [easy, tempo, intervals, long]
5 days/week: [easy, tempo, easy, intervals, long]
6 days/week: [easy, tempo, easy, intervals, easy, long]
7 days/week: [easy, tempo, easy, intervals, recovery, easy, long]
```

### 3. **Distance Distribution**
- Long Run: 35% of weekly distance
- Tempo: 25%
- Intervals: 20%
- Easy: 15%
- Recovery: 10%

### 4. **Pace Calculation**
```dart
basePace = {
  beginner: 7.0 min/km,
  intermediate: 6.0 min/km,
  advanced: 5.0 min/km
}

paceModifiers = {
  recovery: 1.3x slower,
  easy: 1.2x slower,
  tempo: 1.0x (race pace),
  intervals: 0.9x (faster),
  long: 1.15x (slightly slower)
}
```

## Benefits

✅ **Personalized** - Tailored to your goals and fitness
✅ **Progressive** - Smart volume increases
✅ **Safe** - Respects AISRI injury prevention
✅ **Comprehensive** - Full race preparation
✅ **Flexible** - 3-7 training days
✅ **Adaptive** - Adjusts to your progress
✅ **Automated** - No manual planning needed
✅ **Integrated** - Syncs with calendar & dashboard

## Tips for Best Results

1. **Complete AISRI Assessment** first for accurate personalization
2. **Be Honest** about current fitness level
3. **Start Conservative** - can always increase later
4. **Follow the Plan** - AI balanced easy & hard days
5. **Log Your Workouts** - helps AI refine suggestions
6. **Update Goals** as you progress
7. **Rest Days Matter** - built into the plan

## Future Enhancements

🔮 Planned features:
- **Real-time Adaptation** - Adjust plan based on actual performance
- **Weather Integration** - Modify workouts for conditions
- **Recovery Monitoring** - HRV-based rest days
- **Race Strategy** - Pacing recommendations
- **Cross-Training** - Add strength/swim/bike
- **Social Features** - Share plans with coach
- **Performance Prediction** - Estimate race times

## Technical Implementation

### Services
- `AIWorkoutGeneratorService` - Core generation logic
- Integrates with AISRI, Calendar, Profile services

### Screens
- `GoalBasedWorkoutCreatorScreen` - Plan creation UI
- Dashboard integration - Today/tomorrow display
- Calendar integration - Full plan view

### Database
- Migration: `migration_ai_workout_calendar.sql`
- Tables: `ai_training_plans`, extended `calendar_entries`
- RLS policies for user data security

---

**Get Started**: Open Dashboard → Tap "Generate Plan" or use More Menu → AI Training Plan!
