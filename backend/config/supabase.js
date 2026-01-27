// AKURA SafeStride Backend - Supabase Configuration
// Last Updated: 2026-01-27

const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

let supabase;

try {
  if (!supabaseUrl) {
    throw new Error('Missing SUPABASE_URL environment variable');
  }
  
  if (!supabaseServiceKey && !supabaseAnonKey) {
    throw new Error('Missing Supabase key: Either SUPABASE_SERVICE_KEY or SUPABASE_ANON_KEY required');
  }
  
  // Prefer service role key for admin operations, fallback to anon key
  const supabaseKey = supabaseServiceKey || supabaseAnonKey;
  const isServiceRole = !!supabaseServiceKey;
  
  // Initialize Supabase client
  supabase = createClient(supabaseUrl, supabaseKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  });
  
  console.log(`✅ Supabase client initialized (${isServiceRole ? 'service role' : 'anon key'})`);
} catch (error) {
  console.warn('⚠️  Supabase connection failed, using mock mode:', error.message);
  // Fallback to mock if Supabase not configured
  try {
    supabase = require('./supabase-mock');
  } catch (mockError) {
    // If mock doesn't exist, create minimal placeholder
    supabase = {
      from: () => ({
        select: () => Promise.resolve({ data: [], error: null }),
        insert: () => Promise.resolve({ data: null, error: null }),
        update: () => Promise.resolve({ data: null, error: null }),
        delete: () => Promise.resolve({ data: null, error: null })
      }),
      auth: {
        signIn: () => Promise.resolve({ data: null, error: null }),
        signUp: () => Promise.resolve({ data: null, error: null })
      }
    };
  }
}

// Helper function to execute raw SQL queries
async function query(sql, params = []) {
  try {
    const { data, error } = await supabase.rpc('exec_sql', {
      query: sql,
      params: params
    });
    
    if (error) throw error;
    return data;
  } catch (error) {
    console.log('[MOCK/ERROR] SQL query:', sql);
    return [];
  }
}

module.exports = {
  supabase,
  query
};
