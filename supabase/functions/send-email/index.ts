// @ts-nocheck
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type TemplateType =
  | "welcome"
  | "aisri_complete"
  | "strava_connected"
  | "plan_ready"
  | "weekly_progress";

type SendEmailPayload = {
  userId?: string;
  to: string;
  templateType?: TemplateType;
  subject?: string;
  html?: string;
  fullName?: string;
  aisriScore?: number;
  riskCategory?: string;
  dashboardUrl?: string;
  powerCellsUrl?: string;
  metadata?: Record<string, unknown>;
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

function buildTemplate(payload: SendEmailPayload): { subject: string; html: string; type: string } {
  const name = payload.fullName || "Athlete";
  const dashboardUrl = payload.dashboardUrl || "https://production.safestride.pages.dev/coach-dashboard.html";
  const powerCellsUrl = payload.powerCellsUrl || "https://production.safestride.pages.dev/power-cells.html";

  switch (payload.templateType) {
    case "welcome":
      return {
        type: "welcome",
        subject: "Welcome to Safestride",
        html: `<h2>Welcome, ${name}</h2><p>Your account is active. Start with AISRI to get your baseline.</p><p><a href="${dashboardUrl}">Open Dashboard</a></p>`,
      };
    case "aisri_complete":
      return {
        type: "aisri_complete",
        subject: "AISRI Complete - Connect Strava Next",
        html: `<h2>AISRI Completed</h2><p>Hi ${name}, your AISRI score is <b>${payload.aisriScore ?? "N/A"}</b> (${payload.riskCategory ?? "Unclassified"}).</p><p>Next step: connect Strava so we can personalize your plan.</p><p><a href="${dashboardUrl}">Continue Setup</a></p>`,
      };
    case "strava_connected":
      return {
        type: "strava_connected",
        subject: "Strava Connected - We are analyzing your data",
        html: `<h2>Strava Connected</h2><p>Great job ${name}. We are now analyzing your recent activities and training load.</p><p><a href="${dashboardUrl}">Track Progress</a></p>`,
      };
    case "plan_ready":
      return {
        type: "plan_ready",
        subject: "Your 4-week workout plan is ready",
        html: `<h2>Plan Ready</h2><p>${name}, your personalized 4-week plan is now available.</p><p><a href="${powerCellsUrl}">Open Power Cells</a></p><p><a href="${dashboardUrl}">Open Dashboard</a></p>`,
      };
    case "weekly_progress":
      return {
        type: "weekly_progress",
        subject: "Weekly progress check-in",
        html: `<h2>Weekly Check-in</h2><p>Hi ${name}, keep momentum by reviewing your latest sessions and updating your status.</p><p><a href="${dashboardUrl}">Review Weekly Progress</a></p>`,
      };
    default:
      return {
        type: payload.templateType || "custom",
        subject: payload.subject || "Safestride update",
        html: payload.html || `<p>Hi ${name}, you have a new update in Safestride.</p>`,
      };
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json(405, { success: false, error: "Method not allowed" });

  try {
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    const fromEmail = Deno.env.get("EMAIL_FROM") || "Safestride <onboarding@resend.dev>";
    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || Deno.env.get("SUPABASE_ANON_KEY") || "";

    if (!resendApiKey) return json(500, { success: false, error: "Missing RESEND_API_KEY" });
    if (!supabaseUrl || !serviceRoleKey) return json(500, { success: false, error: "Missing Supabase environment variables" });

    const payload = (await req.json()) as SendEmailPayload;
    if (!payload?.to) return json(400, { success: false, error: "Missing 'to' in request body" });

    const rendered = buildTemplate(payload);

    const resendResp = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: fromEmail,
        to: [payload.to],
        subject: rendered.subject,
        html: rendered.html,
      }),
    });

    const resendBody = await resendResp.json().catch(() => ({}));

    const supabase = createClient(supabaseUrl, serviceRoleKey);
    const logStatus = resendResp.ok ? "sent" : "failed";

    await supabase.from("athlete_email_log").insert({
      user_id: payload.userId ?? null,
      email_type: rendered.type,
      recipient_email: payload.to,
      provider_message_id: resendBody?.id ?? null,
      status: logStatus,
      metadata: {
        templateType: payload.templateType || "custom",
        resend: resendBody,
        ...(payload.metadata || {}),
      },
    });

    if (payload.userId) {
      await supabase
        .from("athlete_onboarding_status")
        .upsert(
          {
            user_id: payload.userId,
            last_email_sent_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          },
          { onConflict: "user_id" },
        );
    }

    if (!resendResp.ok) {
      return json(502, { success: false, error: "Email provider failed", details: resendBody });
    }

    return json(200, {
      success: true,
      messageId: resendBody?.id ?? null,
      emailType: rendered.type,
      subject: rendered.subject,
    });
  } catch (error) {
    return json(500, {
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});
