# AKURA SafeStride - Frontend Testing Guide

**Purpose:** Verify frontend correctly formats API requests before backend integration

**Status:** Backend API spec complete, frontend code complete, testing pending

---

## 🎯 Testing Objectives

1. Verify frontend sends correctly formatted requests
2. Confirm offline fallbacks work (localStorage caching)
3. Validate AIFRI calculation matches expected range
4. Ensure UI updates correctly (loading states, success/error messages)

---

## ⚡ Quick Test (5 Minutes)

### Prerequisites
- Local server running on http://localhost:5502
- Browser with DevTools (Chrome/Edge/Firefox)

### Steps

1. **Start Server** (if not running):
```bash
cd "e:\Akura Safe Stride\safestride\frontend"
npx http-server -p 5502 -c-1
```

2. **Open Browser:**
- Navigate to: http://localhost:5502/assessment-intake.html
- Press F12 (open DevTools)
- Click Console tab

3. **Check if api-client.js is loaded:**
```javascript
console.log('API client loaded:', typeof submitAssessment !== 'undefined');
```

If it returns `false`:
```javascript
const script = document.createElement('script');
script.src = 'js/api-client.js';
document.head.appendChild(script);
console.log('Wait 2 seconds and re-check...');
```

4. **Run Consolidated Test Suite:**

Paste this entire block into console:

```javascript
// ============================================
// AKURA BACKEND INTEGRATION - FULL TEST SUITE
// ============================================

console.clear();
console.log('🧪 AKURA SafeStride - Backend Integration Test Suite');
console.log('Timestamp:', new Date().toISOString());
console.log('Browser:', navigator.userAgent.split(' ').slice(-2).join(' '));
console.log('Online:', navigator.onLine);
console.log('='.repeat(80));

// Test data
const mockAssessment = {
  personal: { name: "Test Athlete", age: 47, gender: "male", height: 169, weight: 82, email: "test@akura.in", phone: "1234567890" },
  medical: { injuries: ["knee"], conditions: [], medications: "None", surgeries: "None" },
  alignment: { bodyType: "mesomorph", qAngle: 172, footPronation: "neutral", pelvicTilt: "neutral", forwardHead: "normal" },
  rom: { cervical: 75, shoulder: 85, hip: 90, knee: 92, ankle: 85 },
  fms: { deepSquat: 2, hurdleStep: 2, inlineLunge: 2, shoulderMobility: 2, legRaise: 2, pushUp: 2, rotaryStability: 2, totalScore: 14 },
  strength: { plankHold: 90, singleLegBalance: 25, calfRaises: 20, singleLegSquat: "good" },
  balance: { singleLegEyesOpen: 25, singleLegEyesClosed: 10, fmsTotal: 14 },
  mobility: { sitReach: 12, ankleDorsiflex: 11, hipFlexor: "normal" },
  running: { weeklyMileage: 30, longRun: 12, easyPace: "6:00", tempoPace: "5:30", vdot: 45, recentRace: "10K in 45:00" },
  goals: { primary: "injury-prevention", targetRace: "Half Marathon", targetDate: "2026-06-01", experience: "intermediate" }
};

const mockFeedback = {
  completed: 'yes',
  rpe: 7,
  pain: 2,
  painLocation: 'knee',
  sleep: 7.5,
  nutrition: 2200,
  stress: 4,
  notes: 'Felt good overall, slight knee discomfort'
};

let testResults = {
  flow1: { pass: false, error: null },
  flow2: { pass: false, error: null },
  flow3: { pass: false, error: null }
};

// FLOW 1: ASSESSMENT
console.log('\n📊 FLOW 1: Assessment Submission');
console.log('-'.repeat(80));

try {
  const aifriScore = calculateAIFRIScore(mockAssessment);
  console.log('✅ AIFRI calculation:', aifriScore);
  
  if (aifriScore >= 60 && aifriScore <= 90) {
    console.log('✅ Score in expected range (60-90)');
    testResults.flow1.pass = true;
  } else {
    console.warn('⚠️ Score outside expected range:', aifriScore);
  }
  
  mockAssessment.aifriScore = aifriScore;
  
} catch (error) {
  console.error('❌ AIFRI calculation FAILED:', error.message);
  testResults.flow1.error = error.message;
}

console.log('\n📤 Submitting assessment to backend...');
submitAssessment(mockAssessment)
  .then(r => console.log('✅ Backend SUCCESS (unexpected):', r))
  .catch(e => {
    console.log('⚠️ Backend ERROR (expected):', e.message);
    const cached = localStorage.getItem('pendingAssessment');
    if (cached) {
      console.log('✅ localStorage cache: WORKING');
      console.log('   Cached athlete:', JSON.parse(cached).data.personal.name);
      testResults.flow1.pass = true;
    } else {
      console.error('❌ localStorage cache: NOT WORKING');
      testResults.flow1.error = 'localStorage not caching';
    }
  });

// FLOW 2: PROTOCOL
setTimeout(() => {
  console.log('\n📥 FLOW 2: Protocol Retrieval');
  console.log('-'.repeat(80));
  
  const testProtocolId = 'test_' + Date.now();
  localStorage.setItem('protocolId', testProtocolId);
  localStorage.setItem('aifriScore', '76');
  
  getTrainingProtocol(testProtocolId)
    .then(p => {
      console.log('✅ Protocol fetch: SUCCESS');
      console.log('   Weeks:', p.weeks?.length || 0);
      console.log('   Daily:', p.daily?.length || 0);
      console.log('   Risk:', p.injuryRisk);
      
      if (p.weeks && p.daily && p.injuryRisk) {
        testResults.flow2.pass = true;
        const cached = localStorage.getItem('protocol_' + testProtocolId);
        console.log('✅ localStorage cache:', cached ? 'WORKING' : 'NOT WORKING');
      }
    })
    .catch(e => {
      console.error('❌ Protocol fetch FAILED:', e.message);
      testResults.flow2.error = e.message;
    });
}, 2000);

// FLOW 3: FEEDBACK
setTimeout(() => {
  console.log('\n📤 FLOW 3: Workout Feedback');
  console.log('-'.repeat(80));
  
  const workoutId = 'workout_test_day1';
  
  submitWorkoutFeedback(workoutId, mockFeedback)
    .then(r => console.log('✅ Feedback SUCCESS (unexpected):', r))
    .catch(e => {
      console.log('⚠️ Feedback ERROR (expected):', e.message);
      const pending = JSON.parse(localStorage.getItem('pendingFeedback') || '[]');
      const cached = pending.some(item => item.workoutId === workoutId);
      
      if (cached) {
        console.log('✅ localStorage cache: WORKING');
        console.log('   Cached items:', pending.length);
        testResults.flow3.pass = true;
      } else {
        console.error('❌ localStorage cache: NOT WORKING');
        testResults.flow3.error = 'Feedback not cached';
      }
    });
}, 4000);

// SUMMARY
setTimeout(() => {
  console.log('\n' + '='.repeat(80));
  console.log('📋 TEST SUMMARY');
  console.log('='.repeat(80));
  
  console.log('\nFlow 1 (Assessment):', testResults.flow1.pass ? '✅ PASS' : '❌ FAIL');
  if (testResults.flow1.error) console.log('   Error:', testResults.flow1.error);
  
  console.log('\nFlow 2 (Protocol):', testResults.flow2.pass ? '✅ PASS' : '❌ FAIL');
  if (testResults.flow2.error) console.log('   Error:', testResults.flow2.error);
  
  console.log('\nFlow 3 (Feedback):', testResults.flow3.pass ? '✅ PASS' : '❌ FAIL');
  if (testResults.flow3.error) console.log('   Error:', testResults.flow3.error);
  
  const allPass = testResults.flow1.pass && testResults.flow2.pass && testResults.flow3.pass;
  
  console.log('\n' + '='.repeat(80));
  console.log('OVERALL:', allPass ? '✅ ALL TESTS PASSED' : '❌ SOME TESTS FAILED');
  console.log('='.repeat(80));
  
  if (allPass) {
    console.log('\n🎉 Backend integration ready!');
  } else {
    console.log('\n⚠️ Copy this entire output and report issues.');
  }
}, 6000);
```

5. **Wait 6 seconds** for all tests to complete

6. **Copy the entire console output** (from "🧪 AKURA SafeStride..." to "OVERALL: ✅/❌")

---

## 📋 Visual Verification (Manual)

### Test Flow 2: Training Plans Page

1. Navigate to: http://localhost:5502/training-plans.html?protocolId=test123

2. Visual checks:
   - [ ] "Your 90-Day Adaptive Protocol" header visible
   - [ ] AIFRI Score badge shows number
   - [ ] Weekly plan cards visible (Week 1, Week 2, etc.)
   - [ ] Daily workouts visible (Day 1, Day 2, etc.)
   - [ ] Injury risk alert box visible

3. Console check:
   - [ ] No red errors (except expected "Failed to fetch")
   - [ ] "✅ Protocol loaded" or "⚠️ Using cached data"

### Test Flow 3: Feedback Form

1. Navigate to: http://localhost:5502/athlete-dashboard.html

2. Scroll to "Daily Workout Feedback" section

3. Fill form:
   - Completed: Yes
   - RPE: 7
   - Pain: 2
   - Pain Location: Knee
   - Sleep: 7.5
   - Nutrition: 2200
   - Stress: 4
   - Notes: "Test feedback"

4. Click "Submit Feedback"

5. Expected:
   - [ ] Loading spinner appears
   - [ ] Success message OR offline banner shows
   - [ ] No JavaScript errors in console

### Test Offline Mode

1. On athlete-dashboard.html

2. DevTools → Network tab → Check "Offline"

3. Fill and submit feedback form

4. Expected:
   - [ ] Offline banner appears
   - [ ] "Feedback saved locally" message
   - [ ] Data cached in localStorage

5. Uncheck "Offline" (reconnect)

6. Expected:
   - [ ] Auto-sync banner (if implemented)
   - [ ] No errors

---

## 📤 Reporting Results

After running tests, paste results in this format:

```
=== CONSOLIDATED TEST RESULTS ===

Date/Time: [timestamp]
Browser: Chrome/Edge/Firefox [version]

--- CONSOLE OUTPUT ---
[paste entire console output from test suite]

--- VISUAL VERIFICATION ---
Training Plans Page:
- Protocol header visible: YES / NO
- AIFRI badge visible: YES / NO (value: ___)
- Weekly cards visible: YES / NO (count: ___)
- Daily workouts visible: YES / NO (count: ___)
- Injury alert visible: YES / NO

Athlete Dashboard:
- Feedback form visible: YES / NO
- Submit button works: YES / NO
- Success/error message: [describe]
- Offline banner: YES / NO

--- ISSUES FOUND ---
[List any errors or unexpected behavior]

--- READY TO PROCEED ---
YES - All tests passed
NO - Need debugging: [describe issues]
```

---

## 🐛 Common Issues & Solutions

### Issue: "calculateAIFRIScore is not defined"
**Solution:**
```javascript
const script = document.createElement('script');
script.src = 'js/api-client.js';
document.head.appendChild(script);
// Wait 2 seconds, re-run test
```

### Issue: "Training plans page is blank"
**Check:**
- [ ] URL has protocolId parameter
- [ ] Console shows protocol loading logs
- [ ] No 404 errors for CSS/JS files

**Solution:**
```javascript
// In console:
console.log('Protocol ID:', new URLSearchParams(window.location.search).get('protocolId'));
console.log('Cached protocol:', localStorage.getItem('protocolId'));
```

### Issue: "Feedback not cached in localStorage"
**Check:**
```javascript
// In console:
console.log('Pending feedback:', localStorage.getItem('pendingFeedback'));
```

**Solution:** Check if `submitWorkoutFeedback` function exists and catch block has localStorage code

---

## ✅ Expected Test Results

### PASS Criteria

**Flow 1: Assessment Submission**
- ✅ AIFRI score: 70-85 range
- ⚠️ Backend submission: ERROR (expected)
- ✅ localStorage cache: WORKING
- ✅ Cached athlete name: "Test Athlete"

**Flow 2: Protocol Retrieval**
- ⚠️ Backend fetch: ERROR (expected)
- ✅ Mock protocol generated
- ✅ Weeks: 2+ (from mock)
- ✅ Daily: 7+ (from mock)
- ✅ Injury risk: "Moderate"
- ✅ localStorage cache: WORKING

**Flow 3: Workout Feedback**
- ⚠️ Backend submission: ERROR (expected)
- ✅ localStorage cache: WORKING
- ✅ Cached feedback items: 1+

**Overall:** ✅ ALL TESTS PASSED

---

## 🚀 After Testing

### If All Tests Pass

1. Copy console output
2. Confirm in Slack/email: "Frontend tests passed"
3. Backend team can start implementation
4. You can test UI/UX in parallel

### If Tests Fail

1. Copy full console output
2. Report issues with exact error messages
3. We'll debug together
4. Re-test after fixes

---

## 📞 Support

Need help running tests?
- Paste error messages in chat
- Share screenshots if needed
- I'll provide step-by-step debugging

---

**Generated:** January 27, 2026
**Version:** 1.0.0
**Status:** Ready for Testing
