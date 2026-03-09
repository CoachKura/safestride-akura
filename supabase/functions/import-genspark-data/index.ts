// @ts-nocheck
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type ImportRequest = {
  athleteId?: string;
  sourceUrl?: string;
  sourceHeaders?: Record<string, string>;
  payload?: unknown;
  dryRun?: boolean;
  importKey?: string;
  completeProcess?: boolean;
  triggerWorkflow?: boolean;
  userId?: string;
  userEmail?: string;
  fullName?: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-import-key",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function normalizeJsonText(raw: string) {
  const trimmed = raw.trim();
  if (!trimmed.startsWith("```")) return trimmed;

  const lines = trimmed.split(/\r?\n/);
  if (lines.length < 3) return trimmed;

  const first = lines[0].trim();
  const last = lines[lines.length - 1].trim();
  if (!first.startsWith("```") || last !== "```") return trimmed;

  return lines.slice(1, -1).join("\n").trim();
}

function maybeParseJson(input: unknown) {
  if (typeof input !== "string") return input;
  return JSON.parse(normalizeJsonText(input));
}

function asRecord(value: unknown): Record<string, unknown> {
  if (value && typeof value === "object" && !Array.isArray(value)) return value as Record<string, unknown>;
  return {};
}

function toNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  const n = Number(value);
  if (!Number.isFinite(n)) return null;
  return n;
}

function toDateOnly(value: unknown) {
  if (!value) return new Date().toISOString().slice(0, 10);
  const text = String(value);
  if (/^\d{4}-\d{2}-\d{2}$/.test(text)) return text;
  const parsed = new Date(text);
  if (Number.isNaN(parsed.getTime())) return new Date().toISOString().slice(0, 10);
  return parsed.toISOString().slice(0, 10);
}

function toIsoDateTime(value: unknown) {
  if (!value) return new Date().toISOString();
  const parsed = new Date(String(value));
  if (Number.isNaN(parsed.getTime())) return new Date().toISOString();
  return parsed.toISOString();
}

function firstNonEmptyString(...values: unknown[]): string {
  for (const value of values) {
    if (value === null || value === undefined) continue;
    const text = String(value).trim();
    if (text) return text;
  }
  return "";
}

function classifyRisk(totalScore: number) {
  if (totalScore >= 85) return "Very Low Risk";
  if (totalScore >= 70) return "Low Risk";
  if (totalScore >= 55) return "Medium Risk";
  if (totalScore >= 40) return "High Risk";
  return "Critical Risk";
}

function clamp(value: number, min: number, max: number) {
  return Math.min(max, Math.max(min, value));
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

function pickActivities(payload: unknown): Array<Record<string, unknown>> {
  if (Array.isArray(payload)) return payload.map((item) => asRecord(item));

  const root = asRecord(payload);
  const rootData = asRecord(root.data);
  const rootResult = asRecord(root.result);
  const rootPayload = asRecord(root.payload);

  const candidates: unknown[] = [
    root.activities,
    root.strava_activities,
    root.stravaActivities,
    rootData.activities,
    rootData.strava_activities,
    rootData.stravaActivities,
    rootResult.activities,
    rootResult.strava_activities,
    rootPayload.activities,
  ];

  for (const candidate of candidates) {
    if (Array.isArray(candidate)) return candidate.map((item) => asRecord(item));
  }

  return [];
}

function pickAisri(payload: unknown): Record<string, unknown> | null {
  const root = asRecord(payload);
  const rootData = asRecord(root.data);
  const rootResult = asRecord(root.result);

  const candidates: unknown[] = [
    root.aisri,
    root.aisri_score,
    root.aisriScore,
    root.latest_aisri,
    root.latestAisri,
    rootData.aisri,
    rootData.aisri_score,
    rootData.aisriScore,
    rootResult.aisri,
    rootResult.aisri_score,
    rootResult.aisriScore,
  ];

  for (const candidate of candidates) {
    if (!candidate) continue;
    if (typeof candidate === "number") return { total_score: candidate };
    if (typeof candidate === "string") {
      const n = toNumber(candidate);
      if (n !== null) return { total_score: n };
      continue;
    }
    const record = asRecord(candidate);
    if (Object.keys(record).length > 0) return record;
  }

  return null;
}

function pickAthleteId(payload: unknown, requestedAthleteId?: string) {
  const root = asRecord(payload);
  const athlete = asRecord(root.athlete);
  const profile = asRecord(root.profile);
  const data = asRecord(root.data);

  return firstNonEmptyString(
    requestedAthleteId,
    root.athlete_id,
    root.athleteId,
    root.user_id,
    root.userId,
    athlete.athlete_id,
    athlete.athleteId,
    athlete.id,
    profile.athlete_uid,
    profile.athleteId,
    data.athlete_id,
    data.athleteId,
    data.user_id,
    data.userId,
  );
}

function normalizeActivity(raw: Record<string, unknown>, fallbackAthleteId: string) {
  const activityId = toNumber(
    raw.strava_activity_id ?? raw.activity_id ?? raw.activityId ?? raw.id,
  );
  if (activityId === null) return null;

  const athleteId = firstNonEmptyString(
    raw.athlete_id,
    raw.athleteId,
    raw.user_id,
    raw.userId,
    fallbackAthleteId,
  );
  if (!athleteId) return null;

  const aisriScore = toNumber(
    raw.aisri_score ??
      raw.aisriScore ??
      raw.aisri_contribution ??
      raw.aisriContribution ??
      asRecord(raw.metrics).aisriContribution,
  );

  return {
    athlete_id: athleteId,
    strava_activity_id: Math.trunc(activityId),
    activity_data: asRecord(raw.activity_data).id ? asRecord(raw.activity_data) : raw,
    aisri_score: aisriScore,
    ml_insights: raw.ml_insights ?? raw.insights ?? null,
    created_at: toIsoDateTime(raw.start_date ?? raw.created_at ?? raw.timestamp),
  };
}

function normalizeAisri(raw: Record<string, unknown>, athleteId: string, activityCount: number) {
  const totalScore = toNumber(
    raw.total_score ?? raw.totalScore ?? raw.aisri_score ?? raw.aisriScore ?? raw.score,
  );
  if (totalScore === null) return null;

  const pillarScores =
    asRecord(raw.pillar_scores).running !== undefined
      ? asRecord(raw.pillar_scores)
      : asRecord(raw.pillars).running !== undefined
      ? asRecord(raw.pillars)
      : asRecord(raw.breakdown).running !== undefined
      ? asRecord(raw.breakdown)
      : {};

  const riskCategory = firstNonEmptyString(
    raw.risk_category,
    raw.riskCategory,
    classifyRisk(totalScore),
  );

  return {
    athlete_id: athleteId,
    assessment_date: toDateOnly(raw.assessment_date ?? raw.assessmentDate),
    total_score: totalScore,
    risk_category: riskCategory,
    pillar_scores: pillarScores,
    ml_insights: raw.ml_insights ?? raw.insights ?? { source: "genspark_agent" },
    strava_data_included: Boolean(raw.strava_data_included ?? activityCount > 0),
    created_at: toIsoDateTime(raw.created_at),
  };
}

function deriveAisriFromActivities(
  activities: Array<Record<string, unknown>>,
  athleteId: string,
) {
  if (!activities.length) return null;

  let activityCount = 0;
  let totalDistanceKm = 0;
  let totalMovingMinutes = 0;
  let totalEffortScore = 0;

  for (const activity of activities) {
    const data = asRecord(activity.activity_data).id ? asRecord(activity.activity_data) : asRecord(activity);

    const distanceKm = Math.max(0, Number(data.distance || 0) / 1000);
    const movingMinutes = Math.max(0, Number(data.moving_time || 0) / 60);
    const avgHr = Math.max(0, Number(data.average_heartrate || 0));
    const elevation = Math.max(0, Number(data.total_elevation_gain || 0));

    const hrIntensity = avgHr > 0 ? clamp(avgHr / 175, 0.6, 1.25) : 0.78;
    const elevationBonus = clamp(elevation / 200, 0, 1.5) * 4;
    const sessionScore = clamp(
      35 + distanceKm * 2.2 + movingMinutes * 0.22 + hrIntensity * 15 + elevationBonus,
      20,
      98,
    );

    activityCount += 1;
    totalDistanceKm += distanceKm;
    totalMovingMinutes += movingMinutes;
    totalEffortScore += sessionScore;
  }

  if (!activityCount) return null;

  const avgSessionScore = totalEffortScore / activityCount;
  const consistencyBonus = clamp(activityCount * 0.6, 0, 12);
  const volumeBonus = clamp(totalDistanceKm * 0.18, 0, 10);
  const running = clamp(avgSessionScore + consistencyBonus + volumeBonus - 8, 35, 95);

  const pillars = {
    running: Math.round(running),
    strength: 70,
    rom: 69,
    balance: 70,
    alignment: 70,
    mobility: 71,
  };

  const totalScore = Math.round(
    pillars.running * 0.4 +
      pillars.strength * 0.15 +
      pillars.rom * 0.12 +
      pillars.balance * 0.13 +
      pillars.alignment * 0.1 +
      pillars.mobility * 0.1,
  );

  return {
    athlete_id: athleteId,
    assessment_date: new Date().toISOString().slice(0, 10),
    total_score: totalScore,
    risk_category: classifyRisk(totalScore),
    pillar_scores: pillars,
    ml_insights: {
      source: "derived_from_imported_activities",
      summary: {
        activityCount,
        totalDistanceKm: Math.round(totalDistanceKm * 100) / 100,
        totalMovingMinutes: Math.round(totalMovingMinutes),
        avgSessionScore: Math.round(avgSessionScore * 10) / 10,
      },
    },
    strava_data_included: true,
    created_at: new Date().toISOString(),
  };
}

function pickUserId(payload: unknown, requestedUserId?: string) {
  const root = asRecord(payload);
  const athlete = asRecord(root.athlete);
  const user = asRecord(root.user);
  const data = asRecord(root.data);

  return firstNonEmptyString(
    requestedUserId,
    root.user_id,
    root.userId,
    root.id,
    athlete.user_id,
    athlete.userId,
    athlete.id,
    user.id,
    user.user_id,
    data.user_id,
    data.userId,
  );
}

function pickUserEmail(payload: unknown, requestedEmail?: string) {
  const root = asRecord(payload);
  const athlete = asRecord(root.athlete);
  const user = asRecord(root.user);
  const profile = asRecord(root.profile);
  const data = asRecord(root.data);

  return firstNonEmptyString(
    requestedEmail,
    root.email,
    root.user_email,
    root.userEmail,
    athlete.email,
    athlete.user_email,
    user.email,
    profile.email,
    data.email,
    data.user_email,
    data.userEmail,
  );
}

function pickFullName(payload: unknown, requestedName?: string) {
  const root = asRecord(payload);
  const athlete = asRecord(root.athlete);
  const user = asRecord(root.user);
  const profile = asRecord(root.profile);

  return firstNonEmptyString(
    requestedName,
    root.full_name,
    root.fullName,
    root.name,
    athlete.full_name,
    athlete.fullName,
    athlete.name,
    user.full_name,
    user.fullName,
    user.name,
    profile.full_name,
    profile.fullName,
    profile.name,
  );
}

async function bestEffortProfileUpdate(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  athleteId: string,
  warnings: string[],
) {
  const now = new Date().toISOString();
  let touched = false;

  if (isUuid(userId)) {
    const byUserId = await supabase
      .from("profiles")
      .update({ strava_connected: true, updated_at: now })
      .eq("user_id", userId);
    if (!byUserId.error) touched = true;
  }

  if (isUuid(userId)) {
    const byId = await supabase
      .from("profiles")
      .update({ strava_connected: true, updated_at: now })
      .eq("id", userId);
    if (!byId.error) touched = true;
  }

  if (athleteId) {
    const byAthleteUid = await supabase
      .from("profiles")
      .update({ strava_connected: true, updated_at: now })
      .eq("athlete_uid", athleteId);
    if (!byAthleteUid.error) touched = true;
  }

  if (!touched) {
    warnings.push("No matching profile row updated (non-fatal).");
  }
}

async function bestEffortOnboardingUpdate(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  warnings: string[],
) {
  if (!isUuid(userId)) {
    warnings.push("Onboarding status skip: userId is not UUID.");
    return;
  }

  const now = new Date().toISOString();
  const { error } = await supabase.from("athlete_onboarding_status").upsert(
    {
      user_id: userId,
      strava_synced_at: now,
      aisri_completed_at: now,
      current_step: "active_training",
      updated_at: now,
    },
    { onConflict: "user_id" },
  );

  if (error) {
    warnings.push(`Onboarding status update failed: ${error.message}`);
  }
}

async function bestEffortWorkflowTrigger(
  supabaseUrl: string,
  serviceRoleKey: string,
  body: ImportRequest,
  userId: string,
  userEmail: string,
  fullName: string,
  warnings: string[],
) {
  if (!body.triggerWorkflow) return;

  if (!isUuid(userId) || !userEmail) {
    warnings.push("Workflow trigger skipped: userId/email missing or invalid.");
    return;
  }

  const response = await fetch(`${supabaseUrl}/functions/v1/athlete-workflow`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${serviceRoleKey}`,
      "Content-Type": "application/json",
      apikey: serviceRoleKey,
    },
    body: JSON.stringify({
      eventType: "strava_connected",
      userId,
      email: userEmail,
      fullName: fullName || undefined,
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    warnings.push(`Workflow trigger failed (${response.status}): ${text.slice(0, 180)}`);
  }
}

async function loadSourcePayload(sourceUrl: string, sourceHeaders: Record<string, string>) {
  const response = await fetch(sourceUrl, {
    method: "GET",
    headers: {
      Accept: "application/json, text/plain;q=0.9, */*;q=0.8",
      ...sourceHeaders,
    },
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`sourceUrl request failed (${response.status}): ${text.slice(0, 250)}`);
  }

  const contentType = response.headers.get("content-type") || "";
  if (contentType.includes("application/json")) {
    return await response.json();
  }

  const text = await response.text();
  try {
    return JSON.parse(normalizeJsonText(text));
  } catch {
    throw new Error("sourceUrl response is not valid JSON");
  }
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

    const body = (await req.json()) as ImportRequest;
    const completeProcess = body.completeProcess !== false;
    const requiredImportKey = Deno.env.get("GENSPARK_IMPORT_KEY") || "";
    const providedImportKey = firstNonEmptyString(
      req.headers.get("x-import-key"),
      body.importKey,
    );
    if (requiredImportKey && providedImportKey !== requiredImportKey) {
      return json(401, { success: false, error: "Invalid import key" });
    }

    let rawPayload: unknown = null;
    if (body.sourceUrl) {
      rawPayload = await loadSourcePayload(body.sourceUrl, body.sourceHeaders || {});
    } else if (body.payload !== undefined) {
      rawPayload = maybeParseJson(body.payload);
    } else {
      return json(400, { success: false, error: "Provide either sourceUrl or payload" });
    }

    const activitiesRaw = pickActivities(rawPayload);
    const athleteId = pickAthleteId(rawPayload, body.athleteId);
    const fallbackAthleteId = athleteId || firstNonEmptyString(asRecord(activitiesRaw[0]).athlete_id);

    if (!fallbackAthleteId) {
      return json(400, {
        success: false,
        error: "Could not infer athleteId. Provide athleteId in request body.",
      });
    }

    const normalizedActivities = activitiesRaw
      .map((activity) => normalizeActivity(activity, fallbackAthleteId))
      .filter(Boolean);

    const userId = pickUserId(rawPayload, body.userId);
    const userEmail = pickUserEmail(rawPayload, body.userEmail);
    const fullName = pickFullName(rawPayload, body.fullName);

    const aisriRaw = pickAisri(rawPayload);
    let normalizedAisri = aisriRaw ? normalizeAisri(aisriRaw, fallbackAthleteId, normalizedActivities.length) : null;
    let aisriSource = "payload";
    if (!normalizedAisri && completeProcess) {
      normalizedAisri = deriveAisriFromActivities(normalizedActivities, fallbackAthleteId);
      aisriSource = normalizedAisri ? "derived" : "none";
    } else if (!normalizedAisri) {
      aisriSource = "none";
    }

    if (body.dryRun) {
      return json(200, {
        success: true,
        dryRun: true,
        athleteId: fallbackAthleteId,
        userId: userId || null,
        userEmail: userEmail || null,
        completeProcess,
        triggerWorkflow: Boolean(body.triggerWorkflow),
        sourceMode: body.sourceUrl ? "sourceUrl" : "payload",
        activitiesDetected: activitiesRaw.length,
        activitiesReady: normalizedActivities.length,
        aisriDetected: Boolean(aisriRaw),
        aisriReady: Boolean(normalizedAisri),
        aisriSource,
        sampleActivity: normalizedActivities[0] || null,
        sampleAisri: normalizedAisri,
      });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    let importedActivities = 0;
    const batchSize = 200;
    for (let i = 0; i < normalizedActivities.length; i += batchSize) {
      const batch = normalizedActivities.slice(i, i + batchSize);
      if (!batch.length) continue;

      const { error } = await supabase
        .from("strava_activities")
        .upsert(batch, { onConflict: "strava_activity_id" });
      if (error) {
        throw new Error(`Failed importing activities batch ${i / batchSize + 1}: ${error.message}`);
      }
      importedActivities += batch.length;
    }

    let aisriInserted = false;
    if (normalizedAisri) {
      const { error } = await supabase.from("aisri_scores").insert(normalizedAisri);
      if (error) throw new Error(`Failed importing AISRI score: ${error.message}`);
      aisriInserted = true;
    }

    const completionWarnings: string[] = [];
    if (completeProcess) {
      await bestEffortProfileUpdate(supabase, userId, fallbackAthleteId, completionWarnings);
      await bestEffortOnboardingUpdate(supabase, userId, completionWarnings);
      await bestEffortWorkflowTrigger(
        supabaseUrl,
        serviceRoleKey,
        body,
        userId,
        userEmail,
        fullName,
        completionWarnings,
      );
    }

    return json(200, {
      success: true,
      athleteId: fallbackAthleteId,
      userId: userId || null,
      userEmail: userEmail || null,
      activitiesImported: importedActivities,
      aisriInserted,
      aisriSource,
      completeProcess,
      workflowTriggered: Boolean(body.triggerWorkflow && isUuid(userId) && userEmail),
      warnings: completionWarnings,
      sourceMode: body.sourceUrl ? "sourceUrl" : "payload",
      warning:
        body.sourceUrl && importedActivities === 0 && !aisriInserted
          ? "No importable data found. Use dryRun to inspect payload shape."
          : null,
    });
  } catch (error) {
    return json(500, {
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});
