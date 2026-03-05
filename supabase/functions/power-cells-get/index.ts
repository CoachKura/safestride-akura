import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type ProtocolOut = {
  id: string | number;
  protocol_name: string;
  display_name: string;
  description: string | null;
  color_hex: string | null;
  icon_class: string | null;
  training_focus: string | null;
  created_at?: string | null;
};

function parseAisriFromMetadata(metadata: Record<string, unknown>): number {
  const candidates = [metadata.aisri, metadata.aisri_score, metadata.aisriScore, metadata.AISRI];
  for (const value of candidates) {
    const numeric = Number(value);
    if (!Number.isNaN(numeric) && Number.isFinite(numeric)) {
      return Math.max(0, Math.min(100, Math.round(numeric)));
    }
  }
  return 0;
}

function normalizeProtocol(protocol: Record<string, unknown> | null | undefined): ProtocolOut {
  const source = protocol ?? {};
  return {
    id: (source.id as string | number) ?? "",
    protocol_name: (source.protocol_name as string) ?? (source.protocol_code as string) ?? "UNKNOWN",
    display_name: (source.display_name as string) ?? "Unknown",
    description: (source.description as string) ?? null,
    color_hex: (source.color_hex as string) ?? null,
    icon_class: (source.icon_class as string) ?? (source.icon_name as string) ?? null,
    training_focus: (source.training_focus as string) ?? null,
    created_at: (source.created_at as string) ?? null,
  };
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json().catch(() => ({}));
    const userId = body?.user_id ?? body?.userId;
    if (!userId || typeof userId !== "string") {
      return new Response(JSON.stringify({ error: "user_id is required" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    if (!supabaseUrl || !serviceRoleKey || !anonKey) {
      return new Response(JSON.stringify({ error: "Missing Supabase environment variables" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      });
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    const accessToken = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : "";
    if (!accessToken) {
      return new Response(JSON.stringify({ error: "Missing bearer token" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 401,
      });
    }

    const authClient = createClient(supabaseUrl, anonKey, {
      global: {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      },
    });

    const { data: authData, error: authTokenError } = await authClient.auth.getUser();
    if (authTokenError || !authData?.user) {
      return new Response(JSON.stringify({ error: "Invalid JWT" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 401,
      });
    }

    if (authData.user.id !== userId) {
      return new Response(JSON.stringify({ error: "Forbidden: user_id must match token subject" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 403,
      });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);
    const { data: authUserData, error: authError } = await supabase.auth.admin.getUserById(userId);
    if (authError || !authUserData?.user) {
      return new Response(JSON.stringify({ error: "User not found" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 404,
      });
    }

    const userAisri = parseAisriFromMetadata((authUserData.user.user_metadata ?? {}) as Record<string, unknown>);

    let protocols: ProtocolOut[] = [];
    let availablePowerCells: Record<string, unknown>[] = [];
    let userHistory: Record<string, unknown>[] = [];

    const { data: protocolsNew, error: protocolsNewErr } = await supabase
      .from("power_cell_protocols")
      .select("id, protocol_name, display_name, description, color_hex, icon_class, training_focus, created_at")
      .order("id", { ascending: true });

    if (!protocolsNewErr) {
      protocols = (protocolsNew ?? []).map((p) => normalizeProtocol(p as Record<string, unknown>));

      const { data: availableNew, error: availableNewErr } = await supabase
        .from("power_cell_types")
        .select(`
          id,
          name,
          protocol_id,
          zone_requirement,
          aisri_minimum,
          duration_minutes,
          intensity,
          description,
          created_at,
          power_cell_protocols!inner(
            id,
            protocol_name,
            display_name,
            description,
            color_hex,
            icon_class,
            training_focus,
            created_at
          )
        `)
        .lte("aisri_minimum", userAisri)
        .order("protocol_id", { ascending: true })
        .order("aisri_minimum", { ascending: true });

      if (availableNewErr) {
        throw new Error(`Failed to load power cells: ${availableNewErr.message}`);
      }

      availablePowerCells = (availableNew ?? []).map((row) => {
        const protocol = normalizeProtocol((row as Record<string, unknown>).power_cell_protocols as Record<string, unknown>);
        return { ...(row as Record<string, unknown>), protocol };
      });

      const { data: historyNew, error: historyNewErr } = await supabase
        .from("user_power_cells")
        .select(`
          id,
          user_id,
          power_cell_type_id,
          scheduled_date,
          completed_at,
          actual_duration_minutes,
          actual_distance_km,
          actual_pace_min_per_km,
          compliance_score,
          strava_activity_id,
          coach_notes,
          created_at,
          power_cell_types(
            id,
            name,
            protocol_id,
            zone_requirement,
            aisri_minimum,
            duration_minutes,
            intensity,
            description,
            created_at,
            power_cell_protocols(
              id,
              protocol_name,
              display_name,
              color_hex,
              icon_class,
              training_focus
            )
          )
        `)
        .eq("user_id", userId)
        .order("scheduled_date", { ascending: false })
        .limit(100);

      if (historyNewErr) {
        throw new Error(`Failed to load user history: ${historyNewErr.message}`);
      }

      userHistory = historyNew ?? [];
    } else {
      const { data: protocolsLegacy, error: protocolsLegacyErr } = await supabase
        .from("power_cell_protocols")
        .select("id, protocol_code, display_name, description, color_hex, icon_name, created_at")
        .order("created_at", { ascending: true });

      if (protocolsLegacyErr) {
        throw new Error(`Failed to load protocols: ${protocolsLegacyErr.message}`);
      }

      protocols = (protocolsLegacy ?? []).map((p) => normalizeProtocol(p as Record<string, unknown>));

      const { data: availableLegacy, error: availableLegacyErr } = await supabase
        .from("power_cell_types")
        .select(`
          id,
          name,
          protocol_id,
          zone_requirement,
          aisri_minimum,
          duration_minutes,
          intensity,
          description,
          created_at,
          power_cell_protocols:protocol_id(
            id,
            protocol_code,
            display_name,
            description,
            color_hex,
            icon_name,
            created_at
          )
        `)
        .eq("is_active", true)
        .lte("aisri_minimum", userAisri)
        .order("aisri_minimum", { ascending: true });

      if (availableLegacyErr) {
        throw new Error(`Failed to load power cells: ${availableLegacyErr.message}`);
      }

      availablePowerCells = (availableLegacy ?? []).map((row) => {
        const record = row as Record<string, unknown>;
        const protocolRecord = Array.isArray(record.power_cell_protocols)
          ? (record.power_cell_protocols[0] as Record<string, unknown>)
          : (record.power_cell_protocols as Record<string, unknown>);
        const protocol = normalizeProtocol(protocolRecord);
        return { ...record, protocol };
      });

      const { data: historyLegacy, error: historyLegacyErr } = await supabase
        .from("user_power_cells")
        .select(`
          id,
          user_id,
          power_cell_type_id,
          scheduled_for,
          completed_at,
          actual_duration_minutes,
          compliance_score,
          strava_activity_id,
          compliance_notes,
          created_at,
          power_cell_types:power_cell_type_id(
            id,
            name,
            protocol_id,
            zone_requirement,
            aisri_minimum,
            duration_minutes,
            intensity,
            description,
            created_at,
            power_cell_protocols:protocol_id(
              id,
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

      if (historyLegacyErr) {
        throw new Error(`Failed to load user history: ${historyLegacyErr.message}`);
      }

      userHistory = (historyLegacy ?? []).map((row) => {
        const record = row as Record<string, unknown>;
        return {
          ...record,
          scheduled_date: record.scheduled_for ?? null,
          coach_notes: record.compliance_notes ?? null,
          actual_distance_km: null,
          actual_pace_min_per_km: null,
        };
      });
    }

    return new Response(
      JSON.stringify({
        available_power_cells: availablePowerCells,
        user_history: userHistory,
        user_aisri: userAisri,
        protocols,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      },
    );
  } catch (error) {
    console.error("power-cells-get error:", error);
    return new Response(
      JSON.stringify({ error: String(error instanceof Error ? error.message : error) }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      },
    );
  }
});
