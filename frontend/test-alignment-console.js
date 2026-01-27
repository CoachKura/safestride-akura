// ============================================
// ALIGNMENT SCORING CONSOLE TEST SUITE
// ============================================
// Copy and paste this into browser console on any page that loads aifri-engine.js

console.clear();
console.log('🧪 Testing Alignment Scoring Integration');
console.log('='.repeat(60));

// Test Case 1: Good Alignment (Expected: ~100, Low Risk)
console.log('\n📊 TEST CASE 1: Good Alignment');
const case1Data = {
    qAngle: 16,
    footPronation: 'neutral',
    pelvisTilt: 'neutral',
    forwardHeadPosture: 'none',
    shoulderSymmetry: 'balanced',
    scoliosis: 'no',
    navicularDrop: 5,
    raceTime5K: '22:00',
    weeklyKm: 30,
    runningYears: 3,
    injuryHistory: '',
    painLevel: 0,
    squats: 40,
    plankSeconds: 90,
    shoulderROM: 85,
    hipROM: 90,
    ankleROM: 85,
    singleLegBalance: 25,
    sitReach: 12
};

try {
    const calc1 = new AIFRICalculator(case1Data);
    const result1 = calc1.calculateAIFRI();
    console.log('✅ Result:', {
        total: result1.total,
        grade: result1.grade.label,
        alignment: result1.pillars.alignment,
        allPillars: result1.pillars
    });
    console.log('Expected: Total ~70-85, Alignment ~95-100');
    console.log('Status:', result1.pillars.alignment >= 95 ? '✅ PASS' : '❌ FAIL');
} catch (error) {
    console.error('❌ Test 1 failed:', error);
}

// Test Case 2: Moderate Issues (Expected: ~64-70, Elevated Risk)
console.log('\n📊 TEST CASE 2: Moderate Alignment Issues');
const case2Data = {
    qAngle: 22,
    footPronation: 'over',
    pelvisTilt: 'anterior',
    forwardHeadPosture: 'moderate',
    shoulderSymmetry: 'left-high',
    scoliosis: 'no',
    navicularDrop: 12,
    raceTime5K: '26:00',
    weeklyKm: 25,
    runningYears: 2,
    injuryHistory: 'knee',
    painLevel: 2,
    squats: 30,
    plankSeconds: 60,
    shoulderROM: 80,
    hipROM: 85,
    ankleROM: 80,
    singleLegBalance: 20,
    sitReach: 10
};

try {
    const calc2 = new AIFRICalculator(case2Data);
    const result2 = calc2.calculateAIFRI();
    console.log('✅ Result:', {
        total: result2.total,
        grade: result2.grade.label,
        alignment: result2.pillars.alignment,
        allPillars: result2.pillars
    });
    console.log('Expected: Total ~60-75, Alignment ~55-70');
    console.log('Status:', result2.pillars.alignment >= 55 && result2.pillars.alignment <= 70 ? '✅ PASS' : '❌ FAIL');
} catch (error) {
    console.error('❌ Test 2 failed:', error);
}

// Test Case 3: Severe Issues (Expected: ~50-60, High Risk)
console.log('\n📊 TEST CASE 3: Severe Alignment Issues');
const case3Data = {
    qAngle: 27,
    footPronation: 'severe-over',
    pelvisTilt: 'severe-anterior',
    forwardHeadPosture: 'severe',
    shoulderSymmetry: 'right-high',
    scoliosis: 'minor',
    navicularDrop: 18,
    raceTime5K: '32:00',
    weeklyKm: 15,
    runningYears: 1,
    injuryHistory: 'knee,ankle,back',
    painLevel: 4,
    squats: 20,
    plankSeconds: 45,
    shoulderROM: 70,
    hipROM: 75,
    ankleROM: 70,
    singleLegBalance: 15,
    sitReach: 8
};

try {
    const calc3 = new AIFRICalculator(case3Data);
    const result3 = calc3.calculateAIFRI();
    console.log('✅ Result:', {
        total: result3.total,
        grade: result3.grade.label,
        alignment: result3.pillars.alignment,
        allPillars: result3.pillars
    });
    console.log('Expected: Total ~40-60, Alignment ~30-55');
    console.log('Status:', result3.pillars.alignment >= 30 && result3.pillars.alignment <= 55 ? '✅ PASS' : '❌ FAIL');
} catch (error) {
    console.error('❌ Test 3 failed:', error);
}

// Test Case 4: Elite Athlete
console.log('\n📊 TEST CASE 4: Elite Athlete Profile');
const case4Data = {
    qAngle: 15,
    footPronation: 'neutral',
    pelvisTilt: 'neutral',
    forwardHeadPosture: 'none',
    shoulderSymmetry: 'balanced',
    scoliosis: 'no',
    navicularDrop: 6,
    raceTime5K: '18:00',
    weeklyKm: 50,
    runningYears: 8,
    injuryHistory: '',
    painLevel: 0,
    squats: 60,
    plankSeconds: 120,
    shoulderROM: 90,
    hipROM: 95,
    ankleROM: 90,
    singleLegBalance: 30,
    sitReach: 15
};

try {
    const calc4 = new AIFRICalculator(case4Data);
    const result4 = calc4.calculateAIFRI();
    console.log('✅ Result:', {
        total: result4.total,
        grade: result4.grade.label,
        alignment: result4.pillars.alignment,
        allPillars: result4.pillars
    });
    console.log('Expected: Total ~82-95, Alignment ~95-100');
    console.log('Status:', result4.total >= 82 && result4.pillars.alignment >= 95 ? '✅ PASS' : '❌ FAIL');
} catch (error) {
    console.error('❌ Test 4 failed:', error);
}

console.log('\n' + '='.repeat(60));
console.log('✅ Alignment scoring test suite complete');
console.log('='.repeat(60));
