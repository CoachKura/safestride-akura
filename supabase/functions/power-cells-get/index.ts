// ============================================================================
// Supabase Edge Function: power-cells-get
// Returns available power cells filtered by latest AISRI score and history
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { userId, profileId } = await req.json();

    if (!userId) {
      throw new Error("userId is required");
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars");
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // Resolve profile id if not supplied
    let resolvedProfileId = profileId;
    if (!resolvedProfileId) {
      const { data: profileRow, error: profileErr } = await supabase
        .from("profiles")
        .select("id")
        .eq("user_id", userId)
        .limit(1)
        .single();

      if (profileErr) {
        throw new Error(`Unable to resolve profile for user: ${profileErr.message}`);
      }
      resolvedProfileId = profileRow.id;
    }

    // Latest AISRI
    const { data: aisriRow, error: aisriErr } = await supabase
      .from("aisri_scores")
      .select("total_score")
      .eq("athlete_id", resolvedProfileId)
      .order("assessment_date", { ascending: false })
      .limit(1)
      .single();

    if (aisriErr) {
      // Fallback to zero if user has no AISRI yet
      console.log("No AISRI score found, using 0", aisriErr.message);
    }

    const currentAisri = aisriRow?.total_score ?? 0;

    // Available cells by AISRI
    const { data: cellRows, error: cellsErr } = await supabase
      .from("power_cell_types")
      .select(`
        id,
        name,
        zone_requirement,
        aisri_minimum,
        duration_minutes,
        intensity,
        description,
        protocol_id,
        power_cell_protocols:protocol_id (
          protocol_code,
          display_name,
          color_hex,
          icon_name
        )
      `)
      .eq("is_active", true)
      .lte("aisri_minimum", currentAisri)
      .order("aisri_minimum", { ascending: true });

    if (cellsErr) {
      throw new Error(`Unable to load power cells: ${cellsErr.message}`);
    }

    // User history
    const { data: historyRows, error: historyErr } = await supabase
      .from("user_power_cells")
      .select(`
        id,
        scheduled_for,
        completed_at,
        status,
        compliance_score,
        actual_duration_minutes,
        strava_activity_id,
        power_cell_type_id,
        power_cell_types:power_cell_type_id (
          id,
          name,
          protocol_id,
          intensity,
          duration_minutes,
          power_cell_protocols:protocol_id (
            protocol_code,
            display_name,
            color_hex,
            icon_name
          )
        )
      `)
      .eq("user_id", userId)
      .order("scheduled_for", { ascending: false })
      .limit(100);

    if (historyErr) {
      throw new Error(`Unable to load user power cell history: ${historyErr.message}`);
    }

    // Group available by protocol
    const grouped: Record<string, unknown[]> = {};
    for (const row of cellRows ?? []) {
      const protocol = row.power_cell_protocols?.protocol_code ?? "UNKNOWN";
      if (!grouped[protocol]) grouped[protocol] = [];
      grouped[protocol].push(row);
    }

    return new Response(
      JSON.stringify({
        success: true,
        userId,
        profileId: resolvedProfileId,
        aisriScore: currentAisri,
        availablePowerCells: cellRows ?? [],
        availableByProtocol: grouped,
        history: historyRows ?? [],
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      },
    );
  } catch (error) {
    console.error("power-cells-get error", error);
    return new Response(
      JSON.stringify({ success: false, error: String(error?.message ?? error) }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      },
    );
  }
});
