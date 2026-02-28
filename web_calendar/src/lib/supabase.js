import { createClient } from "@supabase/supabase-js";

const supabaseUrl =
  import.meta.env.VITE_SUPABASE_URL ||
  "https://bdisppaxbvygsspcuymb.supabase.co";
const supabaseAnonKey =
  import.meta.env.VITE_SUPABASE_ANON_KEY ||
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkaXNwcGF4YnZ5Z3NzcGN1eW1iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyNDY4NDQsImV4cCI6MjA4NjgyMjg0NH0.bjgoVhVboDQTmIPe_A5_4yiWvTBvckVtw88lQ7GWFrc";

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

