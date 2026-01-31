import { createClient } from "@supabase/supabase-js";

const supabaseUrl = "https://yawxlwcniqfspcgefuro.supabase.co";
const supabaseKey =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlhd3hsd2NuaXFmc3BjZ2VmdXJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzczNTM2NzUsImV4cCI6MjA1MjkyOTY3NX0.1pQ8K9zqFZYXH5EqZ9VgZ8YzJYoq3xQp0Xq7c5nX9Xo";

export const supabase = createClient(supabaseUrl, supabaseKey);
