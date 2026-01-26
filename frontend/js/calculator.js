// AIFRI Calculator Logic
// PILLAR WEIGHTS: Running 40, Strength 20, ROM 15, Balance 15, Mobility 10
// Inputs come from the multi-step form fields in aifri-calculator.html

function nextStep(step) {
    document.querySelectorAll('.calculator-step').forEach(s => s.style.display = 'none');
    document.getElementById(`step${step}`).style.display = 'block';
}

function prevStep(step) {
    document.querySelectorAll('.calculator-step').forEach(s => s.style.display = 'none');
    document.getElementById(`step${step}`).style.display = 'block';
}

function calculateAIFRI() {
    // Step 1: Demographics
    const age = getNumber('age');
    const restingHR = getNumber('restingHR');
    let maxHR = getNumber('maxHR');
    if (!maxHR) {
        maxHR = Math.round(208 - (0.7 * age)); // Tanaka formula
    }

    // Step 3: Running Performance
    const weeklyKm = clamp(getNumber('weeklyKm'), 0, 200);
    const squats = clamp(getNumber('squats'), 0, 50);
    const injuries = getNumber('injuryHistory');
    const pain = getNumber('painLevel');

    // Step 4: Biomechanics & Flexibility (real measurements)
    const ankleFlexibility = clamp(getNumber('ankleFlexibility'), 0, 45);
    const hipFlexibility = clamp(getNumber('hipFlexibility'), -20, 50);
    const singleLegBalance = clamp(getNumber('singleLegBalance'), 0, 300);
    const plankTime = clamp(getNumber('coreStrength'), 0, 600);
    const fmsScore = clamp(getNumber('fmsScore'), 0, 21);

    // PILLAR 1: RUNNING (40 points) - with penalties
    const runningScore = Math.max(0, Math.min(40, (weeklyKm / 80) * 40) - (injuries * 2) - pain);

    // PILLAR 2: STRENGTH (20 points) - squats + plank split
    const strengthScore = (squats / 50) * 10 + (plankTime / 120) * 10;

    // PILLAR 3: ROM (15 points) - FMS based
    const romScore = (fmsScore / 21) * 15;

    // PILLAR 4: BALANCE (15 points) - single leg balance seconds
    const balanceScore = Math.min(15, (singleLegBalance / 60) * 15);

    // PILLAR 5: MOBILITY (10 points) - ankle + hip
    const ankleScore = (ankleFlexibility / 45) * 5; // max 5
    const hipScore = ((hipFlexibility + 20) / 70) * 5; // range -20..+50 mapped to 0..5
    const mobilityScore = Math.max(0, Math.min(10, ankleScore + hipScore));

    const aifriScore = runningScore + strengthScore + romScore + balanceScore + mobilityScore;

    renderResults({
        aifriScore,
        maxHR,
        restingHR,
        pillars: {
            Running: runningScore,
            Strength: strengthScore,
            ROM: romScore,
            Balance: balanceScore,
            Mobility: mobilityScore
        },
        zones: computeHrZones(maxHR, restingHR)
    });

    nextStep('results');
}

function computeHrZones(maxHR, restingHR) {
    const reserve = maxHR - restingHR;
    const zone = (low, high) => ({
        low: Math.round(restingHR + reserve * low),
        high: Math.round(restingHR + reserve * high)
    });
    return [
        { name: 'Zone 1: Recovery', ...zone(0.5, 0.6) },
        { name: 'Zone 2: Easy', ...zone(0.6, 0.7) },
        { name: 'Zone 3: Tempo', ...zone(0.7, 0.8) },
        { name: 'Zone 4: Threshold', ...zone(0.8, 0.9) },
        { name: 'Zone 5: VO2 Max', ...zone(0.9, 0.95) },
        { name: 'Zone 6: Repetition', ...zone(0.95, 1.0) },
    ];
}

function renderResults({ aifriScore, maxHR, restingHR, pillars, zones }) {
    document.getElementById('totalScore').textContent = Math.round(aifriScore);
    document.getElementById('displayMaxHR').textContent = maxHR;
    document.getElementById('displayRestingHR').textContent = restingHR;

    const category = aifriScore >= 80 ? 'Excellent' : aifriScore >= 60 ? 'Good' : 'Needs Improvement';
    document.getElementById('scoreCategory').textContent = category;

    const pillarsEl = document.getElementById('pillarsBreakdown');
    pillarsEl.innerHTML = '';
    Object.entries(pillars).forEach(([name, val]) => {
        const bar = document.createElement('div');
        bar.className = 'pillar-bar';
        bar.style.setProperty('--pillar-width', `${Math.min(100, (val / 40) * 100)}%`);
        bar.innerHTML = `<span>${name}</span><strong>${val.toFixed(1)} pts</strong>`;
        pillarsEl.appendChild(bar);
    });

    const zonesEl = document.getElementById('hrZones');
    zonesEl.innerHTML = zones.map(z => `<div class="zone-row"><span>${z.name}</span><span>${z.low}-${z.high} bpm</span></div>`).join('');
}

function getNumber(id) {
    const el = document.getElementById(id);
    if (!el) return 0;
    const v = parseFloat(el.value);
    return isNaN(v) ? 0 : v;
}

function clamp(v, min, max) {
    return Math.max(min, Math.min(max, v));
}

function resetCalculator() {
    document.querySelectorAll('input').forEach(i => i.value = '');
    document.getElementById('results').style.display = 'none';
    document.getElementById('step1').style.display = 'block';
}

function saveResults() {
    window.print(); // simple placeholder
}

function printResults() {
    window.print();
}
