import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "../services/supabase";
import StatCard from "../components/StatCard";
import BottomNav from "../components/BottomNav";

export default function Dashboard() {
  const navigate = useNavigate();
  const [data, setData] = useState({
    aifriScore: 0,
    riskLevel: "UNKNOWN",
    currentStreak: 0,
    weeklyDistance: 0,
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboardData();
  }, []);

  async function loadDashboardData() {
    try {
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) {
        navigate("/profile");
        return;
      }

      const { data: assessment } = await supabase
        .from("assessments")
        .select("aifri_score, risk_level")
        .eq("athlete_id", user.id)
        .order("created_at", { ascending: false })
        .limit(1)
        .single();

      const weekAgo = new Date();
      weekAgo.setDate(weekAgo.getDate() - 7);
      const { data: activities } = await supabase
        .from("activity_logs")
        .select("distance_km")
        .eq("athlete_id", user.id)
        .gte("activity_date", weekAgo.toISOString().split("T")[0]);

      const weeklyDistance =
        activities?.reduce((sum, a) => sum + (a.distance_km || 0), 0) || 0;

      const { data: allActivities } = await supabase
        .from("activity_logs")
        .select("activity_date")
        .eq("athlete_id", user.id)
        .order("activity_date", { ascending: false });

      let streak = 0;
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      if (allActivities && allActivities.length > 0) {
        const dates = new Set(allActivities.map((a) => a.activity_date));
        let checkDate = new Date(today);
        while (dates.has(checkDate.toISOString().split("T")[0])) {
          streak++;
          checkDate.setDate(checkDate.getDate() - 1);
        }
      }

      setData({
        aifriScore: assessment?.aifri_score || 0,
        riskLevel: assessment?.risk_level || "UNKNOWN",
        currentStreak: streak,
        weeklyDistance,
      });
    } catch (error) {
      console.error("Error loading dashboard:", error);
    } finally {
      setLoading(false);
    }
  }

  function getRiskColor(riskLevel) {
    switch (riskLevel) {
      case "LOW":
        return "bg-green-500";
      case "MODERATE":
        return "bg-yellow-500";
      case "HIGH":
        return "bg-orange-500";
      case "VERY HIGH":
        return "bg-red-500";
      default:
        return "bg-gray-500";
    }
  }

  if (loading)
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );

  return (
    <div className="min-h-screen bg-gray-50 pb-20">
      <div className="bg-gradient-to-r from-primary to-secondary text-white p-6">
        <div className="text-sm opacity-90">Welcome back! 👋</div>
        <div className="text-lg font-semibold mt-1">
          Today {new Date().toLocaleDateString()}
        </div>
      </div>

      <div className="p-4 space-y-4">
        <div
          className={`${getRiskColor(data.riskLevel)} rounded-3xl p-6 text-white shadow-lg`}
        >
          <div className="text-sm opacity-90 mb-2">AIFRI Score</div>
          <div className="text-6xl font-bold mb-2">{data.aifriScore}</div>
          <div className="text-lg font-semibold">{data.riskLevel}</div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <StatCard
            title="Current Streak"
            value={`${data.currentStreak} days`}
            icon="🔥"
          />
          <StatCard
            title="This Week"
            value={`${data.weeklyDistance.toFixed(1)} km`}
            icon="📈"
          />
        </div>

        <div className="space-y-3 mt-6">
          <button
            onClick={() => navigate("/track")}
            className="w-full bg-primary text-white py-4 rounded-xl font-semibold text-lg shadow-lg hover:bg-opacity-90 transition flex items-center justify-center gap-2"
          >
            Start Run 🏃
          </button>
          <button
            onClick={() => navigate("/log")}
            className="w-full bg-white text-primary py-4 rounded-xl font-semibold text-lg border-2 border-primary hover:bg-gray-50 transition flex items-center justify-center gap-2"
          >
            Log Workout ✏️
          </button>
        </div>
      </div>

      <BottomNav active="dashboard" />
    </div>
  );
}
