import { createClient } from "@supabase/supabase-js";
import offlineQueue from "./offlineQueue";

const supabaseUrl = "https://yawxlwcniqfspcgefuro.supabase.co";
const supabaseKey =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlhd3hsd2NuaXFmc3BjZ2VmdXJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzczNTM2NzUsImV4cCI6MjA1MjkyOTY3NX0.1pQ8K9zqFZYXH5EqZ9VgZ8YzJYoq3xQp0Xq7c5nX9Xo";

export const supabase = createClient(supabaseUrl, supabaseKey);

async function safeInsert(table, data) {
  try {
    const { data: result, error } = await supabase.from(table).insert(data).select().single();
    return { data: result, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

export async function offlineInsert(table, data) {
  if (!navigator.onLine) {
    await offlineQueue.addToQueue("insert", table, data);
    return { data: null, error: null, queued: true };
  }

  const { data: result, error } = await safeInsert(table, data);

  if (error) {
    // Queue for retry
    await offlineQueue.addToQueue("insert", table, data);
    return { data: null, error, queued: true };
  }

  return { data: result, error: null, queued: false };
}

export async function offlineUpdate(table, id, updates) {
  if (navigator.onLine) {
    try {
      const { data: result, error } = await supabase
        .from(table)
        .update(updates)
        .eq("id", id);
      if (error) throw error;
      return { data: result, error: null, queued: false };
    } catch (error) {
      console.error("Update failed, queuing for later:", error);
      await offlineQueue.addToQueue("update", table, { id, updates });
      return { data: null, error, queued: true };
    }
  } else {
    console.log("Offline - queuing update");
    await offlineQueue.addToQueue("update", table, { id, updates });
    return { data: null, error: null, queued: true };
  }
}

export async function offlineDelete(table, id) {
  if (navigator.onLine) {
    try {
      const { error } = await supabase.from(table).delete().eq("id", id);
      if (error) throw error;
      return { error: null, queued: false };
    } catch (error) {
      console.error("Delete failed, queuing for later:", error);
      await offlineQueue.addToQueue("delete", table, { id });
      return { error, queued: true };
    }
  } else {
    console.log("Offline - queuing delete");
    await offlineQueue.addToQueue("delete", table, { id });
    return { error: null, queued: true };
  }
}
