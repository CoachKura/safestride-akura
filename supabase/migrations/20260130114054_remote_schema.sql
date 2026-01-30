


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  user_full_name text;
BEGIN
  -- Extract full name from metadata, fallback to email username
  user_full_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    SPLIT_PART(NEW.email, '@', 1)
  );
  
  -- Insert profile
  INSERT INTO public.profiles (id, email, full_name, role, assessment_completed)
  VALUES (
    NEW.id,
    NEW.email,
    user_full_name,
    'athlete',
    false
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;

$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;

$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;

$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."assessments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "athlete_id" "uuid" NOT NULL,
    "coach_id" "uuid",
    "firstname" "text",
    "lastname" "text",
    "age" integer,
    "gender" "text",
    "height" numeric,
    "weight" numeric,
    "runningexperience" "text",
    "weeklymileage" numeric,
    "injuries" "text",
    "goals" "text",
    "ankleflexibility_left" numeric,
    "ankleflexibility_right" numeric,
    "hipflexibility_left" numeric,
    "hipflexibility_right" numeric,
    "shouldermobility_left" numeric,
    "shouldermobility_right" numeric,
    "fms_deepsquat" integer,
    "fms_hurdlestep_left" integer,
    "fms_hurdlestep_right" integer,
    "fms_inlinelunge_left" integer,
    "fms_inlinelunge_right" integer,
    "fms_shouldermobility_left" integer,
    "fms_shouldermobility_right" integer,
    "fms_shoulderclearingtest" boolean,
    "fms_activestraightlegraise_left" integer,
    "fms_activestraightlegraise_right" integer,
    "fms_trunkstability" integer,
    "fms_pressupclearingtest" boolean,
    "fms_rotarystability_left" integer,
    "fms_rotarystability_right" integer,
    "fms_flexionclearingtest" boolean,
    "fms_extensionclearingtest" boolean,
    "squatreps" integer,
    "lungereps" integer,
    "planktime" numeric,
    "sideplanktime_left" numeric,
    "sideplanktime_right" numeric,
    "calfraises" integer,
    "cadence" numeric,
    "stridelength" numeric,
    "groundcontacttime" numeric,
    "verticaloscillation" numeric,
    "baseline_distance" numeric,
    "baseline_time" numeric,
    "baseline_pace" numeric,
    "baseline_heartrate" numeric,
    "baseline_rpe" integer,
    "traininghistory" "text",
    "recentraces" "text",
    "currenttraining" "text",
    "aifri_score" numeric,
    "risk_level" "text",
    "pillar_scores" "jsonb" DEFAULT '{}'::"jsonb",
    "recommendations" "jsonb" DEFAULT '[]'::"jsonb",
    "assessment_date" timestamp with time zone DEFAULT "now"(),
    "notes" "text",
    "score" numeric,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."assessments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."coach_athlete_relationships" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "coach_id" "uuid" NOT NULL,
    "athlete_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text",
    "permissions" "jsonb" DEFAULT '{"canMessage": true, "canViewFeedback": true, "canEditProtocols": true, "canViewAssessments": true}'::"jsonb",
    "invited_at" timestamp with time zone DEFAULT "now"(),
    "accepted_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "coach_athlete_relationships_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'active'::"text", 'inactive'::"text"])))
);


ALTER TABLE "public"."coach_athlete_relationships" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."feedback" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "workout_id" "uuid" NOT NULL,
    "athlete_id" "uuid" NOT NULL,
    "rpe" integer,
    "pain_level" "text",
    "pain_location" "text"[],
    "fatigue_level" integer,
    "sleep_hours" numeric(3,1),
    "sleep_quality" "text",
    "soreness_level" integer,
    "nutrition_quality" "text",
    "hydration_level" "text",
    "stress_level" "text",
    "completed" boolean DEFAULT false,
    "completion_percentage" integer,
    "notes" "text",
    "ai_analysis" "jsonb" DEFAULT '{"concerns": [], "adjustments": [], "recommendations": []}'::"jsonb",
    "plan_adjusted" boolean DEFAULT false,
    "adjustment_details" "jsonb",
    "submitted_at" timestamp with time zone DEFAULT "now"(),
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "feedback_completion_percentage_check" CHECK ((("completion_percentage" >= 0) AND ("completion_percentage" <= 100))),
    CONSTRAINT "feedback_fatigue_level_check" CHECK ((("fatigue_level" >= 1) AND ("fatigue_level" <= 10))),
    CONSTRAINT "feedback_hydration_level_check" CHECK (("hydration_level" = ANY (ARRAY['poor'::"text", 'adequate'::"text", 'good'::"text", 'excellent'::"text"]))),
    CONSTRAINT "feedback_nutrition_quality_check" CHECK (("nutrition_quality" = ANY (ARRAY['poor'::"text", 'fair'::"text", 'good'::"text", 'excellent'::"text"]))),
    CONSTRAINT "feedback_pain_level_check" CHECK (("pain_level" = ANY (ARRAY['none'::"text", 'mild'::"text", 'moderate'::"text", 'severe'::"text"]))),
    CONSTRAINT "feedback_rpe_check" CHECK ((("rpe" >= 1) AND ("rpe" <= 10))),
    CONSTRAINT "feedback_sleep_hours_check" CHECK ((("sleep_hours" >= (0)::numeric) AND ("sleep_hours" <= (24)::numeric))),
    CONSTRAINT "feedback_sleep_quality_check" CHECK (("sleep_quality" = ANY (ARRAY['poor'::"text", 'fair'::"text", 'good'::"text", 'excellent'::"text"]))),
    CONSTRAINT "feedback_soreness_level_check" CHECK ((("soreness_level" >= 0) AND ("soreness_level" <= 10))),
    CONSTRAINT "feedback_stress_level_check" CHECK (("stress_level" = ANY (ARRAY['low'::"text", 'moderate'::"text", 'high'::"text", 'very high'::"text"])))
);


ALTER TABLE "public"."feedback" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "full_name" "text",
    "role" "text" DEFAULT 'athlete'::"text",
    "phone" "text",
    "date_of_birth" "date",
    "gender" "text",
    "height_cm" numeric(5,2),
    "weight_kg" numeric(5,2),
    "avatar_url" "text",
    "bio" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "assessment_completed" boolean DEFAULT false,
    "assessment_skipped" boolean DEFAULT false,
    "access_level" "text" DEFAULT 'demo'::"text",
    CONSTRAINT "profiles_gender_check" CHECK (("gender" = ANY (ARRAY['male'::"text", 'female'::"text", 'other'::"text"]))),
    CONSTRAINT "profiles_role_check" CHECK (("role" = ANY (ARRAY['athlete'::"text", 'coach'::"text", 'admin'::"text"])))
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."protocols" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "athlete_id" "uuid" NOT NULL,
    "assessment_id" "uuid",
    "name" "text" NOT NULL,
    "description" "text",
    "duration_days" integer DEFAULT 90,
    "start_date" "date" DEFAULT CURRENT_DATE,
    "end_date" "date",
    "protocol_data" "jsonb" DEFAULT '{"weeks": [], "milestones": [], "progressionRules": {}}'::"jsonb" NOT NULL,
    "aifri_score" numeric(5,2),
    "risk_level" "text",
    "pillar_scores" "jsonb",
    "adaptation_rules" "jsonb" DEFAULT '{"recoveryDays": 2, "injuryThreshold": 7, "progressionRate": 0.1, "fatigueThreshold": 8}'::"jsonb",
    "status" "text" DEFAULT 'active'::"text",
    "completion_percentage" numeric(5,2) DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "protocols_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'paused'::"text", 'completed'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."protocols" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."schema_version" (
    "version" "text" NOT NULL,
    "applied_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."schema_version" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."training_plans" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "assessment_id" "uuid",
    "plan_name" "text" NOT NULL,
    "plan_data" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "start_date" "date",
    "end_date" "date",
    "status" "text" DEFAULT 'active'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "training_plans_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'completed'::"text", 'paused'::"text"])))
);


ALTER TABLE "public"."training_plans" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."workouts" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "protocol_id" "uuid" NOT NULL,
    "athlete_id" "uuid" NOT NULL,
    "week_number" integer NOT NULL,
    "day_number" integer NOT NULL,
    "day_of_week" "text",
    "workout_data" "jsonb" DEFAULT '{"type": "rest", "duration": 0, "exercises": [], "intensity": "low"}'::"jsonb" NOT NULL,
    "scheduled_date" "date",
    "completed_date" "date",
    "completed" boolean DEFAULT false,
    "skipped" boolean DEFAULT false,
    "skip_reason" "text",
    "actual_duration" integer,
    "actual_distance" numeric(6,2),
    "actual_pace" "text",
    "calories_burned" integer,
    "coach_notes" "text",
    "athlete_notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "workouts_day_number_check" CHECK ((("day_number" >= 1) AND ("day_number" <= 90))),
    CONSTRAINT "workouts_day_of_week_check" CHECK (("day_of_week" = ANY (ARRAY['Monday'::"text", 'Tuesday'::"text", 'Wednesday'::"text", 'Thursday'::"text", 'Friday'::"text", 'Saturday'::"text", 'Sunday'::"text"]))),
    CONSTRAINT "workouts_week_number_check" CHECK ((("week_number" >= 1) AND ("week_number" <= 12)))
);


ALTER TABLE "public"."workouts" OWNER TO "postgres";


ALTER TABLE ONLY "public"."assessments"
    ADD CONSTRAINT "assessments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."coach_athlete_relationships"
    ADD CONSTRAINT "coach_athlete_relationships_coach_id_athlete_id_key" UNIQUE ("coach_id", "athlete_id");



ALTER TABLE ONLY "public"."coach_athlete_relationships"
    ADD CONSTRAINT "coach_athlete_relationships_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."protocols"
    ADD CONSTRAINT "protocols_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."schema_version"
    ADD CONSTRAINT "schema_version_pkey" PRIMARY KEY ("version");



ALTER TABLE ONLY "public"."training_plans"
    ADD CONSTRAINT "training_plans_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."workouts"
    ADD CONSTRAINT "workouts_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_assessments_athlete_id" ON "public"."assessments" USING "btree" ("athlete_id");



CREATE INDEX "idx_assessments_coach_id" ON "public"."assessments" USING "btree" ("coach_id");



CREATE INDEX "idx_assessments_created_at" ON "public"."assessments" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_coach_athlete_athlete" ON "public"."coach_athlete_relationships" USING "btree" ("athlete_id");



CREATE INDEX "idx_coach_athlete_coach" ON "public"."coach_athlete_relationships" USING "btree" ("coach_id");



CREATE INDEX "idx_coach_athlete_status" ON "public"."coach_athlete_relationships" USING "btree" ("status");



CREATE INDEX "idx_feedback_athlete" ON "public"."feedback" USING "btree" ("athlete_id");



CREATE INDEX "idx_feedback_athlete_id" ON "public"."feedback" USING "btree" ("athlete_id");



CREATE INDEX "idx_feedback_pain" ON "public"."feedback" USING "btree" ("pain_level");



CREATE INDEX "idx_feedback_rpe" ON "public"."feedback" USING "btree" ("rpe");



CREATE INDEX "idx_feedback_submitted" ON "public"."feedback" USING "btree" ("submitted_at" DESC);



CREATE INDEX "idx_feedback_workout" ON "public"."feedback" USING "btree" ("workout_id");



CREATE INDEX "idx_profiles_email" ON "public"."profiles" USING "btree" ("email");



CREATE INDEX "idx_profiles_role" ON "public"."profiles" USING "btree" ("role");



CREATE INDEX "idx_protocols_assessment" ON "public"."protocols" USING "btree" ("assessment_id");



CREATE INDEX "idx_protocols_athlete" ON "public"."protocols" USING "btree" ("athlete_id");



CREATE INDEX "idx_protocols_athlete_id" ON "public"."protocols" USING "btree" ("athlete_id");



CREATE INDEX "idx_protocols_dates" ON "public"."protocols" USING "btree" ("start_date", "end_date");



CREATE INDEX "idx_protocols_status" ON "public"."protocols" USING "btree" ("status");



CREATE INDEX "idx_training_plans_assessment_id" ON "public"."training_plans" USING "btree" ("assessment_id");



CREATE INDEX "idx_training_plans_user_id" ON "public"."training_plans" USING "btree" ("user_id");



CREATE INDEX "idx_workouts_athlete" ON "public"."workouts" USING "btree" ("athlete_id");



CREATE INDEX "idx_workouts_athlete_id" ON "public"."workouts" USING "btree" ("athlete_id");



CREATE INDEX "idx_workouts_completed" ON "public"."workouts" USING "btree" ("completed");



CREATE INDEX "idx_workouts_date" ON "public"."workouts" USING "btree" ("scheduled_date");



CREATE INDEX "idx_workouts_protocol" ON "public"."workouts" USING "btree" ("protocol_id");



CREATE INDEX "idx_workouts_week_day" ON "public"."workouts" USING "btree" ("week_number", "day_number");



CREATE OR REPLACE TRIGGER "trg_profiles_updated_at" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_training_plans_updated_at" BEFORE UPDATE ON "public"."training_plans" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "update_assessments_updated_at" BEFORE UPDATE ON "public"."assessments" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_coach_athlete_updated_at" BEFORE UPDATE ON "public"."coach_athlete_relationships" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_profiles_updated_at" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_protocols_updated_at" BEFORE UPDATE ON "public"."protocols" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_workouts_updated_at" BEFORE UPDATE ON "public"."workouts" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



ALTER TABLE ONLY "public"."assessments"
    ADD CONSTRAINT "assessments_athlete_id_fkey" FOREIGN KEY ("athlete_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."assessments"
    ADD CONSTRAINT "assessments_coach_id_fkey" FOREIGN KEY ("coach_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."coach_athlete_relationships"
    ADD CONSTRAINT "coach_athlete_relationships_athlete_id_fkey" FOREIGN KEY ("athlete_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."coach_athlete_relationships"
    ADD CONSTRAINT "coach_athlete_relationships_coach_id_fkey" FOREIGN KEY ("coach_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_athlete_id_fkey" FOREIGN KEY ("athlete_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_workout_id_fkey" FOREIGN KEY ("workout_id") REFERENCES "public"."workouts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."protocols"
    ADD CONSTRAINT "protocols_athlete_id_fkey" FOREIGN KEY ("athlete_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."training_plans"
    ADD CONSTRAINT "training_plans_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."workouts"
    ADD CONSTRAINT "workouts_athlete_id_fkey" FOREIGN KEY ("athlete_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."workouts"
    ADD CONSTRAINT "workouts_protocol_id_fkey" FOREIGN KEY ("protocol_id") REFERENCES "public"."protocols"("id") ON DELETE CASCADE;



CREATE POLICY "Athletes can accept invites" ON "public"."coach_athlete_relationships" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "athlete_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "athlete_id"));



CREATE POLICY "Athletes can create own assessments" ON "public"."assessments" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "athlete_id"));



CREATE POLICY "Athletes can insert own feedback" ON "public"."feedback" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "athlete_id"));



CREATE POLICY "Athletes can insert own workouts" ON "public"."workouts" FOR INSERT TO "authenticated" WITH CHECK (("athlete_id" = "auth"."uid"()));



CREATE POLICY "Athletes can update own assessments" ON "public"."assessments" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "athlete_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "athlete_id"));



CREATE POLICY "Athletes can update own feedback" ON "public"."feedback" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "athlete_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "athlete_id"));



CREATE POLICY "Athletes can update own workouts" ON "public"."workouts" FOR UPDATE TO "authenticated" USING (("athlete_id" = "auth"."uid"())) WITH CHECK (("athlete_id" = "auth"."uid"()));



CREATE POLICY "Athletes can view own assessments" ON "public"."assessments" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "athlete_id"));



CREATE POLICY "Athletes can view own feedback" ON "public"."feedback" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "athlete_id"));



CREATE POLICY "Athletes can view own protocols" ON "public"."protocols" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "athlete_id"));



CREATE POLICY "Athletes can view own relationships" ON "public"."coach_athlete_relationships" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "athlete_id"));



CREATE POLICY "Athletes can view own workouts" ON "public"."workouts" FOR SELECT TO "authenticated" USING (("athlete_id" = "auth"."uid"()));



CREATE POLICY "Coaches can manage athlete workouts" ON "public"."workouts" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'coach'::"text")))));



CREATE POLICY "Coaches can view athlete assessments" ON "public"."assessments" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = ( SELECT "auth"."uid"() AS "uid")) AND ("profiles"."role" = 'coach'::"text")))));



CREATE POLICY "Coaches can view athlete feedback" ON "public"."feedback" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."coach_athlete_relationships"
  WHERE (("coach_athlete_relationships"."coach_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("coach_athlete_relationships"."athlete_id" = "feedback"."athlete_id") AND ("coach_athlete_relationships"."status" = 'active'::"text")))));



CREATE POLICY "Coaches can view athlete profiles" ON "public"."profiles" FOR SELECT TO "authenticated" USING ((("role" = 'athlete'::"text") OR (( SELECT "auth"."uid"() AS "uid") = "id")));



CREATE POLICY "Users can insert own profile" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "id"));



CREATE POLICY "Users can update own profile" ON "public"."profiles" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "id"));



CREATE POLICY "Users can view own profile" ON "public"."profiles" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "id"));



ALTER TABLE "public"."assessments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."coach_athlete_relationships" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."feedback" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles_delete_self" ON "public"."profiles" FOR DELETE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "id"));



CREATE POLICY "profiles_insert_self" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "id"));



CREATE POLICY "profiles_select_self" ON "public"."profiles" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "id"));



CREATE POLICY "profiles_update_self" ON "public"."profiles" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "id"));



ALTER TABLE "public"."protocols" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."schema_version" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."training_plans" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."workouts" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";


















GRANT ALL ON TABLE "public"."assessments" TO "anon";
GRANT ALL ON TABLE "public"."assessments" TO "authenticated";
GRANT ALL ON TABLE "public"."assessments" TO "service_role";



GRANT ALL ON TABLE "public"."coach_athlete_relationships" TO "anon";
GRANT ALL ON TABLE "public"."coach_athlete_relationships" TO "authenticated";
GRANT ALL ON TABLE "public"."coach_athlete_relationships" TO "service_role";



GRANT ALL ON TABLE "public"."feedback" TO "anon";
GRANT ALL ON TABLE "public"."feedback" TO "authenticated";
GRANT ALL ON TABLE "public"."feedback" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."protocols" TO "anon";
GRANT ALL ON TABLE "public"."protocols" TO "authenticated";
GRANT ALL ON TABLE "public"."protocols" TO "service_role";



GRANT ALL ON TABLE "public"."schema_version" TO "anon";
GRANT ALL ON TABLE "public"."schema_version" TO "authenticated";
GRANT ALL ON TABLE "public"."schema_version" TO "service_role";



GRANT ALL ON TABLE "public"."training_plans" TO "anon";
GRANT ALL ON TABLE "public"."training_plans" TO "authenticated";
GRANT ALL ON TABLE "public"."training_plans" TO "service_role";



GRANT ALL ON TABLE "public"."workouts" TO "anon";
GRANT ALL ON TABLE "public"."workouts" TO "authenticated";
GRANT ALL ON TABLE "public"."workouts" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";



































drop extension if exists "pg_net";

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


