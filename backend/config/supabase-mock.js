// Mock Supabase client for testing routes without database connection
const createMockSupabase = () => ({
  from: (table) => ({
    select: (columns) => ({
      eq: (col, val) => ({
        single: () => Promise.resolve({ data: null, error: null }),
        maybeSingle: () => Promise.resolve({ data: null, error: null }),
        then: (resolve) => resolve({ data: [], error: null })
      }),
      single: () => Promise.resolve({ data: null, error: null }),
      maybeSingle: () => Promise.resolve({ data: null, error: null }),
      then: (resolve) => resolve({ data: [], error: null })
    }),
    insert: (data) => ({
      select: () => ({
        single: () => Promise.resolve({ data: null, error: null }),
        then: (resolve) => resolve({ data: null, error: null })
      }),
      then: (resolve) => resolve({ data: null, error: null })
    }),
    update: (data) => ({
      eq: (col, val) => ({
        select: () => ({
          single: () => Promise.resolve({ data: null, error: null }),
          then: (resolve) => resolve({ data: null, error: null })
        }),
        then: (resolve) => resolve({ data: null, error: null })
      }),
      then: (resolve) => resolve({ data: null, error: null })
    }),
    delete: () => ({
      eq: (col, val) => Promise.resolve({ data: null, error: null }),
      then: (resolve) => resolve({ data: null, error: null })
    }),
    upsert: (data, options) => ({
      select: () => ({
        single: () => Promise.resolve({ data: null, error: null }),
        then: (resolve) => resolve({ data: null, error: null })
      }),
      then: (resolve) => resolve({ data: null, error: null })
    })
  }),
  rpc: (fn, params) => Promise.resolve({ data: null, error: null }),
  auth: {
    signUp: () => Promise.resolve({ data: { user: null, session: null }, error: null }),
    signInWithPassword: () => Promise.resolve({ data: { user: null, session: null }, error: null })
  }
});

module.exports = createMockSupabase();
