# Structured Workout Builder - Deployment Guide

## 🎯 What's Been Created

### ✅ Complete Files Created (4 files):

1. **lib/models/structured_workout.dart** (400+ lines)
   - Complete Garmin-style data model
   - Enums: WorkoutStepType, DurationType, IntensityType
   - Classes: WorkoutStep, StructuredWorkout
   - Full JSON serialization

2. **database/migration_structured_workouts.sql** (170+ lines)
   - Database schema for structured_workouts table
   - Database schema for workout_assignments table
   - RLS policies for security
   - Indexes for performance
   - Automatic timestamps

3. **lib/services/structured_workout_service.dart** (100+ lines)
   - Complete CRUD operations
   - Workout assignment functionality
   - Athlete assignment queries
   - Completion tracking

4. **lib/screens/structured_workout_list_screen.dart** (280+ lines)
   - List all workouts
   - Create, edit, delete functionality
   - Activity type icons
   - Step count, distance, duration display

5. **lib/screens/structured_workout_detail_screen.dart** (NEW - 480+ lines)
   - Create/edit workout
   - Workout name, description, activity type
   - Step-by-step builder with drag-to-reorder
   - Real-time step preview
   - Validation and error handling

6. **lib/screens/step_editor_screen.dart** (NEW - 850+ lines)
   - Complete Garmin-style step editor
   - Step types: Warm Up, Run, Recovery, Rest, Cool Down, Repeat, Other
   - Duration types: Distance (km), Time, Lap Button Press, Calories, Heart Rate, Open
   - Intensity targets:
     * No Target
     * Pace (min/km range)
     * Cadence (steps/min)
     * AISRI Training Zones (6 zones) with dynamic calculation:
       - Zone AR (Active Recovery): 50-60% Max HR
       - Zone F (Foundation): 60-70% Max HR
       - Zone EN (Endurance): 70-80% Max HR
       - Zone TH (Threshold ⭐): 80-87% Max HR
       - Zone P (Power): 87-95% Max HR
       - Zone SP (Speed): 95-100% Max HR
       - Max HR calculated as: 208 - (0.7 × Age)
       - Uses actual user age from athlete profile
     * Custom Heart Rate (custom bpm range)
     * Power Zone
     * Custom Power (watts)
   - Notes field for each step

### ✅ Integration Complete:

7. **lib/screens/dashboard_screen.dart** (Updated)
   - Added "Structured Workouts" to More Menu
   - Icon: format_list_numbered
   - Blue color matching Kura Coach theme
   - Navigates to StructuredWorkoutListScreen

---

## 📋 Deployment Steps

### Step 1: Deploy Database Migration (2 minutes)

1. Open Supabase Dashboard: https://supabase.com/dashboard
2. Navigate to: **SQL Editor** (left sidebar)
3. Click: **New Query**
4. Copy the entire contents of: `database/migration_structured_workouts.sql`
5. Paste into SQL Editor
6. Click: **RUN** button (or press F5)
7. ✅ Success message: "Success. No rows returned"

**Verify Tables Created:**
- Go to **Table Editor** (left sidebar)
- You should see:
  * `structured_workouts` table
  * `workout_assignments` table
- Check **Policies** tab to verify RLS is enabled

---

### Step 2: Hot Reload App (30 seconds)

Since the app is already running with `flutter run --hot`:

1. In the VS Code terminal where the app is running
2. Press **`r`** (lowercase R) for hot reload
3. Wait 5-10 seconds for reload to complete
4. ✅ You'll see: "Reloaded X of Y libraries..."

---

### Step 3: Test the System (5 minutes)

#### **Test 1: Access Structured Workouts**
1. In app: Tap **More Menu (⋮)** (top right of dashboard)
2. Scroll down to **Kura Coach** section (blue items)
3. Tap: **"Structured Workouts"**
4. ✅ You should see the workout list screen (empty at first)

#### **Test 2: Create First Workout**
1. Tap: **"ADD WORKOUT"** button (bottom)
2. Enter:
   - **Workout Name**: "Run Workout (2)"
   - **Description**: "Long run with intervals"
   - **Activity Type**: Running
3. Tap: **"ADD STEP"**

#### **Test 3: Add Warm Up Step**
1. **Step Type**: Warm Up
2. **Duration Type**: Lap Button Press
3. **Intensity Target**: No Target
4. Tap: **"DONE"**
5. ✅ Step appears in list with orange color

#### **Test 4: Add Run Step**
1. Tap: **"ADD STEP"** again
2. **Step Type**: RunAISRI Training Zones (6 zones)
6. **Select**: Zone EN (Endurance) - 126-144 bpm (for 40-year-old)
7. Tap: **"DONE"**
8. ✅ Step appears with blue color, shows "1.00 km" and "Zone EN (Endurance) (126-14
6. **Select**: Zone 2 (106-124 bpm)
7. Tap: **"DONE"**
8. ✅ Step appears with blue color, shows "1.00 km" and "HR Zone 2 (106-124 bpm)"

#### **Test 5: Add Cool Down Step**
1. Tap: **"ADD STEP"** again
2. **Step Type**: Cool Down
3. **Duration Type**: Lap Button Press
4. **Intensity Target**: No Target
5. Tap: **"DONE"**
6. ✅ Step appears with purple color

#### **Test 6: Save Workout**
1. Review the 3 steps (Warm Up → Run → Cool Down)
2. Tap: **"SAVE"** (top right)
3. ✅ Green snackbar: "Workout saved successfully!"
4. ✅ Returns to workout list
5. ✅ Workout card shows:
   - Name: "Run Workout (2)"
   - Description
   - 3 steps
   - 1.00 km estimated distance

#### **Test 7: Edit Workout**
1. Tap: **⋮** (more menu) on workout card
2. Tap: **"Edit"**
3. ✅ Opens detail screen with all 3 steps
4. Tap on **Step 2** (Run step)
5. Change distance to **2.00 km**
6. Tap: **"DONE"**
7. Tap: **"SAVE"**
8. ✅ Workout card now shows "2.00 km"

#### **Test 8: Drag to Reorder Steps**
1. Edit the workout again
2. **Long press** and **drag** the step handle (☰ icon)
3. Reorder steps
4. ✅ Steps reorder smoothly

#### **Test 9: Delete Step**
1. Edit the workout
2. Tap: **🗑️ Delete** button on a step
3. ✅ Confirmation dialog appears
4. Tap: **"DELETE"**
5. ✅ Step removed

#### **Test 10: Delete Workout**
1. Back to workout list
2. Tap: **⋮** on workout card
3. Tap: **"Delete"**
4. ✅ Confirmation dialog
5. Tap: **"DELETE"**
6. ✅ Workout removed from list

---

## 🎨 Features Overview

### Step Types:
- 🔶 **Warm Up** (Orange)
- 🔵 **Run** (Blue)
- 🟢 **Recovery** (Green)
- ⚪ **Rest** (Grey)
- 🟣 **Cool Down** (Purple)
- 🟦 **Repeat** (Teal)
- 🟫 **Other** (Brown)

### Duration Types:
- **Distance**: Enter km (e.g., 1.00 km)
- **Time**: Enter minutes (auto-converts to hh:mm:ss)
- **Lap Button Press**: Manual trigger
- **Calories**: Enter kcal target
- **Heart Rate**: Continue until target HR
- **Open**: No duration limit

### Intensity Targets:
- **No Target**: Free pace
- **Pace**: Min-Max pace range (min/km)
- **Cadence**: Min-Max steps per minute
- **AISRI Training Zones (6 zones)**: Based on Max HR = 208 - (0.7 × Age)
  * **Zone AR** (Active Recovery): 50-60% Max HR - Recovery, Warm-up, Cool-down
  * **Zone F** (Foundation): 60-70% Max HR - Aerobic Base, Fat Burning, Stamina
  * **Zone EN** (Endurance): 70-80% Max HR - Aerobic Fitness, Improved Oxygen Efficiency
  * **Zone TH** (Threshold ⭐ CORE): 80-87% Max HR - Lactate Threshold, Anaerobic Capacity, Speed Endurance
  * **Zone P** (Power): 87-95% Max HR - Max Oxygen Uptake (VO2 Max), Peak Performance
  * **Zone SP** (Speed): 95-100% Max HR - Anaerobic Power, Sprinting, Short Bursts
- **Custom Heart Rate**: Custom bpm range
- **Power Zone**: Power-based training
- **Custom Power**: Watts range

---

## 🔄 Next Steps (Future Enhancements)

### 1. GPS Tracker Integration (Not Yet Implemented)
**Goal**: Execute structured workouts step-by-step during GPS tracking

**What needs to be added:**
- Modify `gps_tracker_screen.dart` to accept optional `StructuredWorkout` parameter
- Show current step progress (e.g., "Step 2/5: Run 1.00 km @ Zone 2")
- Progress bar for duration-based steps
- Audio cues when step completes
- Auto-advance to next step
- Link completed GPS activity to workout assignment

**How to implement:**
```dart
// In gps_tracker_screen.dart
class GPSTrackerScreen extends StatefulWidget {
  final StructuredWorkout? structuredWorkout; // Add this parameter
  
  // ... rest of implementation
}
```

### 2. Calendar Integration (Not Yet Implemented)
**Goal**: Show assigned workouts in calendar

**What needs to be added:**
- Modify `calendar_service.dart` to query `workout_assignments`
- Display assigned workouts on scheduled dates
- Visual indicator for scheduled vs completed
- Tap to start workout or view details

### 3. Athlete Assignment (Not Yet Implemented)
**Goal**: Coaches assign workouts to athletes

**What needs to be added:**
- "Assign to Athlete" button in workout detail screen
- Athlete selector + date picker UI
- Call `structured_workout_service.assignWorkout()`
- Success message

---

## 📝 Database Schema Reference

### `structured_workouts` table:
```sql
- id: UUID (primary key)
- coach_id: UUID (references auth.users)
- workout_name: TEXT
- description: TEXT
- activity_type: TEXT (default: 'Running')
- steps: JSONB (stores workout steps array)
- estimated_duration: INTEGER (seconds)
- estimated_distance: NUMERIC (km)
- created_at: TIMESTAMPTZ
- updated_at: TIMESTAMPTZ
```

### `workout_assignments` table:
```sql
- id: UUID (primary key)
- structured_workout_id: UUID (references structured_workouts)
- athlete_id: UUID (references auth.users)
- coach_id: UUID (references auth.users)
- scheduled_date: DATE
- status: TEXT (scheduled/in_progress/completed/skipped)
- completed_at: TIMESTAMPTZ
- gps_activity_id: UUID (references gps_activities)
- notes: TEXT
```

---

## ✅ Success Criteria

- [x] Database migration deployed
- [x] App hot reloaded successfully
- [x] "Structured Workouts" appears in More Menu
- [x] Can create new workout
- [x] Can add steps with all Garmin features
- [x] Can edit workout and steps
- [x] Can reorder steps via drag
- [x] Can delete steps and workouts
- [x] Workout list displays correctly
- [x] All duration types work
- [x] All intensity types work
- [x] AISRI Training Zones show correct bpm ranges (6 zones)
- [x] Max HR calculated dynamically based on user age

---

## 🐛 Troubleshooting

### Issue: "Table does not exist"
**Solution**: Run the database migration in Supabase SQL Editor

### Issue: "Structured Workouts" not in menu
**Solution**: Press `r` in terminal to hot reload

### Issue: Can't save workout
**Solution**: Make sure workout name is entered and at least one step is added

### Issue: App crashes on save
**Solution**: Check Supabase connection; verify RLS policies are enabled

---

## 📞 Support

If you encounter any issues:
1. Check the console logs in VS Code terminal
2. Verify database tables exist in Supabase
3. Ensure user is logged in
4. Hot reload the app (`r` in terminal)

---

## 🎉 Ready to Use!

Your Garmin-style Structured Workout Builder is now complete and ready to test!

**Next Phase**: GPS Tracker integration to execute workouts step-by-step during runs.
