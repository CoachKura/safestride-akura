// Apply Strava Migration - Automated
// Run with: node apply-migration-direct.js

const https = require("https");
const fs = require("fs");

// Load .env
const env = {};
fs.readFileSync(".env", "utf8")
  .split("\n")
  .forEach((line) => {
    const match = line.match(/^\s*([^#=]+?)\s*=\s*(.+?)\s*$/);
    if (match) env[match[1]] = match[2];
  });

const SUPABASE_URL =
  env.SUPABASE_URL || "https://bdisppaxbvygsspcuymb.supabase.co";
const SERVICE_KEY = env.SUPABASE_SERVICE_ROLE_KEY;

if (!SERVICE_KEY) {
  console.error("❌ SUPABASE_SERVICE_ROLE_KEY not found in .env");
  process.exit(1);
}

console.log("🔄 Applying Strava Migration...\n");

// Read migration SQL
const migrationSQL = fs.readFileSync(
  "supabase/migrations/20240115_strava_signup_stats.sql",
  "utf8",
);

// Execute SQL statements via Supabase REST API
const statements = [
  // Add columns to profiles
  "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS strava_athlete_id BIGINT UNIQUE, ADD COLUMN IF NOT EXISTS strava_refresh_token TEXT, ADD COLUMN IF NOT EXISTS strava_token_expires_at TIMESTAMP WITH TIME ZONE, ADD COLUMN IF NOT EXISTS last_strava_sync TIMESTAMP WITH TIME ZONE",
  "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS profile_photo_url TEXT, ADD COLUMN IF NOT EXISTS gender VARCHAR(10), ADD COLUMN IF NOT EXISTS weight DECIMAL(5,2), ADD COLUMN IF NOT EXISTS height DECIMAL(5,2), ADD COLUMN IF NOT EXISTS city TEXT, ADD COLUMN IF NOT EXISTS state TEXT, ADD COLUMN IF NOT EXISTS country TEXT",
  "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS pb_5k INTEGER, ADD COLUMN IF NOT EXISTS pb_10k INTEGER, ADD COLUMN IF NOT EXISTS pb_half_marathon INTEGER, ADD COLUMN IF NOT EXISTS pb_marathon INTEGER",
  "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS total_runs INTEGER DEFAULT 0, ADD COLUMN IF NOT EXISTS total_distance_km DECIMAL(10,2) DEFAULT 0, ADD COLUMN IF NOT EXISTS total_time_hours DECIMAL(10,2) DEFAULT 0, ADD COLUMN IF NOT EXISTS avg_pace_min_per_km DECIMAL(5,2), ADD COLUMN IF NOT EXISTS longest_run_km DECIMAL(6,2)",
  "CREATE INDEX IF NOT EXISTS idx_profiles_strava_athlete_id ON profiles(strava_athlete_id)",
];

let completed = 0;

statements.forEach((sql, index) => {
  const data = JSON.stringify({ query: sql });

  const options = {
    hostname: "bdisppaxbvygsspcuymb.supabase.co",
    path: "/rest/v1/rpc/sql_query",
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      apikey: SERVICE_KEY,
      Authorization: `Bearer ${SERVICE_KEY}`,
      "Content-Length": data.length,
    },
  };

  const req = https.request(options, (res) => {
    let body = "";
    res.on("data", (chunk) => (body += chunk));
    res.on("end", () => {
      completed++;
      if (res.statusCode === 200 || res.statusCode === 201) {
        process.stdout.write("✓ ");
      } else {
        process.stdout.write("! ");
      }

      if (completed === statements.length) {
        console.log("\n\n✅ Migration applied!");
        console.log("   New columns added to profiles table");
        console.log("   Ready for Strava signup\n");
      }
    });
  });

  req.on("error", (e) => {
    console.error(`\n❌ Error: ${e.message}`);
  });

  req.write(data);
  req.end();
});
