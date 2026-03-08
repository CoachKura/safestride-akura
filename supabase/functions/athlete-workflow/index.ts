// @ts-nocheck
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type WorkflowEvent =
  | "signup_completed"
  | "aisri_completed"
  | "strava_connected"
  | "plan_ready"
  | "weekly_progress";

type WorkflowPayload = {
  eventType: WorkflowEvent;
  userId: string;
  email: string;
  fullName?: string;
  aisriScore?: number;
  riskCategory?: string;
  dashboardUrl?: string;
  powerCellsUrl?: string;
};

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

function stepForEvent(eventType: WorkflowEvent): string {
  switch (eventType) {
    case "signup_completed":
      return "awaiting_aisri";
    case "aisri_completed":
      return "awaiting_strava";
    case "strava_connected":
      return "syncing_data";
    case "plan_ready":
      return "active_training";
    case "weekly_progress":
      return "active_training";
  }
}

function templateForEvent(eventType: WorkflowEvent) {
  switch (eventType) {
    case "signup_completed":
      return "welcome";
    case "aisri_completed":
      return "aisri_complete";
    case "strava_connected":
      return "strava_connected";
    case "plan_ready":
      return "plan_ready";
    case "weekly_progress":
      return "weekly_progress";
  }
}

async function invokeSendEmail(baseUrl: string, serviceRoleKey: string, payload: WorkflowPayload) {
  const response = await fetch(`${baseUrl}/functions/v1/send-email`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${serviceRoleKey}`,
      "Content-Type": "application/json",
      apikey: serviceRoleKey,
    },
    body: JSON.stringify({
      userId: payload.userId,
      to: payload.email,
      fullName: payload.fullName,
      templateType: templateForEvent(payload.eventType),
      aisriScore: payload.aisriScore,
      riskCategory: payload.riskCategory,
      dashboardUrl: payload.dashboardUrl,
      powerCellsUrl: payload.powerCellsUrl,
      metadata: { source: "athlete-workflow", eventType: payload.eventType },
    }),
  });

  const body = await response.json().catch(() => ({}));
  return { ok: response.ok, status: response.status, body };
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

    const payload = (await req.json()) as WorkflowPayload;
    if (!payload?.eventType || !payload?.userId || !payload?.email) {
      return json(400, { success: false, error: "eventType, userId and email are required" });
    }

    const nowIso = new Date().toISOString();
    const currentStep = stepForEvent(payload.eventType);

    const updateData: Record<string, unknown> = {
      user_id: payload.userId,
      current_step: currentStep,
      updated_at: nowIso,
    };

    if (payload.eventType === "signup_completed") updateData.signup_completed_at = nowIso;
    if (payload.eventType === "aisri_completed") updateData.aisri_completed_at = nowIso;
    if (payload.eventType === "strava_connected") updateData.strava_connected_at = nowIso;
    if (payload.eventType === "plan_ready") updateData.workout_plan_generated_at = nowIso;

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const { error: statusError } = await supabase
      .from("athlete_onboarding_status")
      .upsert(updateData, { onConflict: "user_id" });

    if (statusError) {
      console.error("athlete_onboarding_status upsert failed", statusError);
    }

    const emailResult = await invokeSendEmail(supabaseUrl, serviceRoleKey, payload);

    return json(200, {
      success: true,
      eventType: payload.eventType,
      nextStep: currentStep,
      onboardingUpdated: !statusError,
      email: emailResult,
    });
  } catch (error) {
    return json(500, {
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});
