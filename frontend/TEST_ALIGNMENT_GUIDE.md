# AIFRI Alignment Scoring Test Guide

## Overview
This guide explains how to test the 6-pillar AIFRI scoring system with the new Alignment pillar (10% weight) that incorporates NASM/ACSM medical validation standards.

---

## Test Files

### 1. **test-alignment-scoring.html** (Browser UI Test Suite)
**Location:** `frontend/test-alignment-scoring.html`

**How to Run:**
1. Open in browser: `file:///path/to/safestride/frontend/test-alignment-scoring.html`
2. Or use Live Server in VS Code (right-click file → "Open with Live Server")
3. View visual test results with color-coded pass/fail indicators

**What it tests:**
- ✅ Test Case 1: Good Alignment (Expected: AIFRI ~70-85, Alignment ~95-100, Low Risk)
- ✅ Test Case 2: Moderate Issues (Expected: AIFRI ~60-75, Alignment ~55-70, Moderate Risk)
- ✅ Test Case 3: Severe Issues (Expected: AIFRI ~40-60, Alignment ~30-55, High Risk)
- ✅ Test Case 4: Elite Athlete (Expected: AIFRI ~82-95, Alignment ~95-100, Low Risk)

**Features:**
- Green terminal-style UI
- Detailed pillar breakdowns
- Pass/fail badges
- Success rate summary
- Console logging for debugging

---

### 2. **test-alignment-console.js** (Console Test Script)
**Location:** `frontend/test-alignment-console.js`

**How to Run:**
1. Open any HTML page that loads `aifri-engine.js` (e.g., `aifri-calculator.html`)
2. Open browser DevTools (F12)
3. Go to Console tab
4. Copy entire contents of `test-alignment-console.js`
5. Paste into console and press Enter

**What it tests:**
- Same 4 test cases as the HTML suite
- Logs detailed results to console
- Shows all 6 pillar scores
- Validates expected ranges

---

## 6-Pillar AIFRI System

### Pillar Weights
| Pillar | Weight | Assessment Focus |
|--------|--------|------------------|
| 🏃 **Running** | 40% | VO2max proxy, weekly mileage, experience, injury history |
| 💪 **Strength** | 15% | Lower body (squats), core endurance (plank) |
| 🔄 **ROM** | 12% | Shoulder, hip, ankle range of motion |
| ⚖️ **Balance** | 13% | Single-leg stability, proprioception |
| 🧘 **Mobility** | 10% | Sit-and-reach, ankle dorsiflexion |
| 🦴 **Alignment** | 10% | Q-angle, foot pronation, pelvic tilt, posture |

### Alignment Pillar Standards (NASM/ACSM)

**Q-Angle:**
- Ideal: 13-18°
- Moderate deviation: <13° or >18° (-15 points)
- Severe deviation: <10° or >20° (-25 points)

**Foot Pronation:**
- Neutral: 0 penalty
- Over/under pronation: -15 points
- Severe over/under: -25 points

**Pelvic Tilt:**
- Neutral: 0 penalty
- Anterior/posterior: -15 points
- Severe: -25 points

**Forward Head Posture:**
- None: 0 penalty
- Mild: -5 points
- Moderate: -10 points
- Severe: -20 points

**Shoulder/Spinal:**
- Asymmetry: -5 points
- Scoliosis (mild): -10 points
- Scoliosis (moderate): -20 points

---

## Expected Test Results

### Test Case 1: Good Alignment
```javascript
Input:
- Q-angle: 16° (ideal)
- Foot pronation: neutral
- Pelvic tilt: neutral
- Forward head: none
- No injuries, good fitness

Expected Output:
- Total AIFRI: 70-85
- Alignment Score: 95-100
- Grade: ADVANCED/ELITE
- Injury Risk: Low
```

### Test Case 2: Moderate Issues
```javascript
Input:
- Q-angle: 22° (outside ideal)
- Foot pronation: over
- Pelvic tilt: anterior
- Forward head: moderate
- 1 previous knee injury

Expected Output:
- Total AIFRI: 60-75
- Alignment Score: 55-70
- Grade: INTERMEDIATE/ADVANCED
- Injury Risk: Moderate-Elevated
```

### Test Case 3: Severe Issues
```javascript
Input:
- Q-angle: 27° (severe deviation)
- Foot pronation: severe over
- Pelvic tilt: severe anterior
- Forward head: severe
- Multiple injuries (knee, ankle, back)

Expected Output:
- Total AIFRI: 40-60
- Alignment Score: 30-55
- Grade: BEGINNER/INTERMEDIATE
- Injury Risk: Elevated-High
```

### Test Case 4: Elite Athlete
```javascript
Input:
- Q-angle: 15° (optimal)
- All alignment metrics perfect
- 50km/week, 8 years experience
- Fast 5K time (18:00)
- No injuries

Expected Output:
- Total AIFRI: 82-95
- Alignment Score: 95-100
- Grade: ELITE
- Injury Risk: Low
```

---

## Validation Checklist

When running tests, verify:

- [ ] All 6 pillars display correctly (Running, Strength, ROM, Balance, Mobility, Alignment)
- [ ] Alignment scores match expected ranges for each test case
- [ ] Total AIFRI scores fall within expected ranges
- [ ] Grade labels are appropriate (ELITE, ADVANCED, INTERMEDIATE, BEGINNER, NOVICE)
- [ ] No JavaScript errors in console
- [ ] All 4 test cases pass (✅ PASS badges)

---

## Troubleshooting

### Issue: "AIFRICalculator is not defined"
**Solution:** Ensure `aifri-engine.js` is loaded before running tests
```html
<script src="js/aifri-engine.js"></script>
```

### Issue: Alignment scores seem too high/low
**Solution:** Check input data format matches these fields:
- `qAngle` (number: 8-30)
- `footPronation` (string: 'neutral', 'over', 'under', 'severe-over', 'severe-under')
- `pelvisTilt` (string: 'neutral', 'anterior', 'posterior', 'severe-anterior', 'severe-posterior')
- `forwardHeadPosture` (string: 'none', 'mild', 'moderate', 'severe')
- `scoliosis` (string: 'no', 'minor', 'yes')
- `navicularDrop` (number: 0-30mm)

### Issue: Tests fail with calculation errors
**Solution:** Verify all required fields are present in test data:
- Running: `raceTime5K`, `weeklyKm`, `runningYears`
- Strength: `squats`, `plankSeconds`
- ROM: `shoulderROM`, `hipROM`, `ankleROM`
- Balance: `singleLegBalance`
- Mobility: `sitReach`

---

## Integration Notes

The alignment scoring is integrated into:
- ✅ `aifri-engine.js` - `calculateAlignmentScore()` method
- ✅ `chart-utils.js` - 6-pillar donut chart visualization
- ✅ `athlete-dashboard.html` - Pillar progress cards
- ✅ `training-plans.html` - Protocol milestone tracking
- ✅ `coach-dashboard.html` - Multi-athlete alignment monitoring

---

## Next Steps

After tests pass:
1. Update assessment-intake.html form to collect alignment data
2. Add Q-angle measurement guide
3. Create foot pronation visual assessment
4. Implement pelvic tilt screening
5. Add posture photography uploads (optional)

---

**Last Updated:** January 27, 2026
**Version:** 6-Pillar AIFRI System v2.0
