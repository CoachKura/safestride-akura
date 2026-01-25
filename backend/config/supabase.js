const { createClient } = require('@supabase/supabase-js');
let supabase;

try {
  if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_KEY) {
    throw new Error('Missing Supabase environment variables');
  }
  
  supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    }
  );
  
  console.log('✅ Supabase client initialized');
} catch (error) {
  console.warn('⚠️  Supabase connection failed, using mock mode:', error.message);
  supabase = require('./supabase-mock');
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
