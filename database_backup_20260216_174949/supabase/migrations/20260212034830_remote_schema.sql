


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



CREATE EXTENSION IF NOT EXISTS "hypopg" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "index_advisor" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."coach_alert_type" AS ENUM (
    'missed_workout',
    'performance_decline',
    'urgent_checkin',
    'low_compliance',
    'injury_risk'
);


ALTER TYPE "public"."coach_alert_type" OWNER TO "postgres";


CREATE TYPE "public"."notification_priority" AS ENUM (
    'low',
    'medium',
    'high',
    'urgent'
);


ALTER TYPE "public"."notification_priority" OWNER TO "postgres";


CREATE TYPE "public"."notification_type" AS ENUM (
    'training',
    'social',
    'system',
    'achievement',
    'reminder',
    'challenge'
);


ALTER TYPE "public"."notification_type" OWNER TO "postgres";


CREATE TYPE "public"."protocol_review_status" AS ENUM (
    'pending',
    'approved',
    'modified',
    'rejected'
);


ALTER TYPE "public"."protocol_review_status" OWNER TO "postgres";


CREATE TYPE "public"."training_phase" AS ENUM (
    'base',
    'build',
    'peak',
    'recovery'
);


ALTER TYPE "public"."training_phase" OWNER TO "postgres";


CREATE TYPE "public"."training_zone" AS ENUM (
    'easy',
    'marathon',
    'threshold',
    'interval',
    'repetition'
);


ALTER TYPE "public"."training_zone" OWNER TO "postgres";


CREATE TYPE "public"."user_role" AS ENUM (
    'athlete',
    'coach',
    'admin'
);


ALTER TYPE "public"."user_role" OWNER TO "postgres";


CREATE TYPE "public"."workout_type" AS ENUM (
    'easy_run',
    'long_run',
    'tempo',
    'intervals',
    'repetition',
    'recovery',
    'race'
);


ALTER TYPE "public"."workout_type" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_vdot_from_race"("race_distance_km" numeric, "race_time_seconds" integer) RETURNS numeric
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    velocity DECIMAL;
    percent_max DECIMAL;
    vdot DECIMAL;
BEGIN
    velocity := (race_distance_km * 1000) / race_time_seconds;
    percent_max := 0.8 + 0.1894393 * EXP(-0.012778 * race_time_seconds / 60) + 0.2989558 * EXP(-0.1932605 * race_time_seconds / 60);
    vdot := (-4.6 + 0.182258 * velocity + 0.000104 * velocity * velocity) / percent_max;
    RETURN ROUND(vdot, 1);
END;
$$;


ALTER FUNCTION "public"."calculate_vdot_from_race"("race_distance_km" numeric, "race_time_seconds" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_missed_workouts"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    missed_workout RECORD;
    coach_record RECORD;
BEGIN
    FOR missed_workout IN
        SELECT 
            ww.id,
            ww.user_id as athlete_id,
            ww.week_number,
            ww.day_of_week,
            ww.workout_type,
            up.full_name as athlete_name
        FROM public.weekly_workouts ww
        JOIN public.user_profiles up ON ww.user_id = up.id
        WHERE ww.is_completed = false
        AND ww.created_at < NOW() - INTERVAL '24 hours'
        AND NOT EXISTS (
            SELECT 1 FROM public.notifications n
            WHERE n.metadata->>'workout_id' = ww.id::text
            AND n.metadata->>'alert_type' = 'missed_workout'
            AND n.created_at > NOW() - INTERVAL '24 hours'
        )
    LOOP
        FOR coach_record IN
            SELECT car.coach_id
            FROM public.coach_athlete_relationships car
            WHERE car.athlete_id = missed_workout.athlete_id
            AND car.is_active = true
        LOOP
            PERFORM public.create_coach_alert(
                coach_record.coach_id,
                missed_workout.athlete_id,
                'missed_workout'::public.coach_alert_type,
                'Missed Workout Alert',
                missed_workout.athlete_name || ' missed their scheduled ' || 
                missed_workout.workout_type || ' workout',
                jsonb_build_object(
                    'workout_id', missed_workout.id,
                    'week_number', missed_workout.week_number,
                    'day_of_week', missed_workout.day_of_week
                )
            );
        END LOOP;
    END LOOP;
END;
$$;


ALTER FUNCTION "public"."check_missed_workouts"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."check_missed_workouts"() IS 'Run this function via cron/scheduler every 6 hours';



CREATE OR REPLACE FUNCTION "public"."check_performance_decline"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    decline_record RECORD;
    coach_record RECORD;
BEGIN
    FOR decline_record IN
        SELECT 
            tlm.user_id as athlete_id,
            tlm.injury_risk,
            tlm.training_stress_balance,
            tlm.adaptation_status,
            up.full_name as athlete_name
        FROM public.training_load_metrics tlm
        JOIN public.user_profiles up ON tlm.user_id = up.id
        WHERE tlm.date >= CURRENT_DATE - INTERVAL '7 days'
        AND (
            tlm.injury_risk = 'High'
            OR tlm.training_stress_balance < -15
            OR tlm.adaptation_status IN ('Overreaching', 'Fatigued')
        )
        AND NOT EXISTS (
            SELECT 1 FROM public.notifications n
            WHERE n.metadata->>'athlete_id' = tlm.user_id::text
            AND n.metadata->>'alert_type' = 'performance_decline'
            AND n.created_at > NOW() - INTERVAL '48 hours'
        )
    LOOP
        FOR coach_record IN
            SELECT car.coach_id
            FROM public.coach_athlete_relationships car
            WHERE car.athlete_id = decline_record.athlete_id
            AND car.is_active = true
        LOOP
            PERFORM public.create_coach_alert(
                coach_record.coach_id,
                decline_record.athlete_id,
                'performance_decline'::public.coach_alert_type,
                'Performance Decline Detected',
                decline_record.athlete_name || ' showing declining metrics: ' ||
                CASE 
                    WHEN decline_record.injury_risk = 'High' THEN 'High injury risk'
                    WHEN decline_record.training_stress_balance < -15 THEN 'Negative training balance'
                    ELSE decline_record.adaptation_status || ' status'
                END,
                jsonb_build_object(
                    'injury_risk', decline_record.injury_risk,
                    'training_stress_balance', decline_record.training_stress_balance,
                    'adaptation_status', decline_record.adaptation_status
                )
            );
        END LOOP;
    END LOOP;
END;
$$;


ALTER FUNCTION "public"."check_performance_decline"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."check_performance_decline"() IS 'Run this function via cron/scheduler every 12 hours';



CREATE OR REPLACE FUNCTION "public"."check_urgent_checkins"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    checkin_record RECORD;
BEGIN
    FOR checkin_record IN
        SELECT 
            cis.coach_id,
            cis.athlete_id,
            cis.id as checkin_id,
            cis.scheduled_date,
            up.full_name as athlete_name
        FROM public.check_in_schedules cis
        JOIN public.user_profiles up ON cis.athlete_id = up.id
        WHERE cis.is_completed = false
        AND cis.scheduled_date < NOW() + INTERVAL '4 hours'
        AND cis.scheduled_date > NOW()
        AND NOT EXISTS (
            SELECT 1 FROM public.notifications n
            WHERE n.metadata->>'checkin_id' = cis.id::text
            AND n.metadata->>'alert_type' = 'urgent_checkin'
            AND n.created_at > NOW() - INTERVAL '6 hours'
        )
    LOOP
        PERFORM public.create_coach_alert(
            checkin_record.coach_id,
            checkin_record.athlete_id,
            'urgent_checkin'::public.coach_alert_type,
            'Upcoming Check-in',
            'Check-in with ' || checkin_record.athlete_name || ' scheduled in less than 4 hours',
            jsonb_build_object(
                'checkin_id', checkin_record.checkin_id,
                'scheduled_date', checkin_record.scheduled_date
            )
        );
    END LOOP;
END;
$$;


ALTER FUNCTION "public"."check_urgent_checkins"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."check_urgent_checkins"() IS 'Run this function via cron/scheduler every hour';



CREATE OR REPLACE FUNCTION "public"."create_athlete_profile_for_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    INSERT INTO public.athlete_profiles (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."create_athlete_profile_for_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_coach_alert"("p_coach_id" "uuid", "p_athlete_id" "uuid", "p_alert_type" "public"."coach_alert_type", "p_title" "text", "p_message" "text", "p_metadata" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    notification_id UUID;
BEGIN
    INSERT INTO public.notifications (
        user_id,
        type,
        title,
        message,
        priority,
        metadata,
        action_url,
        action_label
    )
    VALUES (
        p_coach_id,
        'training',
        p_title,
        p_message,
        'urgent',
        jsonb_build_object(
            'alert_type', p_alert_type,
            'athlete_id', p_athlete_id,
            'requires_action', true
        ) || p_metadata,
        '/coach-dashboard?athlete_id=' || p_athlete_id::text,
        'View Details'
    )
    RETURNING id INTO notification_id;
    
    RETURN notification_id;
END;
$$;


ALTER FUNCTION "public"."create_coach_alert"("p_coach_id" "uuid", "p_athlete_id" "uuid", "p_alert_type" "public"."coach_alert_type", "p_title" "text", "p_message" "text", "p_metadata" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_protocol_review_notification"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    urgency TEXT;
BEGIN
    -- Determine urgency based on athlete metrics
    SELECT CASE
        WHEN EXISTS (
            SELECT 1 FROM public.training_load_metrics tlm
            WHERE tlm.user_id = NEW.athlete_id
            AND tlm.injury_risk IN ('High', 'Very High')
            LIMIT 1
        ) THEN 'urgent'
        WHEN EXISTS (
            SELECT 1 FROM public.weekly_workouts ww
            WHERE ww.user_id = NEW.athlete_id
            AND ww.is_completed = false
            AND ww.week_number < (SELECT week_number FROM public.weekly_workouts WHERE training_plan_id = NEW.training_plan_id ORDER BY week_number DESC LIMIT 1)
        ) THEN 'high'
        ELSE 'normal'
    END INTO urgency;

    -- Create notification for coach
    INSERT INTO public.protocol_review_notifications (
        protocol_review_id,
        coach_id,
        urgency_level
    ) VALUES (
        NEW.id,
        NEW.coach_id,
        urgency
    );

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."create_protocol_review_notification"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."delete_expired_notifications"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    DELETE FROM public.notifications
    WHERE expires_at IS NOT NULL 
    AND expires_at < now()
    AND is_read = true;
END;
$$;


ALTER FUNCTION "public"."delete_expired_notifications"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_pace_for_vdot_and_zone"("vdot_value" numeric, "zone_name" "text") RETURNS TABLE("pace_min_per_km" numeric, "pace_max_per_km" numeric)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        CASE zone_name
            WHEN 'easy' THEN ROUND((vdot_value * 0.65)::DECIMAL, 2)
            WHEN 'marathon' THEN ROUND((vdot_value * 0.75)::DECIMAL, 2)
            WHEN 'threshold' THEN ROUND((vdot_value * 0.88)::DECIMAL, 2)
            WHEN 'interval' THEN ROUND((vdot_value * 0.98)::DECIMAL, 2)
            WHEN 'repetition' THEN ROUND((vdot_value * 1.05)::DECIMAL, 2)
        END AS pace_min,
        CASE zone_name
            WHEN 'easy' THEN ROUND((vdot_value * 0.79)::DECIMAL, 2)
            WHEN 'marathon' THEN ROUND((vdot_value * 0.84)::DECIMAL, 2)
            WHEN 'threshold' THEN ROUND((vdot_value * 0.92)::DECIMAL, 2)
            WHEN 'interval' THEN ROUND((vdot_value * 1.02)::DECIMAL, 2)
            WHEN 'repetition' THEN ROUND((vdot_value * 1.15)::DECIMAL, 2)
        END AS pace_max;
END;
$$;


ALTER FUNCTION "public"."get_pace_for_vdot_and_zone"("vdot_value" numeric, "zone_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_unread_notification_count"("p_user_id" "uuid") RETURNS integer
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
    SELECT COUNT(*)::INTEGER
    FROM public.notifications
    WHERE user_id = p_user_id
    AND is_read = false
    AND (expires_at IS NULL OR expires_at > now());
$$;


ALTER FUNCTION "public"."get_unread_notification_count"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  user_role TEXT;
  user_name TEXT;
BEGIN
  -- Get the role from user metadata (default to 'athlete')
  user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'athlete');
  user_name := COALESCE(NEW.raw_user_meta_data->>'full_name', 'User');

  -- ALWAYS create a profiles record (required for app)
  -- Using only columns that exist in the table
  BEGIN
    INSERT INTO public.profiles (user_id, name, email)
    VALUES (NEW.id, user_name, NEW.email)
    ON CONFLICT (user_id) DO NOTHING;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error creating profile for user %: %', NEW.id, SQLERRM;
  END;

  -- If user is an athlete, also create athlete_profiles record
  IF user_role = 'athlete' THEN
    BEGIN
      INSERT INTO public.athlete_profiles (user_id)
      VALUES (NEW.id)
      ON CONFLICT (user_id) DO NOTHING;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Error creating athlete_profile for user %: %', NEW.id, SQLERRM;
    END;
  END IF;

  -- If user is a coach, create coach_profiles record
  IF user_role = 'coach' THEN
    BEGIN
      INSERT INTO public.coach_profiles (user_id, coach_name)
      VALUES (NEW.id, user_name)
      ON CONFLICT (user_id) DO NOTHING;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Error creating coach_profile for user %: %', NEW.id, SQLERRM;
    END;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_assigned_coach"("athlete_uuid" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
SELECT EXISTS (
    SELECT 1 FROM public.coach_athlete_relationships car
    WHERE car.athlete_id = athlete_uuid
    AND car.coach_id = auth.uid()
    AND car.is_active = true
)
$$;


ALTER FUNCTION "public"."is_assigned_coach"("athlete_uuid" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_assigned_coach_for_protocol"("protocol_uuid" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
SELECT EXISTS (
    SELECT 1 FROM public.ai_protocol_reviews apr
    WHERE apr.id = protocol_uuid AND apr.coach_id = auth.uid()
)
$$;


ALTER FUNCTION "public"."is_assigned_coach_for_protocol"("protocol_uuid" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_coach_from_auth"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() AND up.role = 'coach'
)
$$;


ALTER FUNCTION "public"."is_coach_from_auth"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mark_all_notifications_read"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  UPDATE public.notifications
  SET is_read = true, read_at = CURRENT_TIMESTAMP
  WHERE user_id = auth.uid() AND is_read = false;
END;
$$;


ALTER FUNCTION "public"."mark_all_notifications_read"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mark_notification_read"("notification_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    UPDATE public.notifications
    SET is_read = true, read_at = now()
    WHERE id = notification_id;
END;
$$;


ALTER FUNCTION "public"."mark_notification_read"("notification_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_athlete_on_protocol_decision"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    alert_title TEXT;
    alert_message TEXT;
    alert_priority public.notification_priority;
    action_url_path TEXT;
    action_label_text TEXT;
BEGIN
    -- Only trigger on status changes from pending
    IF OLD.review_status = 'pending'::public.protocol_review_status 
       AND NEW.review_status != OLD.review_status THEN
        
        -- Determine notification content based on decision
        CASE NEW.review_status
            WHEN 'approved'::public.protocol_review_status THEN
                alert_title := 'Training Protocol Approved';
                alert_message := 'Your coach has approved the AI-generated training protocol. Ready to start your new plan!';
                alert_priority := 'high'::public.notification_priority;
                action_label_text := 'View Protocol';
            
            WHEN 'modified'::public.protocol_review_status THEN
                alert_title := 'Training Protocol Modified';
                alert_message := 'Your coach has made adjustments to the AI-generated protocol. Review the changes and get started!';
                alert_priority := 'high'::public.notification_priority;
                action_label_text := 'Review Changes';
            
            WHEN 'rejected'::public.protocol_review_status THEN
                alert_title := 'Protocol Needs Revision';
                alert_message := COALESCE(
                    'Your coach has requested revisions: ' || NEW.rejection_reason,
                    'Your coach has requested revisions to the training protocol.'
                );
                alert_priority := 'urgent'::public.notification_priority;
                action_label_text := 'See Feedback';
        END CASE;
        
        -- Create action URL for protocol review interface
        action_url_path := '/ai-protocol-review/' || NEW.id::TEXT;
        
        -- Insert notification for athlete
        INSERT INTO public.notifications (
            user_id,
            type,
            title,
            message,
            priority,
            action_url,
            action_label,
            metadata,
            created_at
        ) VALUES (
            NEW.athlete_id,
            'training'::public.notification_type,
            alert_title,
            alert_message,
            alert_priority,
            action_url_path,
            action_label_text,
            jsonb_build_object(
                'protocol_review_id', NEW.id,
                'review_status', NEW.review_status,
                'coach_id', NEW.coach_id,
                'training_plan_id', NEW.training_plan_id,
                'decision_made_at', NEW.decision_made_at
            ),
            CURRENT_TIMESTAMP
        );
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_athlete_on_protocol_decision"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_missed_workout_alert"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    coach_record RECORD;
    athlete_name TEXT;
BEGIN
    IF NEW.is_completed = false AND NEW.created_at < NOW() - INTERVAL '24 hours' THEN
        SELECT full_name INTO athlete_name 
        FROM public.user_profiles 
        WHERE id = NEW.user_id;
        
        FOR coach_record IN
            SELECT car.coach_id
            FROM public.coach_athlete_relationships car
            WHERE car.athlete_id = NEW.user_id
            AND car.is_active = true
        LOOP
            PERFORM public.create_coach_alert(
                coach_record.coach_id,
                NEW.user_id,
                'missed_workout'::public.coach_alert_type,
                'Workout Missed',
                athlete_name || ' did not complete scheduled workout',
                jsonb_build_object(
                    'workout_id', NEW.id,
                    'week_number', NEW.week_number,
                    'workout_type', NEW.workout_type
                )
            );
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trigger_missed_workout_alert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_performance_alert"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    coach_record RECORD;
    athlete_name TEXT;
BEGIN
    IF NEW.injury_risk = 'High' OR 
       NEW.training_stress_balance < -15 OR 
       NEW.adaptation_status IN ('Overreaching', 'Fatigued') THEN
        
        SELECT full_name INTO athlete_name 
        FROM public.user_profiles 
        WHERE id = NEW.user_id;
        
        FOR coach_record IN
            SELECT car.coach_id
            FROM public.coach_athlete_relationships car
            WHERE car.athlete_id = NEW.user_id
            AND car.is_active = true
        LOOP
            PERFORM public.create_coach_alert(
                coach_record.coach_id,
                NEW.user_id,
                'performance_decline'::public.coach_alert_type,
                'Performance Alert',
                athlete_name || ' showing concerning metrics',
                jsonb_build_object(
                    'metric_id', NEW.id,
                    'injury_risk', NEW.injury_risk,
                    'training_stress_balance', NEW.training_stress_balance
                )
            );
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trigger_performance_alert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_readiness_decline_alert"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_user_id UUID;
    v_notification_enabled BOOLEAN;
    v_injury_risk_changed BOOLEAN;
    v_fatigue_changed BOOLEAN;
    v_adaptation_changed BOOLEAN;
BEGIN
    v_user_id := NEW.user_id;
    
    -- Check if user has training notifications enabled
    SELECT push_enabled INTO v_notification_enabled
    FROM public.notification_preferences
    WHERE user_id = v_user_id 
    AND type = 'training'::public.notification_type;
    
    -- Skip if notifications disabled
    IF v_notification_enabled IS NULL OR v_notification_enabled = false THEN
        RETURN NEW;
    END IF;
    
    -- Detect if this is an INSERT (no OLD record)
    IF TG_OP = 'INSERT' THEN
        v_injury_risk_changed := (NEW.injury_risk IN ('High', 'Medium'));
        v_fatigue_changed := (NEW.fatigue_indicator IN ('High', 'Very High'));
        v_adaptation_changed := (NEW.adaptation_status IN ('Overreaching', 'Maladapted'));
    ELSE
        -- For UPDATE, check if values got worse
        v_injury_risk_changed := (
            (OLD.injury_risk IS NULL OR OLD.injury_risk = 'Low')
            AND NEW.injury_risk IN ('High', 'Medium')
        );
        
        v_fatigue_changed := (
            (OLD.fatigue_indicator IS NULL OR OLD.fatigue_indicator IN ('Low', 'Moderate'))
            AND NEW.fatigue_indicator IN ('High', 'Very High')
        );
        
        v_adaptation_changed := (
            (OLD.adaptation_status IS NULL OR OLD.adaptation_status IN ('Fresh', 'Adapting'))
            AND NEW.adaptation_status IN ('Overreaching', 'Maladapted')
        );
    END IF;
    
    -- Create notification for injury risk
    IF v_injury_risk_changed THEN
        INSERT INTO public.notifications (
            user_id,
            type,
            title,
            message,
            priority,
            action_label,
            action_url,
            metadata
        ) VALUES (
            v_user_id,
            'training'::public.notification_type,
            'Injury Risk Alert',
            'Your injury risk has increased to ' || NEW.injury_risk || '. Consider reducing training intensity and ensuring adequate recovery.',
            'urgent'::public.notification_priority,
            'View Recovery',
            '/recovery-status',
            jsonb_build_object('injury_risk', NEW.injury_risk, 'date', NEW.date)
        );
    END IF;
    
    -- Create notification for fatigue
    IF v_fatigue_changed THEN
        INSERT INTO public.notifications (
            user_id,
            type,
            title,
            message,
            priority,
            action_label,
            action_url,
            metadata
        ) VALUES (
            v_user_id,
            'training'::public.notification_type,
            'High Fatigue Detected',
            'Your fatigue level is ' || NEW.fatigue_indicator || '. Extra rest days may be needed. Consider adjusting your training plan.',
            'high'::public.notification_priority,
            'View Metrics',
            '/progress-analytics',
            jsonb_build_object('fatigue_indicator', NEW.fatigue_indicator, 'date', NEW.date)
        );
    END IF;
    
    -- Create notification for adaptation issues
    IF v_adaptation_changed THEN
        INSERT INTO public.notifications (
            user_id,
            type,
            title,
            message,
            priority,
            action_label,
            action_url,
            metadata
        ) VALUES (
            v_user_id,
            'training'::public.notification_type,
            'Training Adaptation Alert',
            'Your body is showing signs of ' || NEW.adaptation_status || '. Review your training load and recovery strategies.',
            'high'::public.notification_priority,
            'View Training Plan',
            '/training-plan',
            jsonb_build_object('adaptation_status', NEW.adaptation_status, 'date', NEW.date)
        );
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trigger_readiness_decline_alert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_athlete_statistics"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    UPDATE public.athlete_profiles
    SET 
        total_distance = (
            SELECT COALESCE(SUM(distance), 0)
            FROM public.activities
            WHERE user_id = NEW.user_id
        ),
        total_activities = (
            SELECT COUNT(*)
            FROM public.activities
            WHERE user_id = NEW.user_id
        ),
        updated_at = NOW()
    WHERE user_id = NEW.user_id;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_athlete_statistics"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_conversation_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    UPDATE public.chat_conversations
    SET last_message_at = NEW.created_at,
        updated_at = NEW.created_at
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_conversation_timestamp"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_protocol_review_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_protocol_review_timestamp"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."activities" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "strava_activity_id" bigint,
    "activity_type" "text" NOT NULL,
    "name" "text" NOT NULL,
    "distance" numeric(10,2) NOT NULL,
    "moving_time" integer NOT NULL,
    "elapsed_time" integer NOT NULL,
    "total_elevation_gain" numeric(10,2) DEFAULT 0,
    "average_speed" numeric(10,2),
    "max_speed" numeric(10,2),
    "average_heartrate" integer,
    "max_heartrate" integer,
    "average_cadence" integer,
    "calories" numeric(10,2),
    "effort_score" integer,
    "start_date" timestamp with time zone NOT NULL,
    "timezone" "text",
    "route_thumbnail" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."activities" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ai_protocol_reviews" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "training_plan_id" "uuid" NOT NULL,
    "athlete_id" "uuid" NOT NULL,
    "coach_id" "uuid" NOT NULL,
    "protocol_version" integer DEFAULT 1 NOT NULL,
    "generated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "review_status" "public"."protocol_review_status" DEFAULT 'pending'::"public"."protocol_review_status" NOT NULL,
    "ai_protocol_data" "jsonb" NOT NULL,
    "ai_reasoning" "jsonb" NOT NULL,
    "comparison_data" "jsonb",
    "coach_annotations" "text",
    "coach_modifications" "jsonb",
    "decision_made_at" timestamp with time zone,
    "rejection_reason" "text",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."ai_protocol_reviews" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."athlete_profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "strava_athlete_id" bigint,
    "strava_access_token" "text",
    "strava_refresh_token" "text",
    "strava_token_expires_at" timestamp with time zone,
    "total_distance" numeric(10,2) DEFAULT 0,
    "total_activities" integer DEFAULT 0,
    "active_years" integer DEFAULT 0,
    "current_streak" integer DEFAULT 0,
    "achievement_count" integer DEFAULT 0,
    "location" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "strava_username" "text",
    "strava_firstname" "text",
    "strava_lastname" "text",
    "strava_profile_image" "text",
    "strava_connected_at" timestamp with time zone
);


ALTER TABLE "public"."athlete_profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."chat_conversations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" DEFAULT 'New Conversation'::"text" NOT NULL,
    "last_message_at" timestamp with time zone DEFAULT "now"(),
    "is_archived" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."chat_conversations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."chat_messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "conversation_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" "text" NOT NULL,
    "content" "text" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "chat_messages_role_check" CHECK (("role" = ANY (ARRAY['user'::"text", 'assistant'::"text", 'system'::"text"])))
);


ALTER TABLE "public"."chat_messages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."check_in_schedules" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "coach_id" "uuid" NOT NULL,
    "athlete_id" "uuid" NOT NULL,
    "scheduled_date" timestamp with time zone NOT NULL,
    "check_in_type" "text" DEFAULT 'regular'::"text",
    "notes" "text",
    "is_completed" boolean DEFAULT false,
    "completed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."check_in_schedules" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."coach_athlete_relationships" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "coach_id" "uuid" NOT NULL,
    "athlete_id" "uuid" NOT NULL,
    "assigned_date" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."coach_athlete_relationships" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."garmin_activities" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "athlete_id" "uuid" NOT NULL,
    "garmin_activity_id" bigint NOT NULL,
    "activity_type" "text" NOT NULL,
    "start_time" timestamp with time zone NOT NULL,
    "duration" integer NOT NULL,
    "distance" numeric(10,2),
    "average_heart_rate" integer,
    "max_heart_rate" integer,
    "average_pace" numeric(5,2),
    "calories" integer,
    "elevation_gain" numeric(10,2),
    "training_effect" numeric(3,1),
    "vo2_max" numeric(4,1),
    "fit_file_url" "text",
    "raw_data" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."garmin_activities" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."garmin_connections" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "athlete_id" "uuid" NOT NULL,
    "garmin_user_id" "text" NOT NULL,
    "access_token" "text" NOT NULL,
    "refresh_token" "text" NOT NULL,
    "token_expires_at" timestamp with time zone NOT NULL,
    "is_active" boolean DEFAULT true,
    "last_sync_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."garmin_connections" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."garmin_devices" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "device_id" character varying(255) NOT NULL,
    "device_name" character varying(255) NOT NULL,
    "connection_type" character varying(20) DEFAULT 'bluetooth'::character varying,
    "ip_address" character varying(45),
    "device_info" "jsonb",
    "last_connected_at" timestamp with time zone DEFAULT "now"(),
    "last_sync_at" timestamp with time zone,
    "is_active" boolean DEFAULT true,
    "sync_settings" "jsonb" DEFAULT '{"auto_sync": true, "sync_interval_hours": 24}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "garmin_devices_connection_type_check" CHECK ((("connection_type")::"text" = ANY ((ARRAY['bluetooth'::character varying, 'wifi'::character varying, 'both'::character varying])::"text"[])))
);


ALTER TABLE "public"."garmin_devices" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."garmin_pushed_workouts" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "athlete_id" "uuid" NOT NULL,
    "safestride_workout_id" "uuid",
    "garmin_workout_id" "text",
    "workout_name" "text" NOT NULL,
    "workout_type" "text" NOT NULL,
    "scheduled_date" "date",
    "push_status" "text" DEFAULT 'pending'::"text",
    "pushed_at" timestamp with time zone,
    "garmin_response" "jsonb",
    "error_message" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "garmin_pushed_workouts_push_status_check" CHECK (("push_status" = ANY (ARRAY['pending'::"text", 'success'::"text", 'failed'::"text"])))
);


ALTER TABLE "public"."garmin_pushed_workouts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."mileage_overrides" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "coach_id" "uuid" NOT NULL,
    "athlete_id" "uuid" NOT NULL,
    "training_plan_id" "uuid" NOT NULL,
    "week_number" integer NOT NULL,
    "original_mileage" numeric,
    "override_mileage" numeric NOT NULL,
    "ai_recommendation" numeric,
    "override_reason" "text" NOT NULL,
    "applied_date" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "confidence_score" numeric DEFAULT 85.0,
    "effectiveness_metric" numeric,
    CONSTRAINT "mileage_overrides_confidence_score_check" CHECK ((("confidence_score" >= (0)::numeric) AND ("confidence_score" <= (100)::numeric))),
    CONSTRAINT "mileage_overrides_effectiveness_metric_check" CHECK ((("effectiveness_metric" >= (0)::numeric) AND ("effectiveness_metric" <= (100)::numeric)))
);


ALTER TABLE "public"."mileage_overrides" OWNER TO "postgres";


COMMENT ON COLUMN "public"."mileage_overrides"."confidence_score" IS 'AI model confidence in the recommendation (0-100)';



COMMENT ON COLUMN "public"."mileage_overrides"."effectiveness_metric" IS 'Measured effectiveness of the coach override decision (0-100)';



CREATE TABLE IF NOT EXISTS "public"."notification_preferences" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "type" "public"."notification_type" NOT NULL,
    "push_enabled" boolean DEFAULT true,
    "email_enabled" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."notification_preferences" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "type" "public"."notification_type" NOT NULL,
    "priority" "public"."notification_priority" DEFAULT 'medium'::"public"."notification_priority",
    "title" "text" NOT NULL,
    "message" "text" NOT NULL,
    "action_url" "text",
    "action_label" "text",
    "is_read" boolean DEFAULT false,
    "source_app" "text" DEFAULT 'SafeStride'::"text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "read_at" timestamp with time zone,
    "expires_at" timestamp with time zone
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pace_progression" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "distance_category" "text" NOT NULL,
    "recorded_date" "date" NOT NULL,
    "average_pace" numeric(10,2) NOT NULL,
    "goal_pace" numeric(10,2),
    "improvement" numeric(5,2),
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."pace_progression" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."personal_bests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "distance_category" "text" NOT NULL,
    "best_time" integer NOT NULL,
    "average_pace" numeric(10,2) NOT NULL,
    "achieved_date" timestamp with time zone NOT NULL,
    "activity_id" "uuid",
    "improvement_percentage" numeric(5,2),
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."personal_bests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."protocol_review_notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "protocol_review_id" "uuid" NOT NULL,
    "coach_id" "uuid" NOT NULL,
    "urgency_level" "text" DEFAULT 'normal'::"text" NOT NULL,
    "is_read" boolean DEFAULT false,
    "notification_sent_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."protocol_review_notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."race_predictions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "vdot_score_id" "uuid" NOT NULL,
    "race_distance" "text" NOT NULL,
    "predicted_time_seconds" integer NOT NULL,
    "predicted_pace_min_per_km" numeric(5,2) NOT NULL,
    "confidence_level" "text",
    "improvement_potential_seconds" integer,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."race_predictions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."training_load_metrics" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "date" "date" NOT NULL,
    "acute_load" numeric(6,2) NOT NULL,
    "chronic_load" numeric(6,2) NOT NULL,
    "training_stress_balance" numeric(6,2),
    "fatigue_indicator" "text",
    "injury_risk" "text",
    "adaptation_status" "text",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."training_load_metrics" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."training_notes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "coach_id" "uuid" NOT NULL,
    "athlete_id" "uuid" NOT NULL,
    "training_plan_id" "uuid",
    "note_content" "text" NOT NULL,
    "note_type" "text" DEFAULT 'general'::"text",
    "is_read" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."training_notes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."training_plans" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "plan_name" "text" NOT NULL,
    "goal_race_distance" "text" NOT NULL,
    "goal_race_date" "date",
    "current_phase" "public"."training_phase" DEFAULT 'base'::"public"."training_phase",
    "weeks_duration" integer NOT NULL,
    "weekly_mileage_target" numeric(6,2),
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."training_plans" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."training_zones" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "vdot_score_id" "uuid" NOT NULL,
    "zone_type" "public"."training_zone" NOT NULL,
    "pace_min_per_km" numeric(5,2) NOT NULL,
    "pace_max_per_km" numeric(5,2) NOT NULL,
    "heart_rate_min" integer,
    "heart_rate_max" integer,
    "effort_description" "text",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."training_zones" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_profiles" (
    "id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "full_name" "text" NOT NULL,
    "role" "public"."user_role" DEFAULT 'athlete'::"public"."user_role",
    "avatar_url" "text",
    "bio" "text",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."user_profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."vdot_scores" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "vdot_value" numeric(4,1) NOT NULL,
    "fitness_level" "text" NOT NULL,
    "calculated_from" "text" NOT NULL,
    "race_distance" "text",
    "race_time" integer,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "vdot_scores_vdot_value_check" CHECK ((("vdot_value" >= (30)::numeric) AND ("vdot_value" <= (85)::numeric)))
);


ALTER TABLE "public"."vdot_scores" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."weekly_workouts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "training_plan_id" "uuid" NOT NULL,
    "week_number" integer NOT NULL,
    "day_of_week" integer NOT NULL,
    "workout_type" "public"."workout_type" NOT NULL,
    "distance_km" numeric(5,2),
    "target_pace_min_per_km" numeric(5,2),
    "target_zone" "public"."training_zone",
    "intervals_count" integer,
    "interval_distance_km" numeric(4,2),
    "recovery_time_minutes" integer,
    "description" "text",
    "technique_tips" "text",
    "is_completed" boolean DEFAULT false,
    "completed_at" timestamp with time zone,
    "actual_pace" numeric(5,2),
    "effort_rating" integer,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "weekly_workouts_day_of_week_check" CHECK ((("day_of_week" >= 1) AND ("day_of_week" <= 7))),
    CONSTRAINT "weekly_workouts_effort_rating_check" CHECK ((("effort_rating" >= 1) AND ("effort_rating" <= 10))),
    CONSTRAINT "weekly_workouts_week_number_check" CHECK (("week_number" > 0))
);


ALTER TABLE "public"."weekly_workouts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."year_statistics" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "year" integer NOT NULL,
    "month" integer NOT NULL,
    "total_distance" numeric(10,2) DEFAULT 0,
    "total_activities" integer DEFAULT 0,
    "total_time" integer DEFAULT 0,
    "avg_pace" numeric(10,2),
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."year_statistics" OWNER TO "postgres";


ALTER TABLE ONLY "public"."activities"
    ADD CONSTRAINT "activities_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."activities"
    ADD CONSTRAINT "activities_strava_activity_id_key" UNIQUE ("strava_activity_id");



ALTER TABLE ONLY "public"."ai_protocol_reviews"
    ADD CONSTRAINT "ai_protocol_reviews_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."athlete_profiles"
    ADD CONSTRAINT "athlete_profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."athlete_profiles"
    ADD CONSTRAINT "athlete_profiles_strava_athlete_id_key" UNIQUE ("strava_athlete_id");



ALTER TABLE ONLY "public"."chat_conversations"
    ADD CONSTRAINT "chat_conversations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."chat_messages"
    ADD CONSTRAINT "chat_messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."check_in_schedules"
    ADD CONSTRAINT "check_in_schedules_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."coach_athlete_relationships"
    ADD CONSTRAINT "coach_athlete_relationships_coach_id_athlete_id_key" UNIQUE ("coach_id", "athlete_id");



ALTER TABLE ONLY "public"."coach_athlete_relationships"
    ADD CONSTRAINT "coach_athlete_relationships_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."garmin_activities"
    ADD CONSTRAINT "garmin_activities_garmin_activity_id_key" UNIQUE ("garmin_activity_id");



ALTER TABLE ONLY "public"."garmin_activities"
    ADD CONSTRAINT "garmin_activities_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."garmin_connections"
    ADD CONSTRAINT "garmin_connections_athlete_id_garmin_user_id_key" UNIQUE ("athlete_id", "garmin_user_id");



ALTER TABLE ONLY "public"."garmin_connections"
    ADD CONSTRAINT "garmin_connections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."garmin_devices"
    ADD CONSTRAINT "garmin_devices_device_id_key" UNIQUE ("device_id");



ALTER TABLE ONLY "public"."garmin_devices"
    ADD CONSTRAINT "garmin_devices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."garmin_pushed_workouts"
    ADD CONSTRAINT "garmin_pushed_workouts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."mileage_overrides"
    ADD CONSTRAINT "mileage_overrides_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "notification_preferences_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "notification_preferences_user_id_type_key" UNIQUE ("user_id", "type");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pace_progression"
    ADD CONSTRAINT "pace_progression_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."personal_bests"
    ADD CONSTRAINT "personal_bests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."protocol_review_notifications"
    ADD CONSTRAINT "protocol_review_notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."race_predictions"
    ADD CONSTRAINT "race_predictions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."training_load_metrics"
    ADD CONSTRAINT "training_load_metrics_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."training_notes"
    ADD CONSTRAINT "training_notes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."training_plans"
    ADD CONSTRAINT "training_plans_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."training_zones"
    ADD CONSTRAINT "training_zones_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."personal_bests"
    ADD CONSTRAINT "unique_user_distance" UNIQUE ("user_id", "distance_category");



ALTER TABLE ONLY "public"."pace_progression"
    ADD CONSTRAINT "unique_user_distance_date" UNIQUE ("user_id", "distance_category", "recorded_date");



ALTER TABLE ONLY "public"."athlete_profiles"
    ADD CONSTRAINT "unique_user_profile" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."year_statistics"
    ADD CONSTRAINT "unique_user_year_month" UNIQUE ("user_id", "year", "month");



ALTER TABLE ONLY "public"."user_profiles"
    ADD CONSTRAINT "user_profiles_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."user_profiles"
    ADD CONSTRAINT "user_profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."vdot_scores"
    ADD CONSTRAINT "vdot_scores_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."weekly_workouts"
    ADD CONSTRAINT "weekly_workouts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."year_statistics"
    ADD CONSTRAINT "year_statistics_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_activities_start_date" ON "public"."activities" USING "btree" ("start_date" DESC);



CREATE INDEX "idx_activities_strava_id" ON "public"."activities" USING "btree" ("strava_activity_id");



CREATE INDEX "idx_activities_user_id" ON "public"."activities" USING "btree" ("user_id");



CREATE INDEX "idx_ai_protocol_reviews_athlete_id" ON "public"."ai_protocol_reviews" USING "btree" ("athlete_id");



CREATE INDEX "idx_ai_protocol_reviews_coach_id" ON "public"."ai_protocol_reviews" USING "btree" ("coach_id");



CREATE INDEX "idx_ai_protocol_reviews_generated_at" ON "public"."ai_protocol_reviews" USING "btree" ("generated_at" DESC);



CREATE INDEX "idx_ai_protocol_reviews_status" ON "public"."ai_protocol_reviews" USING "btree" ("review_status");



CREATE INDEX "idx_ai_protocol_reviews_training_plan_id" ON "public"."ai_protocol_reviews" USING "btree" ("training_plan_id");



CREATE INDEX "idx_athlete_profiles_strava_id" ON "public"."athlete_profiles" USING "btree" ("strava_athlete_id");



CREATE INDEX "idx_athlete_profiles_user_id" ON "public"."athlete_profiles" USING "btree" ("user_id");



CREATE INDEX "idx_chat_conversations_last_message" ON "public"."chat_conversations" USING "btree" ("last_message_at" DESC);



CREATE INDEX "idx_chat_conversations_user_id" ON "public"."chat_conversations" USING "btree" ("user_id");



CREATE INDEX "idx_chat_messages_conversation_id" ON "public"."chat_messages" USING "btree" ("conversation_id");



CREATE INDEX "idx_chat_messages_created_at" ON "public"."chat_messages" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_check_in_schedules_athlete_id" ON "public"."check_in_schedules" USING "btree" ("athlete_id");



CREATE INDEX "idx_check_in_schedules_coach_id" ON "public"."check_in_schedules" USING "btree" ("coach_id");



CREATE INDEX "idx_check_in_schedules_date" ON "public"."check_in_schedules" USING "btree" ("scheduled_date");



CREATE INDEX "idx_coach_athlete_active" ON "public"."coach_athlete_relationships" USING "btree" ("is_active");



CREATE INDEX "idx_coach_athlete_athlete_id" ON "public"."coach_athlete_relationships" USING "btree" ("athlete_id");



CREATE INDEX "idx_coach_athlete_coach_id" ON "public"."coach_athlete_relationships" USING "btree" ("coach_id");



CREATE INDEX "idx_garmin_activities_athlete" ON "public"."garmin_activities" USING "btree" ("athlete_id");



CREATE INDEX "idx_garmin_activities_date" ON "public"."garmin_activities" USING "btree" ("athlete_id", "start_time" DESC);



CREATE INDEX "idx_garmin_activities_garmin_id" ON "public"."garmin_activities" USING "btree" ("garmin_activity_id");



CREATE INDEX "idx_garmin_devices_active" ON "public"."garmin_devices" USING "btree" ("user_id", "is_active") WHERE ("is_active" = true);



CREATE INDEX "idx_garmin_devices_device_id" ON "public"."garmin_devices" USING "btree" ("device_id");



CREATE INDEX "idx_garmin_devices_user_id" ON "public"."garmin_devices" USING "btree" ("user_id");



CREATE INDEX "idx_garmin_pushed_athlete" ON "public"."garmin_pushed_workouts" USING "btree" ("athlete_id");



CREATE INDEX "idx_garmin_pushed_date" ON "public"."garmin_pushed_workouts" USING "btree" ("scheduled_date" DESC);



CREATE INDEX "idx_garmin_pushed_status" ON "public"."garmin_pushed_workouts" USING "btree" ("push_status");



CREATE INDEX "idx_mileage_overrides_athlete_id" ON "public"."mileage_overrides" USING "btree" ("athlete_id");



CREATE INDEX "idx_mileage_overrides_coach_id" ON "public"."mileage_overrides" USING "btree" ("coach_id");



CREATE INDEX "idx_mileage_overrides_confidence" ON "public"."mileage_overrides" USING "btree" ("confidence_score");



CREATE INDEX "idx_mileage_overrides_effectiveness" ON "public"."mileage_overrides" USING "btree" ("effectiveness_metric");



CREATE INDEX "idx_mileage_overrides_plan_id" ON "public"."mileage_overrides" USING "btree" ("training_plan_id");



CREATE INDEX "idx_notification_preferences_user_id" ON "public"."notification_preferences" USING "btree" ("user_id");



CREATE INDEX "idx_notifications_athlete_protocol_alerts" ON "public"."notifications" USING "btree" ("user_id", "created_at" DESC) WHERE ("type" = 'training'::"public"."notification_type");



CREATE INDEX "idx_notifications_created_at" ON "public"."notifications" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_notifications_is_read" ON "public"."notifications" USING "btree" ("is_read");



CREATE INDEX "idx_notifications_type" ON "public"."notifications" USING "btree" ("type");



CREATE INDEX "idx_notifications_user_id" ON "public"."notifications" USING "btree" ("user_id");



CREATE INDEX "idx_notifications_user_unread" ON "public"."notifications" USING "btree" ("user_id", "is_read") WHERE ("is_read" = false);



CREATE INDEX "idx_pace_progression_user_id" ON "public"."pace_progression" USING "btree" ("user_id");



CREATE INDEX "idx_personal_bests_user_id" ON "public"."personal_bests" USING "btree" ("user_id");



CREATE INDEX "idx_protocol_review_notifications_coach_id" ON "public"."protocol_review_notifications" USING "btree" ("coach_id");



CREATE INDEX "idx_protocol_review_notifications_is_read" ON "public"."protocol_review_notifications" USING "btree" ("is_read");



CREATE INDEX "idx_protocol_review_notifications_protocol_review_id" ON "public"."protocol_review_notifications" USING "btree" ("protocol_review_id");



CREATE INDEX "idx_race_predictions_user_id" ON "public"."race_predictions" USING "btree" ("user_id");



CREATE INDEX "idx_race_predictions_vdot_score_id" ON "public"."race_predictions" USING "btree" ("vdot_score_id");



CREATE INDEX "idx_training_load_metrics_date" ON "public"."training_load_metrics" USING "btree" ("date" DESC);



CREATE INDEX "idx_training_load_metrics_user_id" ON "public"."training_load_metrics" USING "btree" ("user_id");



CREATE INDEX "idx_training_notes_athlete_id" ON "public"."training_notes" USING "btree" ("athlete_id");



CREATE INDEX "idx_training_notes_coach_id" ON "public"."training_notes" USING "btree" ("coach_id");



CREATE INDEX "idx_training_notes_plan_id" ON "public"."training_notes" USING "btree" ("training_plan_id");



CREATE INDEX "idx_training_plans_is_active" ON "public"."training_plans" USING "btree" ("is_active");



CREATE INDEX "idx_training_plans_user_id" ON "public"."training_plans" USING "btree" ("user_id");



CREATE INDEX "idx_training_zones_user_id" ON "public"."training_zones" USING "btree" ("user_id");



CREATE INDEX "idx_training_zones_vdot_score_id" ON "public"."training_zones" USING "btree" ("vdot_score_id");



CREATE INDEX "idx_user_profiles_email" ON "public"."user_profiles" USING "btree" ("email");



CREATE INDEX "idx_user_profiles_role" ON "public"."user_profiles" USING "btree" ("role");



CREATE INDEX "idx_vdot_scores_created_at" ON "public"."vdot_scores" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_vdot_scores_user_id" ON "public"."vdot_scores" USING "btree" ("user_id");



CREATE INDEX "idx_weekly_workouts_plan_id" ON "public"."weekly_workouts" USING "btree" ("training_plan_id");



CREATE INDEX "idx_weekly_workouts_user_id" ON "public"."weekly_workouts" USING "btree" ("user_id");



CREATE INDEX "idx_weekly_workouts_week_day" ON "public"."weekly_workouts" USING "btree" ("week_number", "day_of_week");



CREATE INDEX "idx_year_statistics_user_id" ON "public"."year_statistics" USING "btree" ("user_id");



CREATE INDEX "idx_year_statistics_year_month" ON "public"."year_statistics" USING "btree" ("year", "month");



CREATE OR REPLACE TRIGGER "missed_workout_check" AFTER INSERT OR UPDATE ON "public"."weekly_workouts" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_missed_workout_alert"();



CREATE OR REPLACE TRIGGER "notify_athlete_on_protocol_status_change" AFTER UPDATE OF "review_status" ON "public"."ai_protocol_reviews" FOR EACH ROW EXECUTE FUNCTION "public"."notify_athlete_on_protocol_decision"();



CREATE OR REPLACE TRIGGER "notify_coach_on_protocol_creation" AFTER INSERT ON "public"."ai_protocol_reviews" FOR EACH ROW WHEN (("new"."review_status" = 'pending'::"public"."protocol_review_status")) EXECUTE FUNCTION "public"."create_protocol_review_notification"();



CREATE OR REPLACE TRIGGER "performance_decline_check" AFTER INSERT OR UPDATE ON "public"."training_load_metrics" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_performance_alert"();



CREATE OR REPLACE TRIGGER "readiness_decline_alert" AFTER INSERT OR UPDATE ON "public"."training_load_metrics" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_readiness_decline_alert"();



CREATE OR REPLACE TRIGGER "update_ai_protocol_reviews_updated_at" BEFORE UPDATE ON "public"."ai_protocol_reviews" FOR EACH ROW EXECUTE FUNCTION "public"."update_protocol_review_timestamp"();



CREATE OR REPLACE TRIGGER "update_athlete_stats_on_activity" AFTER INSERT OR DELETE OR UPDATE ON "public"."activities" FOR EACH ROW EXECUTE FUNCTION "public"."update_athlete_statistics"();



CREATE OR REPLACE TRIGGER "update_conversation_on_message" AFTER INSERT ON "public"."chat_messages" FOR EACH ROW EXECUTE FUNCTION "public"."update_conversation_timestamp"();



ALTER TABLE ONLY "public"."activities"
    ADD CONSTRAINT "activities_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ai_protocol_reviews"
    ADD CONSTRAINT "ai_protocol_reviews_athlete_id_fkey" FOREIGN KEY ("athlete_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ai_protocol_reviews"
    ADD CONSTRAINT "ai_protocol_reviews_coach_id_fkey" FOREIGN KEY ("coach_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ai_protocol_reviews"
    ADD CONSTRAINT "ai_protocol_reviews_training_plan_id_fkey" FOREIGN KEY ("training_plan_id") REFERENCES "public"."training_plans"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."athlete_profiles"
    ADD CONSTRAINT "athlete_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."chat_messages"
    ADD CONSTRAINT "chat_messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."chat_conversations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."check_in_schedules"
    ADD CONSTRAINT "check_in_schedules_athlete_id_fkey" FOREIGN KEY ("athlete_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."check_in_schedules"
    ADD CONSTRAINT "check_in_schedules_coach_id_fkey" FOREIGN KEY ("coach_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."coach_athlete_relationships"
    ADD CONSTRAINT "coach_athlete_relationships_athlete_id_fkey" FOREIGN KEY ("athlete_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."coach_athlete_relationships"
    ADD CONSTRAINT "coach_athlete_relationships_coach_id_fkey" FOREIGN KEY ("coach_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."garmin_activities"
    ADD CONSTRAINT "garmin_activities_athlete_id_fkey" FOREIGN KEY ("athlete_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."garmin_connections"
    ADD CONSTRAINT "garmin_connections_athlete_id_fkey" FOREIGN KEY ("athlete_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."garmin_devices"
    ADD CONSTRAINT "garmin_devices_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."garmin_pushed_workouts"
    ADD CONSTRAINT "garmin_pushed_workouts_athlete_id_fkey" FOREIGN KEY ("athlete_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."mileage_overrides"
    ADD CONSTRAINT "mileage_overrides_athlete_id_fkey" FOREIGN KEY ("athlete_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."mileage_overrides"
    ADD CONSTRAINT "mileage_overrides_coach_id_fkey" FOREIGN KEY ("coach_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."mileage_overrides"
    ADD CONSTRAINT "mileage_overrides_training_plan_id_fkey" FOREIGN KEY ("training_plan_id") REFERENCES "public"."training_plans"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "notification_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pace_progression"
    ADD CONSTRAINT "pace_progression_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."personal_bests"
    ADD CONSTRAINT "personal_bests_activity_id_fkey" FOREIGN KEY ("activity_id") REFERENCES "public"."activities"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."personal_bests"
    ADD CONSTRAINT "personal_bests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."protocol_review_notifications"
    ADD CONSTRAINT "protocol_review_notifications_coach_id_fkey" FOREIGN KEY ("coach_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."protocol_review_notifications"
    ADD CONSTRAINT "protocol_review_notifications_protocol_review_id_fkey" FOREIGN KEY ("protocol_review_id") REFERENCES "public"."ai_protocol_reviews"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."race_predictions"
    ADD CONSTRAINT "race_predictions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."race_predictions"
    ADD CONSTRAINT "race_predictions_vdot_score_id_fkey" FOREIGN KEY ("vdot_score_id") REFERENCES "public"."vdot_scores"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."training_load_metrics"
    ADD CONSTRAINT "training_load_metrics_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."training_notes"
    ADD CONSTRAINT "training_notes_athlete_id_fkey" FOREIGN KEY ("athlete_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."training_notes"
    ADD CONSTRAINT "training_notes_coach_id_fkey" FOREIGN KEY ("coach_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."training_notes"
    ADD CONSTRAINT "training_notes_training_plan_id_fkey" FOREIGN KEY ("training_plan_id") REFERENCES "public"."training_plans"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."training_plans"
    ADD CONSTRAINT "training_plans_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."training_zones"
    ADD CONSTRAINT "training_zones_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."training_zones"
    ADD CONSTRAINT "training_zones_vdot_score_id_fkey" FOREIGN KEY ("vdot_score_id") REFERENCES "public"."vdot_scores"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_profiles"
    ADD CONSTRAINT "user_profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."vdot_scores"
    ADD CONSTRAINT "vdot_scores_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."weekly_workouts"
    ADD CONSTRAINT "weekly_workouts_training_plan_id_fkey" FOREIGN KEY ("training_plan_id") REFERENCES "public"."training_plans"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."weekly_workouts"
    ADD CONSTRAINT "weekly_workouts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."user_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."year_statistics"
    ADD CONSTRAINT "year_statistics_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Users can delete own activities" ON "public"."activities" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can delete own conversations" ON "public"."chat_conversations" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can delete own messages" ON "public"."chat_messages" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can delete their own Garmin devices" ON "public"."garmin_devices" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert own Garmin activities" ON "public"."garmin_activities" FOR INSERT WITH CHECK (("auth"."uid"() = "athlete_id"));



CREATE POLICY "Users can insert own Garmin connections" ON "public"."garmin_connections" FOR INSERT WITH CHECK (("auth"."uid"() = "athlete_id"));



CREATE POLICY "Users can insert own activities" ON "public"."activities" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert own athlete profile" ON "public"."athlete_profiles" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert own conversations" ON "public"."chat_conversations" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert own messages" ON "public"."chat_messages" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert own pace progression" ON "public"."pace_progression" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert own personal bests" ON "public"."personal_bests" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert own pushed workouts" ON "public"."garmin_pushed_workouts" FOR INSERT WITH CHECK (("auth"."uid"() = "athlete_id"));



CREATE POLICY "Users can insert own year statistics" ON "public"."year_statistics" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert their own Garmin devices" ON "public"."garmin_devices" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can read own activities" ON "public"."activities" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can read own bests" ON "public"."personal_bests" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can read own pace" ON "public"."pace_progression" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can read own profile" ON "public"."user_profiles" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can read own stats" ON "public"."year_statistics" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own Garmin connections" ON "public"."garmin_connections" FOR UPDATE USING (("auth"."uid"() = "athlete_id"));



CREATE POLICY "Users can update own activities" ON "public"."activities" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own athlete profile" ON "public"."athlete_profiles" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own conversations" ON "public"."chat_conversations" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own messages" ON "public"."chat_messages" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own pace progression" ON "public"."pace_progression" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own personal bests" ON "public"."personal_bests" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own profile" ON "public"."user_profiles" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Users can update own pushed workouts" ON "public"."garmin_pushed_workouts" FOR UPDATE USING (("auth"."uid"() = "athlete_id"));



CREATE POLICY "Users can update own year statistics" ON "public"."year_statistics" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update their own Garmin devices" ON "public"."garmin_devices" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view own Garmin activities" ON "public"."garmin_activities" FOR SELECT USING (("auth"."uid"() = "athlete_id"));



CREATE POLICY "Users can view own Garmin connections" ON "public"."garmin_connections" FOR SELECT USING (("auth"."uid"() = "athlete_id"));



CREATE POLICY "Users can view own activities" ON "public"."activities" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view own athlete profile" ON "public"."athlete_profiles" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view own conversations" ON "public"."chat_conversations" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view own messages" ON "public"."chat_messages" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view own pace progression" ON "public"."pace_progression" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view own personal bests" ON "public"."personal_bests" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view own pushed workouts" ON "public"."garmin_pushed_workouts" FOR SELECT USING (("auth"."uid"() = "athlete_id"));



CREATE POLICY "Users can view own year statistics" ON "public"."year_statistics" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view their own Garmin devices" ON "public"."garmin_devices" FOR SELECT USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."activities" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ai_protocol_reviews" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."athlete_profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "athletes_view_own_protocols" ON "public"."ai_protocol_reviews" FOR SELECT TO "authenticated" USING (("athlete_id" = "auth"."uid"()));



ALTER TABLE "public"."chat_conversations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."chat_messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."check_in_schedules" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."coach_athlete_relationships" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "coaches_and_athletes_view_checkins" ON "public"."check_in_schedules" FOR SELECT TO "authenticated" USING ((("coach_id" = "auth"."uid"()) OR ("athlete_id" = "auth"."uid"())));



CREATE POLICY "coaches_and_athletes_view_notes" ON "public"."training_notes" FOR SELECT TO "authenticated" USING ((("coach_id" = "auth"."uid"()) OR (("athlete_id" = "auth"."uid"()) AND ("is_read" = true))));



CREATE POLICY "coaches_and_athletes_view_overrides" ON "public"."mileage_overrides" FOR SELECT TO "authenticated" USING ((("coach_id" = "auth"."uid"()) OR ("athlete_id" = "auth"."uid"())));



CREATE POLICY "coaches_create_protocols" ON "public"."ai_protocol_reviews" FOR INSERT TO "authenticated" WITH CHECK (("public"."is_coach_from_auth"() AND ("coach_id" = "auth"."uid"())));



CREATE POLICY "coaches_manage_check_in_schedules" ON "public"."check_in_schedules" TO "authenticated" USING (("public"."is_coach_from_auth"() AND ("coach_id" = "auth"."uid"()))) WITH CHECK (("public"."is_coach_from_auth"() AND ("coach_id" = "auth"."uid"())));



CREATE POLICY "coaches_manage_mileage_overrides" ON "public"."mileage_overrides" TO "authenticated" USING (("public"."is_coach_from_auth"() AND ("coach_id" = "auth"."uid"()))) WITH CHECK (("public"."is_coach_from_auth"() AND ("coach_id" = "auth"."uid"())));



CREATE POLICY "coaches_manage_own_protocol_notifications" ON "public"."protocol_review_notifications" TO "authenticated" USING (("coach_id" = "auth"."uid"())) WITH CHECK (("coach_id" = "auth"."uid"()));



CREATE POLICY "coaches_manage_own_relationships" ON "public"."coach_athlete_relationships" TO "authenticated" USING (("public"."is_coach_from_auth"() AND ("coach_id" = "auth"."uid"()))) WITH CHECK (("public"."is_coach_from_auth"() AND ("coach_id" = "auth"."uid"())));



CREATE POLICY "coaches_manage_training_notes" ON "public"."training_notes" TO "authenticated" USING (("public"."is_coach_from_auth"() AND ("coach_id" = "auth"."uid"()))) WITH CHECK (("public"."is_coach_from_auth"() AND ("coach_id" = "auth"."uid"())));



CREATE POLICY "coaches_update_assigned_protocols" ON "public"."ai_protocol_reviews" FOR UPDATE TO "authenticated" USING (("public"."is_coach_from_auth"() AND ("coach_id" = "auth"."uid"()))) WITH CHECK (("public"."is_coach_from_auth"() AND ("coach_id" = "auth"."uid"())));



CREATE POLICY "coaches_view_assigned_protocols" ON "public"."ai_protocol_reviews" FOR SELECT TO "authenticated" USING (("public"."is_coach_from_auth"() AND ("coach_id" = "auth"."uid"())));



CREATE POLICY "coaches_view_own_relationships" ON "public"."coach_athlete_relationships" FOR SELECT TO "authenticated" USING ((("coach_id" = "auth"."uid"()) OR ("athlete_id" = "auth"."uid"())));



ALTER TABLE "public"."garmin_activities" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."garmin_connections" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."garmin_devices" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."garmin_pushed_workouts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."mileage_overrides" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notification_preferences" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."pace_progression" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."personal_bests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."protocol_review_notifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."race_predictions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."training_load_metrics" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."training_notes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."training_plans" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."training_zones" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "users_manage_own_notification_preferences" ON "public"."notification_preferences" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "users_manage_own_notifications" ON "public"."notifications" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "users_manage_own_race_predictions" ON "public"."race_predictions" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "users_manage_own_training_load_metrics" ON "public"."training_load_metrics" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "users_manage_own_training_plans" ON "public"."training_plans" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "users_manage_own_training_zones" ON "public"."training_zones" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "users_manage_own_user_profiles" ON "public"."user_profiles" TO "authenticated" USING (("id" = "auth"."uid"())) WITH CHECK (("id" = "auth"."uid"()));



CREATE POLICY "users_manage_own_vdot_scores" ON "public"."vdot_scores" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "users_manage_own_weekly_workouts" ON "public"."weekly_workouts" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."vdot_scores" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."weekly_workouts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."year_statistics" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";





























































































































































































GRANT ALL ON FUNCTION "public"."calculate_vdot_from_race"("race_distance_km" numeric, "race_time_seconds" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_vdot_from_race"("race_distance_km" numeric, "race_time_seconds" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_vdot_from_race"("race_distance_km" numeric, "race_time_seconds" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."check_missed_workouts"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_missed_workouts"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_missed_workouts"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_performance_decline"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_performance_decline"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_performance_decline"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_urgent_checkins"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_urgent_checkins"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_urgent_checkins"() TO "service_role";



GRANT ALL ON FUNCTION "public"."create_athlete_profile_for_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."create_athlete_profile_for_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_athlete_profile_for_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."create_coach_alert"("p_coach_id" "uuid", "p_athlete_id" "uuid", "p_alert_type" "public"."coach_alert_type", "p_title" "text", "p_message" "text", "p_metadata" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."create_coach_alert"("p_coach_id" "uuid", "p_athlete_id" "uuid", "p_alert_type" "public"."coach_alert_type", "p_title" "text", "p_message" "text", "p_metadata" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_coach_alert"("p_coach_id" "uuid", "p_athlete_id" "uuid", "p_alert_type" "public"."coach_alert_type", "p_title" "text", "p_message" "text", "p_metadata" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_protocol_review_notification"() TO "anon";
GRANT ALL ON FUNCTION "public"."create_protocol_review_notification"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_protocol_review_notification"() TO "service_role";



GRANT ALL ON FUNCTION "public"."delete_expired_notifications"() TO "anon";
GRANT ALL ON FUNCTION "public"."delete_expired_notifications"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_expired_notifications"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_pace_for_vdot_and_zone"("vdot_value" numeric, "zone_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_pace_for_vdot_and_zone"("vdot_value" numeric, "zone_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_pace_for_vdot_and_zone"("vdot_value" numeric, "zone_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_unread_notification_count"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_unread_notification_count"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_unread_notification_count"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_assigned_coach"("athlete_uuid" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_assigned_coach"("athlete_uuid" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_assigned_coach"("athlete_uuid" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_assigned_coach_for_protocol"("protocol_uuid" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_assigned_coach_for_protocol"("protocol_uuid" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_assigned_coach_for_protocol"("protocol_uuid" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_coach_from_auth"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_coach_from_auth"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_coach_from_auth"() TO "service_role";



GRANT ALL ON FUNCTION "public"."mark_all_notifications_read"() TO "anon";
GRANT ALL ON FUNCTION "public"."mark_all_notifications_read"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_all_notifications_read"() TO "service_role";



GRANT ALL ON FUNCTION "public"."mark_notification_read"("notification_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."mark_notification_read"("notification_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_notification_read"("notification_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_athlete_on_protocol_decision"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_athlete_on_protocol_decision"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_athlete_on_protocol_decision"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_missed_workout_alert"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_missed_workout_alert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_missed_workout_alert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_performance_alert"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_performance_alert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_performance_alert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_readiness_decline_alert"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_readiness_decline_alert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_readiness_decline_alert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_athlete_statistics"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_athlete_statistics"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_athlete_statistics"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_conversation_timestamp"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_conversation_timestamp"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_conversation_timestamp"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_protocol_review_timestamp"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_protocol_review_timestamp"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_protocol_review_timestamp"() TO "service_role";
























GRANT ALL ON TABLE "public"."activities" TO "anon";
GRANT ALL ON TABLE "public"."activities" TO "authenticated";
GRANT ALL ON TABLE "public"."activities" TO "service_role";



GRANT ALL ON TABLE "public"."ai_protocol_reviews" TO "anon";
GRANT ALL ON TABLE "public"."ai_protocol_reviews" TO "authenticated";
GRANT ALL ON TABLE "public"."ai_protocol_reviews" TO "service_role";



GRANT ALL ON TABLE "public"."athlete_profiles" TO "anon";
GRANT ALL ON TABLE "public"."athlete_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."athlete_profiles" TO "service_role";



GRANT ALL ON TABLE "public"."chat_conversations" TO "anon";
GRANT ALL ON TABLE "public"."chat_conversations" TO "authenticated";
GRANT ALL ON TABLE "public"."chat_conversations" TO "service_role";



GRANT ALL ON TABLE "public"."chat_messages" TO "anon";
GRANT ALL ON TABLE "public"."chat_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."chat_messages" TO "service_role";



GRANT ALL ON TABLE "public"."check_in_schedules" TO "anon";
GRANT ALL ON TABLE "public"."check_in_schedules" TO "authenticated";
GRANT ALL ON TABLE "public"."check_in_schedules" TO "service_role";



GRANT ALL ON TABLE "public"."coach_athlete_relationships" TO "anon";
GRANT ALL ON TABLE "public"."coach_athlete_relationships" TO "authenticated";
GRANT ALL ON TABLE "public"."coach_athlete_relationships" TO "service_role";



GRANT ALL ON TABLE "public"."garmin_activities" TO "anon";
GRANT ALL ON TABLE "public"."garmin_activities" TO "authenticated";
GRANT ALL ON TABLE "public"."garmin_activities" TO "service_role";



GRANT ALL ON TABLE "public"."garmin_connections" TO "anon";
GRANT ALL ON TABLE "public"."garmin_connections" TO "authenticated";
GRANT ALL ON TABLE "public"."garmin_connections" TO "service_role";



GRANT ALL ON TABLE "public"."garmin_devices" TO "anon";
GRANT ALL ON TABLE "public"."garmin_devices" TO "authenticated";
GRANT ALL ON TABLE "public"."garmin_devices" TO "service_role";



GRANT ALL ON TABLE "public"."garmin_pushed_workouts" TO "anon";
GRANT ALL ON TABLE "public"."garmin_pushed_workouts" TO "authenticated";
GRANT ALL ON TABLE "public"."garmin_pushed_workouts" TO "service_role";



GRANT ALL ON TABLE "public"."mileage_overrides" TO "anon";
GRANT ALL ON TABLE "public"."mileage_overrides" TO "authenticated";
GRANT ALL ON TABLE "public"."mileage_overrides" TO "service_role";



GRANT ALL ON TABLE "public"."notification_preferences" TO "anon";
GRANT ALL ON TABLE "public"."notification_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."notification_preferences" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."pace_progression" TO "anon";
GRANT ALL ON TABLE "public"."pace_progression" TO "authenticated";
GRANT ALL ON TABLE "public"."pace_progression" TO "service_role";



GRANT ALL ON TABLE "public"."personal_bests" TO "anon";
GRANT ALL ON TABLE "public"."personal_bests" TO "authenticated";
GRANT ALL ON TABLE "public"."personal_bests" TO "service_role";



GRANT ALL ON TABLE "public"."protocol_review_notifications" TO "anon";
GRANT ALL ON TABLE "public"."protocol_review_notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."protocol_review_notifications" TO "service_role";



GRANT ALL ON TABLE "public"."race_predictions" TO "anon";
GRANT ALL ON TABLE "public"."race_predictions" TO "authenticated";
GRANT ALL ON TABLE "public"."race_predictions" TO "service_role";



GRANT ALL ON TABLE "public"."training_load_metrics" TO "anon";
GRANT ALL ON TABLE "public"."training_load_metrics" TO "authenticated";
GRANT ALL ON TABLE "public"."training_load_metrics" TO "service_role";



GRANT ALL ON TABLE "public"."training_notes" TO "anon";
GRANT ALL ON TABLE "public"."training_notes" TO "authenticated";
GRANT ALL ON TABLE "public"."training_notes" TO "service_role";



GRANT ALL ON TABLE "public"."training_plans" TO "anon";
GRANT ALL ON TABLE "public"."training_plans" TO "authenticated";
GRANT ALL ON TABLE "public"."training_plans" TO "service_role";



GRANT ALL ON TABLE "public"."training_zones" TO "anon";
GRANT ALL ON TABLE "public"."training_zones" TO "authenticated";
GRANT ALL ON TABLE "public"."training_zones" TO "service_role";



GRANT ALL ON TABLE "public"."user_profiles" TO "anon";
GRANT ALL ON TABLE "public"."user_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."user_profiles" TO "service_role";



GRANT ALL ON TABLE "public"."vdot_scores" TO "anon";
GRANT ALL ON TABLE "public"."vdot_scores" TO "authenticated";
GRANT ALL ON TABLE "public"."vdot_scores" TO "service_role";



GRANT ALL ON TABLE "public"."weekly_workouts" TO "anon";
GRANT ALL ON TABLE "public"."weekly_workouts" TO "authenticated";
GRANT ALL ON TABLE "public"."weekly_workouts" TO "service_role";



GRANT ALL ON TABLE "public"."year_statistics" TO "anon";
GRANT ALL ON TABLE "public"."year_statistics" TO "authenticated";
GRANT ALL ON TABLE "public"."year_statistics" TO "service_role";









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































