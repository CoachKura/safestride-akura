import { useState } from "react";
import { offlineInsert } from "../services/supabase";

export default function WorkoutLogger() {
  const [activityType, setActivityType] = useState("Run");
  const [distance, setDistance] = useState(0);
  const [duration, setDuration] = useState(0);
  const [rpe, setRpe] = useState(6);
  const [notes, setNotes] = useState("");
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState(null);

  const user = { id: "anon" };

  const valid = parseFloat(distance) > 0 && parseInt(duration) > 0;

  const pace = () => {
    const d = parseFloat(distance) || 0;
    const m = parseInt(duration) || 0;
    if (d <= 0) return "--";
    const secPerKm = (m * 60) / d;
    const mm = Math.floor(secPerKm / 60);
    const ss = Math.round(secPerKm % 60)
      .toString()
      .padStart(2, "0");
    return `${mm}:${ss}`;
  };

  async function handleSave(e) {
    e.preventDefault();
    if (!valid) {
      setMessage({ type: "error", text: "Distance and duration must be > 0" });
      return;
    }

    setSaving(true);
    const payload = {
      athlete_id: user.id,
      activity_date: new Date().toISOString().slice(0, 10),
      distance_km: parseFloat(distance),
      duration_minutes: parseInt(duration),
      activity_type: activityType,
      rpe: parseInt(rpe),
      notes: notes || null,
      gps_data: null
    };

    try {
      const { queued, error } = await offlineInsert("activity_logs", payload);
      if (error) {
        console.error("❌ Supabase insert error:", error);
        setMessage({ type: "error", text: "Failed to save — queued locally." });
      } else if (queued) {
        setMessage({ type: "info", text: "⚡ Offline — saved locally" });
      } else {
        setMessage({ type: "success", text: "✅ Saved workout" });
        setDistance(0);
        setDuration(0);
        setNotes("");
        setRpe(6);
        setActivityType("Run");
      }
    } catch (err) {
      console.error(err);
      setMessage({ type: "error", text: "Unexpected error — saved locally." });
    } finally {
      setSaving(false);
      setTimeout(() => setMessage(null), 3000);
    }
  }

  return (
    <div className="min-h-screen p-4 bg-gradient-to-b from-purple-600 to-pink-600">
      <div className="max-w-md mx-auto bg-white p-6 rounded-xl shadow-lg border-2 border-gray-200">
        <h2 className="text-2xl font-bold mb-4">Log Workout</h2>
        <form onSubmit={handleSave} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Activity</label>
            <select
              value={activityType}
              onChange={(e) => setActivityType(e.target.value)}
              className="w-full p-4 border-2 border-gray-200 rounded-xl mt-2 focus:border-purple-500 focus:ring-2 focus:ring-purple-200"
            >
              <option>Run</option>
              <option>Walk</option>
              <option>Strength</option>
              <option>Yoga</option>
              <option>Cycling</option>
              <option>Swimming</option>
              <option>Other</option>
            </select>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm font-medium text-gray-700">Distance (km)</label>
              <input
                inputMode="decimal"
                step="0.01"
                value={distance}
                onChange={(e) => setDistance(e.target.value)}
                className="w-full p-4 border-2 border-gray-200 rounded-xl mt-2"
                placeholder="e.g. 5.25"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Duration (min)</label>
              <input
                inputMode="numeric"
                value={duration}
                onChange={(e) => setDuration(e.target.value)}
                className="w-full p-4 border-2 border-gray-200 rounded-xl mt-2"
                placeholder="e.g. 30"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">RPE: {rpe}</label>
            <input
              type="range"
              min="0"
              max="10"
              value={rpe}
              onChange={(e) => setRpe(e.target.value)}
              className="w-full mt-2"
            />
            <div className="flex justify-between text-xs text-gray-500 mt-1">
              <span>Rest</span>
              <span>Very Easy</span>
              <span>Easy</span>
              <span>Moderate</span>
              <span>Hard</span>
              <span>Max</span>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">Notes</label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              className="w-full p-4 border-2 border-gray-200 rounded-xl mt-2 h-24"
              placeholder="Optional notes"
            />
          </div>

          <div className="flex items-center justify-between">
            <div>
              <div className="text-sm text-gray-500">Pace</div>
              <div className="text-xl font-bold">{pace()}</div>
            </div>
            <button
              type="submit"
              disabled={!valid || saving}
              className="bg-gradient-to-r from-purple-600 to-pink-600 text-white font-bold py-3 px-6 rounded-xl shadow-lg hover:shadow-xl transition-all transform hover:scale-105 min-h-[44px]"
            >
              {saving ? "Saving..." : "Save"}
            </button>
          </div>
        </form>

        {message && (
          <div className={`mt-4 p-3 rounded-lg ${message.type === 'error' ? 'bg-red-100 text-red-700' : message.type === 'success' ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'}`}>
            {message.text}
          </div>
        )}
      </div>
    </div>
  );
}
