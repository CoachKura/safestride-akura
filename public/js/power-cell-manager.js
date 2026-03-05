/* global Chart */

const PowerCellState = {
  sessionToken: "",
  userId: "",
  chart: null,
  protocolsById: new Map(),
  availablePowerCells: [],
  userHistory: [],
  userAisri: 0,
};

function isDev() {
  const env = window.SAFESTRIDE_CONFIG?.environment;
  return env === "development" || window.location.hostname === "localhost";
}

function debugLog(...args) {
  if (isDev()) {
    console.log("[power-cells]", ...args);
  }
}

/**
 * Extracts user session from sessionStorage key safestride_session.
 * Supports either JWT string or JSON object shape.
 * @returns {{ userId: string, token: string } | null}
 */
function getSessionFromStorage() {
  const raw = sessionStorage.getItem("safestride_session");
  if (!raw) return null;

  if (raw.includes(".")) {
    try {
      const payload = JSON.parse(atob(raw.split(".")[1]));
      const userId = payload.sub || payload.user_id || payload.uid || "";
      return userId ? { userId, token: raw } : null;
    } catch (error) {
      debugLog("JWT parse failed", error);
      return null;
    }
  }

  try {
    const obj = JSON.parse(raw);
    const token = obj.access_token || obj.token || "";
    const userId = obj.user?.id || obj.user_id || obj.uid || "";
    return userId && token ? { userId, token } : null;
  } catch (error) {
    debugLog("JSON session parse failed", error);
    return null;
  }
}

/**
 * Loads Power Cell data from the Edge Function.
 * @param {string} userId - Auth user id.
 * @returns {Promise<{available_power_cells: Array, user_history: Array, user_aisri: number, protocols: Array}>}
 */
async function loadPowerCells(userId) {
  const config = window.SAFESTRIDE_CONFIG;
  const baseUrl = config?.supabase?.functionsUrl || config?.api?.functionsUrl;

  if (!baseUrl) {
    throw new Error("Missing functions URL in SAFESTRIDE_CONFIG");
  }

  const response = await fetch(`${baseUrl.replace(/\/$/, "")}/power-cells-get`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      apikey: config?.supabase?.anonKey || "",
      Authorization: `Bearer ${PowerCellState.sessionToken}`,
    },
    body: JSON.stringify({ user_id: userId }),
  });

  const payload = await response.json();
  if (!response.ok) {
    throw new Error(payload?.error || `Failed to load power cells (${response.status})`);
  }

  return payload;
}

function protocolMeta(protocol) {
  return {
    id: protocol.id,
    protocol_name: protocol.protocol_name,
    display_name: protocol.display_name,
    color_hex: protocol.color_hex,
    icon_class: protocol.icon_class,
    description: protocol.description,
  };
}

/**
 * Renders protocol-grouped sections with power cell cards.
 * @param {Array} powerCells - Available power cells from API.
 */
function renderProtocolSections(powerCells) {
  const root = document.getElementById("protocolSections");

  const groups = new Map();
  for (const cell of powerCells) {
    const protocol = Array.isArray(cell.power_cell_protocols)
      ? cell.power_cell_protocols[0]
      : cell.power_cell_protocols;

    const protocolName = protocol?.protocol_name || "UNKNOWN";
    if (!groups.has(protocolName)) {
      groups.set(protocolName, { protocol: protocolMeta(protocol || {}), cells: [] });
    }
    groups.get(protocolName).cells.push(cell);
  }

  if (groups.size === 0) {
    root.innerHTML = "<p class='text-slate-500 text-sm'>No power cells unlocked for your current AISRI yet.</p>";
    return;
  }

  root.innerHTML = Array.from(groups.values()).map(({ protocol, cells }) => {
    const color = protocol.color_hex || "#9333EA";
    const icon = protocol.icon_class || "fa-circle";

    return `
      <section class="protocol-section">
        <header class="protocol-header" style="--protocol-color: ${color}">
          <div class="flex items-center gap-2">
            <i class="fas ${icon}"></i>
            <h3>${protocol.display_name || protocol.protocol_name}</h3>
          </div>
          <span class="text-xs font-semibold bg-white/25 px-2 py-1 rounded-full">${cells.length} cells</span>
        </header>
        <div class="power-cell-grid">
          ${cells.map((cell) => cardTemplate(cell)).join("")}
        </div>
      </section>
    `;
  }).join("");

  root.querySelectorAll("button[data-schedule-cell]").forEach((button) => {
    button.addEventListener("click", async () => {
      const cellId = Number(button.getAttribute("data-schedule-cell"));
      const defaultDate = new Date().toISOString().slice(0, 10);
      const selectedDate = prompt("Schedule date (YYYY-MM-DD)", defaultDate);
      if (!selectedDate) return;

      try {
        await schedulePowerCell(cellId, selectedDate);
        await refreshDashboard();
      } catch (error) {
        showError(error.message || String(error));
      }
    });
  });
}

function cardTemplate(cell) {
  return `
    <article class="power-cell-card">
      <h4 class="font-bold text-slate-900">${cell.name}</h4>
      <p class="text-sm text-slate-600">${cell.description || "No description provided."}</p>
      <div class="flex flex-wrap gap-2 mt-1">
        <span class="zone-badge">Zone ${cell.zone_requirement}</span>
        <span class="intensity-badge intensity-${cell.intensity}">${String(cell.intensity).replace("_", " ")}</span>
      </div>
      <div class="text-sm text-slate-700 mt-1">
        <div><i class="fas fa-clock"></i> ${cell.duration_minutes} min</div>
        <div><i class="fas fa-shield-heart"></i> AISRI ${cell.aisri_minimum}+</div>
      </div>
      <button class="schedule-btn" data-schedule-cell="${cell.id}">Schedule</button>
    </article>
  `;
}

/**
 * Renders a 7-day schedule calendar from user history.
 * @param {Array} history - User power cell history rows.
 */
function renderWeeklySchedule(history) {
  const root = document.getElementById("weeklySchedule");
  const today = new Date();

  const days = [];
  for (let i = 0; i < 7; i++) {
    const date = new Date(today);
    date.setDate(today.getDate() + i);
    const iso = date.toISOString().slice(0, 10);

    const entries = history.filter((row) => row.scheduled_date === iso);
    days.push({ date, iso, entries });
  }

  root.innerHTML = days.map((day) => {
    const items = day.entries.map((entry) => {
      const name = entry.power_cell_types?.name || "Power Cell";
      return `<li>${name}</li>`;
    }).join("");

    return `
      <article class="schedule-day-card">
        <h4>${day.date.toLocaleDateString(undefined, { weekday: "short", month: "short", day: "numeric" })}</h4>
        <ul>${items || "<li class='text-slate-400'>No scheduled cells</li>"}</ul>
      </article>
    `;
  }).join("");
}

/**
 * Renders Chart.js pie chart of protocol distribution from history.
 * @param {Array} history - User history rows.
 */
function renderProtocolChart(history) {
  const counts = new Map();

  for (const row of history) {
    const protocol = row.power_cell_types?.power_cell_protocols;
    const protocolName = Array.isArray(protocol)
      ? protocol[0]?.protocol_name
      : protocol?.protocol_name;

    if (!protocolName) continue;
    counts.set(protocolName, (counts.get(protocolName) || 0) + 1);
  }

  const labels = Array.from(counts.keys());
  const values = labels.map((label) => counts.get(label));
  const colors = labels.map((label) => {
    const protocol = Array.from(PowerCellState.protocolsById.values()).find((p) => p.protocol_name === label);
    return protocol?.color_hex || "#9333EA";
  });

  const ctx = document.getElementById("protocolChart");
  if (PowerCellState.chart) {
    PowerCellState.chart.destroy();
  }

  PowerCellState.chart = new Chart(ctx, {
    type: "pie",
    data: {
      labels,
      datasets: [{
        data: values,
        backgroundColor: colors,
      }],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { position: "bottom" },
      },
    },
  });
}

/**
 * Schedules a power cell for a date.
 * @param {number} cellId - Power cell type id.
 * @param {string} date - ISO date string.
 */
async function schedulePowerCell(cellId, date) {
  const config = window.SAFESTRIDE_CONFIG;
  const endpoint = `${config.supabase.url}/rest/v1/user_power_cells`;

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      apikey: config.supabase.anonKey,
      Authorization: `Bearer ${PowerCellState.sessionToken}`,
      Prefer: "return=minimal",
    },
    body: JSON.stringify({
      user_id: PowerCellState.userId,
      power_cell_type_id: cellId,
      scheduled_date: date,
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Failed to schedule power cell: ${body}`);
  }

  debugLog("Scheduled power cell", { cellId, date });
}

/**
 * Calculates compliance score against target prescription.
 * @param {{moving_time?: number, distance?: number}} stravaActivity - Strava activity data.
 * @param {{duration_minutes?: number}} powerCell - Planned power cell.
 * @returns {number}
 */
function calculateCompliance(stravaActivity, powerCell) {
  const plannedMinutes = Number(powerCell?.duration_minutes || 0);
  const actualMinutes = Number(stravaActivity?.moving_time || 0) / 60;

  if (plannedMinutes <= 0 || actualMinutes <= 0) return 0;

  const delta = Math.abs(actualMinutes - plannedMinutes);
  const score = Math.max(0, 100 - delta * 4);
  return Math.round(score);
}

function setLoading(loading) {
  document.getElementById("loadingState").classList.toggle("hidden", !loading);
}

function showError(message) {
  const root = document.getElementById("errorState");
  document.getElementById("errorMessage").textContent = message;
  root.classList.remove("hidden");
}

function clearError() {
  document.getElementById("errorState").classList.add("hidden");
}

function updateSummary() {
  document.getElementById("aisriValue").textContent = String(PowerCellState.userAisri ?? 0);
  document.getElementById("powerCellCount").textContent = String(PowerCellState.availablePowerCells.length);
  document.getElementById("historyCount").textContent = String(PowerCellState.userHistory.length);
}

async function refreshDashboard() {
  clearError();
  setLoading(true);
  const data = await loadPowerCells(PowerCellState.userId);

  PowerCellState.availablePowerCells = data.available_power_cells || [];
  PowerCellState.userHistory = data.user_history || [];
  PowerCellState.userAisri = data.user_aisri || 0;

  PowerCellState.protocolsById.clear();
  for (const protocol of data.protocols || []) {
    PowerCellState.protocolsById.set(protocol.id, protocol);
  }

  updateSummary();
  renderProtocolSections(PowerCellState.availablePowerCells);
  renderWeeklySchedule(PowerCellState.userHistory);
  renderProtocolChart(PowerCellState.userHistory);
  setLoading(false);
}

document.addEventListener("DOMContentLoaded", async () => {
  const session = getSessionFromStorage();

  if (!session) {
    showError("No active session found. Please log in again.");
    setLoading(false);
    return;
  }

  PowerCellState.userId = session.userId;
  PowerCellState.sessionToken = session.token;

  try {
    await refreshDashboard();
  } catch (error) {
    setLoading(false);
    showError(error.message || String(error));
  }
});

window.loadPowerCells = loadPowerCells;
window.renderProtocolSections = renderProtocolSections;
window.renderWeeklySchedule = renderWeeklySchedule;
window.renderProtocolChart = renderProtocolChart;
window.schedulePowerCell = schedulePowerCell;
window.calculateCompliance = calculateCompliance;
