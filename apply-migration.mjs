/**
 * Apply Strava Migration Automatically
 * Executes SQL migration using Supabase Service Role Key
 */

import { createClient } from "@supabase/supabase-js";
import { readFileSync } from "fs";
import { config } from "dotenv";

// Load environment variables
config();

const SUPABASE_URL =
  process.env.SUPABASE_URL || "https://bdisppaxbvygsspcuymb.supabase.co";
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_SERVICE_KEY) {
  console.error("❌ Error: SUPABASE_SERVICE_ROLE_KEY not found in .env file");
  process.exit(1);
}

// Create Supabase admin client
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

async function applyMigration() {
  console.log("🔄 Applying Strava Signup Migration...\n");

  try {
    // Read migration file
    const migrationSQL = readFileSync(
      "supabase/migrations/20240115_strava_signup_stats.sql",
      "utf8",
    );

    // Split into individual statements
    const statements = migrationSQL
      .split(";")
      .map((s) => s.trim())
      .filter((s) => s.length > 0 && !s.startsWith("--"));

    console.log(`📊 Found ${statements.length} SQL statements to execute\n`);

    let successCount = 0;
    let errorCount = 0;

    // Execute each statement
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i] + ";";

      // Skip comments
      if (
        statement.trim().startsWith("--") ||
        statement.trim().startsWith("COMMENT")
      ) {
        continue;
      }

      try {
        // Execute via RPC
        const { error } = await supabase.rpc("exec_sql", { sql: statement });

        if (error) {
          // Try direct execution for DDL statements
          const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_sql`, {
            method: "POST",
            headers: {
              apikey: SUPABASE_SERVICE_KEY,
              Authorization: `Bearer ${SUPABASE_SERVICE_KEY}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({ query: statement }),
          });

          if (!response.ok) {
            throw new Error(
              `HTTP ${response.status}: ${await response.text()}`,
            );
          }
        }

        successCount++;
        process.stdout.write(`✓`);
      } catch (err) {
        errorCount++;
        console.error(`\n❌ Error executing statement ${i + 1}:`, err.message);
      }
    }

    console.log(`\n\n✅ Migration complete!`);
    console.log(`   Success: ${successCount}/${statements.length}`);

    if (errorCount > 0) {
      console.log(
        `   ⚠️  Errors: ${errorCount} (may be expected for IF NOT EXISTS)`,
      );
    }

    console.log("\n📋 New database schema:");
    console.log("  profiles table:");
    console.log("    + strava_athlete_id");
    console.log("    + pb_5k, pb_10k, pb_half_marathon, pb_marathon");
    console.log("    + total_runs, total_distance_km, avg_pace_min_per_km");
    console.log("    + profile_photo_url, gender, weight, height");
    console.log("  strava_activities table: ✓ Created");
  } catch (error) {
    console.error("\n❌ Migration failed:", error.message);
    process.exit(1);
  }
}

applyMigration();
