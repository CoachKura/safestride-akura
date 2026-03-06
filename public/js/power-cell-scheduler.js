(function () {
  const POWER_CELLS = [
    { code: 'START-01', name: 'START: Run-Walk Basics', protocol: 'START', minAisri: 20, duration: 30, difficulty: 'Beginner', description: 'Gentle run-walk intervals to build consistency.', tags: ['Run-Walk', 'Low Impact'], instructions: ['5 min brisk walk warm-up', '10 x (1 min easy jog + 1 min walk)', '5 min mobility cool-down'] },
    { code: 'ENGINE-01', name: 'ENGINE: Aerobic Builder', protocol: 'ENGINE', minAisri: 35, duration: 40, difficulty: 'Beginner+', description: 'Steady aerobic base development session.', tags: ['Aerobic', 'Base'], instructions: ['8 min dynamic warm-up', '25 min zone-2 steady run', '7 min cooldown walk and stretch'] },
    { code: 'STRENGTH-01', name: 'STRENGTH: Runner Stability', protocol: 'STRENGTH', minAisri: 30, duration: 35, difficulty: 'All Levels', description: 'Bodyweight routine focused on injury prevention.', tags: ['Strength', 'Prehab'], instructions: ['2 rounds glute bridge, split squat, calf raises', 'Core: dead bug + side plank', 'Ankle and hip mobility finish'] },
    { code: 'ZONES-01', name: 'ZONES: Threshold Intro', protocol: 'ZONES', minAisri: 50, duration: 45, difficulty: 'Intermediate', description: 'Controlled threshold blocks to improve stamina.', tags: ['Threshold', 'Pacing'], instructions: ['10 min easy warm-up', '3 x 6 min threshold effort (2 min easy between)', '8 min cool-down'] },
    { code: 'LONG-01', name: 'LONG RUN: Endurance Session', protocol: 'LONG RUN', minAisri: 50, duration: 70, difficulty: 'Intermediate', description: 'Progressive long run for endurance adaptation.', tags: ['Long Run', 'Endurance'], instructions: ['10 min easy start', '45 min steady aerobic pace', 'Last 10 min gentle progression', '5 min cool-down walk'] },
    { code: 'POWER-01', name: 'POWER: Hill Repeats', protocol: 'POWER', minAisri: 65, duration: 50, difficulty: 'Advanced', description: 'Hill intervals for strength and running economy.', tags: ['Power', 'Hills'], instructions: ['10 min warm-up', '8 x 45 sec uphill hard effort (walk down recovery)', 'Strides x 4 on flat', 'Cool-down 10 min'] },
    { code: 'OXYGEN-01', name: 'OXYGEN: VO2 Intervals', protocol: 'OXYGEN', minAisri: 70, duration: 48, difficulty: 'Advanced', description: 'VO2 max workout with strict recoveries.', tags: ['VO2', 'Intervals'], instructions: ['12 min warm-up with drills', '5 x 3 min hard effort / 2 min easy jog', '6 min cool-down and breathing reset'] }
  ];

  const state = {
    aisri: 55,
    schedules: [],
    selectedCell: null,
    supabase: null,
    userId: null
  };

  const el = {
    grid: document.getElementById('pc-grid'),
    totalKpi: document.getElementById('pc-kpi-total'),
    availableKpi: document.getElementById('pc-kpi-available'),
    scheduledKpi: document.getElementById('pc-kpi-scheduled'),
    empty: document.getElementById('pc-empty'),
    detailBackdrop: document.getElementById('pc-detail-backdrop'),
    detailTitle: document.getElementById('pc-detail-title'),
    detailMeta: document.getElementById('pc-detail-meta'),
    detailDesc: document.getElementById('pc-detail-description'),
    detailList: document.getElementById('pc-detail-list'),
    scheduleBackdrop: document.getElementById('pc-schedule-backdrop'),
    scheduleTitle: document.getElementById('pc-schedule-title'),
    scheduleForm: document.getElementById('pc-schedule-form'),
    scheduleDate: document.getElementById('pc-scheduled-date'),
    scheduleTime: document.getElementById('pc-scheduled-time'),
    scheduleNotes: document.getElementById('pc-schedule-notes'),
    toastWrap: document.getElementById('pc-toast-wrap')
  };

  function safeParse(json, fallback) { try { return JSON.parse(json); } catch (_) { return fallback; } }
  function getStoredAisri() { const raw = localStorage.getItem('safestride_aisri_score') || localStorage.getItem('aisri_score'); const n = Number(raw); return (!Number.isNaN(n) && n > 0) ? n : 55; }
  function getSchedulesLocal() { return safeParse(localStorage.getItem('safestride_schedules') || '[]', []); }
  function saveSchedulesLocal() { localStorage.setItem('safestride_schedules', JSON.stringify(state.schedules)); }

  function getSupabaseClient() {
    if (!window.supabase || !window.SAFESTRIDE_CONFIG || !window.SAFESTRIDE_CONFIG.supabase) return null;
    const cfg = window.SAFESTRIDE_CONFIG.supabase;
    if (!cfg.url || !cfg.anonKey || String(cfg.anonKey).includes('YOUR_ACTUAL_KEY_HERE')) return null;
    try { return window.supabase.createClient(cfg.url, cfg.anonKey); } catch (_) { return null; }
  }

  async function initUser() {
    if (!state.supabase) return;
    try {
      const { data } = await state.supabase.auth.getUser();
      if (data && data.user) state.userId = data.user.id;
    } catch (_) { state.userId = null; }
  }

  function getScheduleForCell(cellCode) {
    return state.schedules.find((s) => s.powerCellCode === cellCode && s.status === 'scheduled');
  }

  function render() {
    const cards = POWER_CELLS.map((cell) => {
      const scheduled = getScheduleForCell(cell.code);
      const locked = state.aisri < cell.minAisri;
      const statusClass = scheduled ? 'scheduled' : (locked ? 'locked' : 'available');
      const statusLabel = scheduled ? 'Scheduled' : (locked ? 'Locked' : 'Available');
      const scheduleDisabled = locked ? 'disabled' : '';
      const scheduleLabel = scheduled ? 'Reschedule' : 'Schedule';

      return `
        <article class="pc-card" data-code="${cell.code}">
          <header class="pc-card-head">
            <span class="pc-badge ${statusClass}">${statusLabel}</span>
            <h3 class="pc-name">${cell.name}</h3>
            <div class="pc-meta">Min AISRI ${cell.minAisri} • ${cell.duration} min • ${cell.difficulty}</div>
          </header>
          <div class="pc-body">
            <p class="pc-description">${cell.description}</p>
            <div class="pc-tags">${cell.tags.map((t) => `<span class="pc-tag">${t}</span>`).join('')}</div>
            <div class="pc-meta">${scheduled ? `Scheduled for ${scheduled.scheduledDate} ${scheduled.scheduledTime}` : 'Not scheduled yet'}</div>
            <div class="pc-actions">
              <button class="pc-btn pc-btn-secondary" data-action="details">Details</button>
              <button class="pc-btn pc-btn-primary" data-action="schedule" ${scheduleDisabled}>${scheduleLabel}</button>
            </div>
          </div>
        </article>
      `;
    }).join('');

    el.grid.innerHTML = cards;
    if (el.empty) el.empty.style.display = POWER_CELLS.length ? 'none' : 'block';

    el.totalKpi.textContent = String(POWER_CELLS.length);
    el.availableKpi.textContent = String(POWER_CELLS.filter((c) => state.aisri >= c.minAisri).length);
    el.scheduledKpi.textContent = String(state.schedules.filter((s) => s.status === 'scheduled').length);
  }

  function openBackdrop(backdrop) { backdrop.classList.add('show'); }
  function closeBackdrop(backdrop) { backdrop.classList.remove('show'); }

  function openDetails(cell) {
    el.detailTitle.textContent = cell.name;
    el.detailMeta.textContent = `${cell.protocol} • ${cell.duration} min • Min AISRI ${cell.minAisri}`;
    el.detailDesc.textContent = cell.description;
    el.detailList.innerHTML = cell.instructions.map((x) => `<li>${x}</li>`).join('');
    openBackdrop(el.detailBackdrop);
  }

  function openSchedule(cell) {
    state.selectedCell = cell;
    el.scheduleTitle.textContent = `Schedule: ${cell.name}`;
    const existing = getScheduleForCell(cell.code);
    const defaultDate = new Date().toISOString().split('T')[0];
    el.scheduleDate.value = existing ? existing.scheduledDate : defaultDate;
    el.scheduleTime.value = existing ? existing.scheduledTime : '06:30';
    el.scheduleNotes.value = existing ? existing.notes : '';
    openBackdrop(el.scheduleBackdrop);
  }

  function showToast(message, type) {
    const toast = document.createElement('div');
    toast.className = `pc-toast ${type || 'info'}`;
    toast.textContent = message;
    el.toastWrap.appendChild(toast);
    setTimeout(() => toast.remove(), 2800);
  }

  async function syncScheduleSupabase(schedule) {
    if (!state.supabase || !state.userId) return;
    await state.supabase.from('power_cell_schedules').insert({
      user_id: state.userId,
      power_cell_code: schedule.powerCellCode,
      power_cell_name: schedule.powerCellName,
      scheduled_date: schedule.scheduledDate,
      scheduled_time: schedule.scheduledTime,
      notes: schedule.notes,
      status: schedule.status
    });
  }

  async function onScheduleSubmit(evt) {
    evt.preventDefault();
    if (!state.selectedCell) return;

    const payload = {
      id: crypto.randomUUID(),
      powerCellCode: state.selectedCell.code,
      powerCellName: state.selectedCell.name,
      scheduledDate: el.scheduleDate.value,
      scheduledTime: el.scheduleTime.value,
      notes: el.scheduleNotes.value.trim(),
      status: 'scheduled',
      createdAt: new Date().toISOString()
    };

    state.schedules = state.schedules.filter((s) => !(s.powerCellCode === payload.powerCellCode && s.status === 'scheduled'));
    state.schedules.push(payload);
    saveSchedulesLocal();

    try { await syncScheduleSupabase(payload); } catch (_) { showToast('Saved locally. Supabase sync failed.', 'info'); }

    closeBackdrop(el.scheduleBackdrop);
    render();
    showToast('Workout scheduled successfully.', 'success');
  }

  function handleGridClick(evt) {
    const btn = evt.target.closest('button[data-action]');
    if (!btn) return;
    const card = evt.target.closest('.pc-card');
    if (!card) return;
    const cell = POWER_CELLS.find((c) => c.code === card.getAttribute('data-code'));
    if (!cell) return;
    const action = btn.getAttribute('data-action');
    if (action === 'details') openDetails(cell);
    if (action === 'schedule') openSchedule(cell);
  }

  function wireModalClose(backdrop) {
    backdrop.addEventListener('click', (evt) => {
      if (evt.target === backdrop || evt.target.matches('[data-close-modal]')) closeBackdrop(backdrop);
    });
  }

  async function init() {
    state.aisri = getStoredAisri();
    state.schedules = getSchedulesLocal();
    state.supabase = getSupabaseClient();
    await initUser();

    el.grid.addEventListener('click', handleGridClick);
    el.scheduleForm.addEventListener('submit', onScheduleSubmit);
    wireModalClose(el.detailBackdrop);
    wireModalClose(el.scheduleBackdrop);
    render();
  }

  document.addEventListener('DOMContentLoaded', init);
})();
