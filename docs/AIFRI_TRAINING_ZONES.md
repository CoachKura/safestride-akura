# 6 AISRI Training Zones - Technical Reference

## Overview
The SafeStride structured workout system uses the **6 AISRI Training Zones** for heart rate-based intensity targets. These zones are scientifically designed to optimize training across different physiological systems.

---

## Heart Rate Calculation

### Max Heart Rate Formula:
```
Max HR = 208 - (0.7 × Age)
```

**Examples:**
- **20 years old**: 208 - (0.7 × 20) = **194 bpm**
- **30 years old**: 208 - (0.7 × 30) = **187 bpm**
- **40 years old**: 208 - (0.7 × 40) = **180 bpm**
- **50 years old**: 208 - (0.7 × 50) = **173 bpm**
- **60 years old**: 208 - (0.7 × 60) = **166 bpm**

---

## The 6 AISRI Training Zones

### 🔵 Zone AR (Active Recovery)
- **% of Max HR**: 50-60%
- **Purpose**: Recovery, Warm-up, Cool-down
- **Color**: Light Blue
- **When to use**: Easy days, recovery runs, warm-up/cool-down portions
- **Example (40yo, Max HR 180)**: 90-108 bpm

### 🔵 Zone F (Foundation)
- **% of Max HR**: 60-70%
- **Purpose**: Aerobic Base, Fat Burning, Stamina
- **Color**: Blue
- **When to use**: Base building, long easy runs, fat burning workouts
- **Example (40yo, Max HR 180)**: 108-126 bpm

### 🟦 Zone EN (Endurance)
- **% of Max HR**: 70-80%
- **Purpose**: Aerobic Fitness, Improved Oxygen Efficiency
- **Color**: Teal
- **When to use**: Long runs, aerobic development, endurance training
- **Example (40yo, Max HR 180)**: 126-144 bpm

### 🟠 Zone TH (Threshold) ⭐ **CORE ZONE**
- **% of Max HR**: 80-87%
- **Purpose**: Lactate Threshold, Anaerobic Capacity, Speed Endurance
- **Color**: Orange
- **When to use**: Tempo runs, lactate threshold workouts, race pace training
- **Example (40yo, Max HR 180)**: 144-157 bpm
- **Note**: This is the most important training zone for performance improvement

### 🔴 Zone P (Power)
- **% of Max HR**: 87-95%
- **Purpose**: Max Oxygen Uptake (VO2 Max), Peak Performance
- **Color**: Red
- **When to use**: Interval training, VO2 max workouts, high-intensity intervals
- **Example (40yo, Max HR 180)**: 157-171 bpm

### 🔴 Zone SP (Speed)
- **% of Max HR**: 95-100%
- **Purpose**: Anaerobic Power, Sprinting, Short Bursts
- **Color**: Dark Red
- **When to use**: Sprint intervals, short high-intensity bursts, speed work
- **Example (40yo, Max HR 180)**: 171-180 bpm

---

## Implementation in SafeStride

### Dynamic Calculation
The app automatically:
1. Fetches user's date of birth from `athlete_profile` table
2. Calculates current age
3. Computes Max HR using the formula
4. Calculates all 6 zone ranges based on percentages
5. Displays zones with actual bpm ranges during workout creation

### Code Location
- **Model**: `lib/models/structured_workout.dart`
- **UI**: `lib/screens/step_editor_screen.dart`
- **Functions**:
  - `_getMaxHR()` - Calculates max HR
  - `_getHRZoneRange(int zone)` - Returns [min, max] bpm for zone
  - `_getZoneName(int zone)` - Returns zone name
  - `_getZonePurpose(int zone)` - Returns zone description

---

## Zone Selection UI

When creating a workout step with heart rate target, users see:

```
Select AISRI Training Zone: (Max HR: 180 bpm)

🔵 Zone AR (Active Recovery)
   90-108 bpm
   Recovery, Warm-up, Cool-down

🔵 Zone F (Foundation)
   108-126 bpm
   Aerobic Base, Fat Burning, Stamina

🟦 Zone EN (Endurance)
   126-144 bpm
   Aerobic Fitness, Improved Oxygen Efficiency

🟠 Zone TH (Threshold ⭐)
   144-157 bpm
   Lactate Threshold, Anaerobic Capacity, Speed Endurance

🔴 Zone P (Power)
   157-171 bpm
   Max Oxygen Uptake (VO2 Max), Peak Performance

🔴 Zone SP (Speed)
   171-180 bpm
   Anaerobic Power, Sprinting, Short Bursts
```

---

## Training Guidelines by Zone

### Zone Distribution for Different Training Phases:

**Base Building Phase (Off-season)**
- 70% Zone AR + Zone F
- 20% Zone EN
- 10% Zone TH

**Build Phase (Pre-competition)**
- 50% Zone F + Zone EN
- 30% Zone TH (CORE)
- 20% Zone P + Zone SP

**Peak Phase (Competition)**
- 40% Zone EN
- 40% Zone TH (CORE)
- 20% Zone P + Zone SP

**Recovery Phase (Post-race)**
- 90% Zone AR + Zone F
- 10% Zone EN

---

## Example Workouts by Zone

### Easy Recovery Run (Zone AR)
```
Workout: "Recovery Run"
- Warm Up: 5 min (Lap Press, No Target)
- Run: 3.00 km (Distance, Zone AR)
- Cool Down: 5 min (Lap Press, No Target)
```

### Long Base Run (Zone F)
```
Workout: "Sunday Long Run"
- Warm Up: 10 min (Lap Press, No Target)
- Run: 15.00 km (Distance, Zone F)
- Cool Down: 10 min (Lap Press, No Target)
```

### Tempo Run (Zone TH - CORE)
```
Workout: "Tempo Intervals"
- Warm Up: 15 min (Lap Press, No Target)
- Run: 2.00 km (Distance, Zone TH)
- Recovery: 3 min (Time, Zone AR)
- Run: 2.00 km (Distance, Zone TH)
- Recovery: 3 min (Time, Zone AR)
- Run: 2.00 km (Distance, Zone TH)
- Cool Down: 10 min (Lap Press, No Target)
```

### VO2 Max Intervals (Zone P)
```
Workout: "VO2 Max Intervals"
- Warm Up: 20 min (Lap Press, Zone F)
- Run: 800m (Distance, Zone P)
- Recovery: 2 min (Time, Zone AR)
- Repeat 5 times
- Cool Down: 15 min (Lap Press, No Target)
```

### Sprint Intervals (Zone SP)
```
Workout: "Speed Work"
- Warm Up: 20 min (Lap Press, Zone F)
- Run: 200m (Distance, Zone SP)
- Recovery: 90 sec (Time, Zone AR)
- Repeat 8 times
- Cool Down: 10 min (Lap Press, No Target)
```

---

## Benefits of Each Zone

### Zone AR (Active Recovery)
✅ Removes metabolic waste
✅ Promotes blood flow
✅ Accelerates recovery
✅ Maintains aerobic base

### Zone F (Foundation)
✅ Builds aerobic base
✅ Improves fat oxidation
✅ Increases mitochondrial density
✅ Develops capillary network

### Zone EN (Endurance)
✅ Enhances aerobic capacity
✅ Improves oxygen utilization
✅ Builds endurance
✅ Increases glycogen storage

### Zone TH (Threshold) ⭐
✅ Raises lactate threshold
✅ Improves anaerobic capacity
✅ Develops speed endurance
✅ Most effective for performance gains

### Zone P (Power)
✅ Maximizes VO2 max
✅ Improves peak performance
✅ Enhances cardiac output
✅ Develops fast-twitch muscle fibers

### Zone SP (Speed)
✅ Develops anaerobic power
✅ Improves sprint speed
✅ Enhances neuromuscular coordination
✅ Builds explosive strength

---

## Technical Notes

### Database Storage
Heart rate zones are stored in the `structured_workouts` table as part of the JSONB `steps` column:

```json
{
  "id": "step-uuid",
  "stepType": "run",
  "durationType": "distance",
  "durationValue": 1.0,
  "intensityType": "heartRateZone",
  "heartRateZone": 3,
  "targetMin": 126,
  "targetMax": 144,
  "targetDisplay": "Zone EN (Endurance) (126-144 bpm)"
}
```

### User Age Integration
The system fetches `date_of_birth` from `athlete_profile` table:
- If available: Uses actual age for Max HR calculation
- If not available: Defaults to 40 years old (Max HR = 180)

### Future Enhancements
- [ ] Allow manual Max HR override (for athletes who know their actual Max HR)
- [ ] Integrate with GPS tracker for real-time zone feedback
- [ ] Track time spent in each zone per workout
- [ ] Generate zone distribution reports
- [ ] Adjust zones based on heart rate variability (HRV)

---

## References

- Formula source: Tanaka, H., Monahan, K. D., & Seals, D. R. (2001). "Age-predicted maximal heart rate revisited." Journal of the American College of Cardiology.
- AISRI Zone System: Based on scientific research on lactate threshold, VO2 max, and anaerobic capacity training zones.
