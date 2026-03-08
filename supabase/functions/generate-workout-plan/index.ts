// @ts-nocheck
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

type Session = {
  date: string;
  time: string;
  power_cell_code: string;
  power_cell_name: string;
  notes: string;
};

function addDays(date: Date, days: number): Date {
  const d = new Date(date);
  d.setDate(d.getDate() + days);
  return d;
}

function toDateOnly(d: Date): string {
  return d.toISOString().split("T")[0];
}

function buildPlan(startDate: Date, weeks: number, aisriScore: number, riskCategory: string): Session[] {
  const sessions: Session[] = [];
  const lowerRisk = riskCategory.toLowerCase().includes("low") || aisriScore >= 70;
  const baseDays = lowerRisk ? [1, 3, 5, 6] : [1, 4, 6];

  for (let w = 0; w < weeks; w++) {
    const weekStart = addDays(startDate, w * 7);

    for (const dayOffset of baseDays) {
      const date = addDays(weekStart, dayOffset);
      const progressive = w + 1;
      const code = dayOffset === 6 ? "RECOVERY" : dayOffset === 1 ? "BASE" : "BUILD";
      const name =
        code === "RECOVERY"
          ? "Power Cell Recovery"
          : code === "BASE"
          ? "Power Cell Base Run"
          : "Power Cell Progressive Load";

      sessions.push({
        date: toDateOnly(date),
        time: dayOffset === 6 ? "07:30:00" : "06:00:00",
        power_cell_code: `${code}_W${progressive}`,
        power_cell_name: name,
        notes: `Week ${progressive} auto-plan (${riskCategory}, AISRI ${aisriScore}).`,
      });
    }
  }

  return sessions;
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json(405, { success: false, error: "Method not allowed" });

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || Deno.env.get("SUPABASE_ANON_KEY") || "";
    if (!supabaseUrl || !serviceRoleKey) {
      return json(500, { success: false, error: "Missing Supabase environment variables" });
    }

    const { userId, weeks = 4, startDate } = await req.json();
    if (!userId) return json(400, { success: false, error: "userId is required" });

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const { data: latestAisri } = await supabase
      .from("aisri_scores")
      .select("total_score, risk_category")
      .eq("athlete_id", userId)
      .order("assessment_date", { ascending: false })
      .limit(1)
      .maybeSingle();

    const aisriScore = Number(latestAisri?.total_score ?? 65);
    const riskCategory = String(latestAisri?.risk_category ?? "Medium Risk");

    // Optional AI hook (kept non-blocking): if OPENAI_API_KEY exists you can enrich notes externally.
    const planStart = startDate ? new Date(startDate) : new Date();
    const sessions = buildPlan(planStart, Number(weeks), aisriScore, riskCategory);

    const rows = sessions.map((s) => ({
      user_id: userId,
      power_cell_code: s.power_cell_code,
      power_cell_name: s.power_cell_name,
      scheduled_date: s.date,
      scheduled_time: s.time,
      notes: s.notes,
      status: "scheduled",
    }));

    const { error: insertError } = await supabase.from("power_cell_schedules").insert(rows);
    if (insertError) {
      return json(500, {
        success: false,
        error: "Failed to store workout plan",
        details: insertError.message,
      });
    }

    await supabase
      .from("athlete_onboarding_status")
      .upsert(
        {
          user_id: userId,
          workout_plan_generated_at: new Date().toISOString(),
          current_step: "active_training",
          updated_at: new Date().toISOString(),
        },
        { onConflict: "user_id" },
      );

    // Trigger plan-ready email.
    const { data: profile } = await supabase
      .from("users")
      .select("email, full_name")
      .eq("id", userId)
      .maybeSingle();

    if (profile?.email) {
      await fetch(`${supabaseUrl}/functions/v1/send-email`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${serviceRoleKey}`,
          "Content-Type": "application/json",
          apikey: serviceRoleKey,
        },
        body: JSON.stringify({
          userId,
          to: profile.email,
          fullName: profile.full_name,
          templateType: "plan_ready",
        }),
      });
    }

    return json(200, {
      success: true,
      weeks: Number(weeks),
      aisriScore,
      riskCategory,
      sessionsGenerated: sessions.length,
      sessions,
    });
  } catch (error) {
    return json(500, {
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});
