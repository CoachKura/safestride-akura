// ============================================
// AKURA SafeStride - Authentication Module
// ============================================

console.log('🚀 Loading AKURA Auth Module...');

// ============================================
// SUPABASE CONFIGURATION
// ============================================
// Get credentials from: https://supabase.com/dashboard → Settings → API

// Project URL - Get from: Settings → API → Project URL
const AKURA_SUPABASE_URL = 'https://yawxlwcniqfspcgefuro.supabase.co';

// Anon Public Key - Get from: Settings → API → anon public
const AKURA_SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlhd3hsd2NuaXFmc3BjZ2VmdXJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk0OTcxODksImV4cCI6MjA4NTA3MzE4OX0.eky8ua6lEhzPcvG289wWDMWOjVGwr-bL8LLUnrzO4r4';

// Initialize Supabase Client
let akuraSupabaseClient = null;

// Initialize when script loads
(function initializeAkuraAuth() {
    console.log('🚀 Initializing Supabase...');
    
    // Log connection details
    console.log('📍 URL:', AKURA_SUPABASE_URL);
    console.log('🔑 Key (first 20):', AKURA_SUPABASE_KEY ? AKURA_SUPABASE_KEY.substring(0, 20) + '...' : 'NOT SET');
    
    // Check if credentials are configured
    if (AKURA_SUPABASE_URL.includes('YOUR_') || AKURA_SUPABASE_KEY.includes('YOUR_')) {
        console.error('❌ CREDENTIALS NOT CONFIGURED!');
        console.error('Please update AKURA_SUPABASE_URL and AKURA_SUPABASE_KEY in auth.js');
        return;
    }
    
    // Check if Supabase library is loaded
    if (typeof window.supabase === 'undefined') {
        console.error('❌ Supabase library not loaded!');
        console.error('Add this to your HTML: <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>');
        return;
    }
    
    try {
        // Create Supabase client
        akuraSupabaseClient = window.supabase.createClient(
            AKURA_SUPABASE_URL,
            AKURA_SUPABASE_KEY
        );
        
        console.log('✅ Supabase client initialized');
        console.log('📍 Connected to:', AKURA_SUPABASE_URL);
    } catch (error) {
        console.error('❌ Failed to initialize Supabase:', error);
    }
})();

// Export authentication functions
window.AkuraAuth = {
    // Check if ready
    isReady: function() {
        return akuraSupabaseClient !== null;
    },
    
    // Get Supabase client
    getClient: function() {
        if (!akuraSupabaseClient) {
            throw new Error('Supabase client not initialized');
        }
        return akuraSupabaseClient;
    },
    
    // Provide direct access to Supabase client (for database queries)
    get supabase() {
        return akuraSupabaseClient;
    },
    
    // Sign Up
    signUp: async function(email, password, metadata = {}) {
        console.log('🎯 Starting signup...');
        console.log('📧 Email:', email);
        console.log('📦 Metadata:', metadata);
        
        if (!akuraSupabaseClient) {
            console.error('❌ Supabase client not initialized');
            return { data: null, error: new Error('Supabase client not initialized') };
        }
        
        try {
            console.log('📤 Calling Supabase signUp...');
            const { data, error } = await akuraSupabaseClient.auth.signUp({
                email: email,
                password: password,
                options: {
                    data: metadata
                }
            });
            
            if (error) {
                console.error('❌ Signup failed:', error);
                console.error('Error message:', error.message);
                console.error('Error status:', error.status);
                return { data: null, error: error };
            }
            
            const user = data.user || null;
            if (user && user.id) {
                console.log('✅ User created in auth:', user.id);
            } else {
                console.log('✅ User created!');
            }
            
            // Create profile record in database AFTER auth user creation
            let profile = null;
            if (user) {
                try {
                    console.log('📝 Creating profile record...');
                    const insertPayload = {
                        id: user.id,
                        full_name: metadata.full_name || '',
                        email: email,
                        role: metadata.role || 'athlete',
                        access_level: (metadata.access_level || 'demo'),
                        assessment_completed: false,
                        created_at: new Date().toISOString()
                    };

                    const { data: profileRows, error: profileError } = await akuraSupabaseClient
                        .from('profiles')
                        .insert(insertPayload)
                        .select('*')
                        .single();

                    if (profileError) {
                        console.error('⚠️ Profile creation error:', profileError);
                    } else {
                        profile = profileRows;
                        console.log('✅ Profile created successfully');
                    }
                } catch (profileError) {
                    console.error('⚠️ Profile creation failed:', profileError);
                    // Continue anyway
                }
            }
            
            return { data: { user, profile }, error: null };
        } catch (error) {
            console.error('❌ Signup failed with exception:', error);
            return { data: null, error: error };
        }
    },
    
    // Sign In
    signIn: async function(email, password) {
        console.log('🎯 Starting signin...');
        console.log('📧 Email:', email);
        
        if (!akuraSupabaseClient) {
            console.error('❌ Supabase client not initialized');
            return { user: null, session: null, error: new Error('Supabase client not initialized') };
        }
        
        try {
            console.log('📤 Calling Supabase signInWithPassword...');
            const { data, error } = await akuraSupabaseClient.auth.signInWithPassword({
                email: email,
                password: password
            });
            
            if (error) {
                console.error('❌ Login failed:', error);
                console.error('Error message:', error.message);
                return { user: null, session: null, error: error };
            }
            
            console.log('✅ Login successful!');
            console.log('User ID:', data.user?.id);
            
            return {
                user: data.user,
                session: data.session,
                error: null
            };
        } catch (error) {
            console.error('❌ Login failed with exception:', error);
            return { user: null, session: null, error: error };
        }
    },
    
    // Sign Out
    signOut: async function() {
        console.log('🎯 Starting signout...');
        
        if (!akuraSupabaseClient) {
            console.error('❌ Supabase client not initialized');
            return { error: new Error('Supabase client not initialized') };
        }
        
        try {
            console.log('📤 Calling Supabase signOut...');
            const { error } = await akuraSupabaseClient.auth.signOut();
            
            if (error) {
                console.error('❌ Signout failed:', error);
                return { error: error };
            }
            
            console.log('✅ Signed out successfully!');
            return { error: null };
        } catch (error) {
            console.error('❌ Signout failed with exception:', error);
            return { error: error };
        }
    },
    
    // Get Current User
    getCurrentUser: async function() {
        console.log('🎯 Getting current user...');
        
        if (!akuraSupabaseClient) {
            console.error('❌ Supabase client not initialized');
            return null;
        }
        
        try {
            const { data: { user }, error } = await akuraSupabaseClient.auth.getUser();
            
            if (error) {
                console.error('❌ Get user failed:', error);
                return null;
            }
            
            if (user) {
                console.log('✅ User found:', user.id);
            } else {
                console.log('ℹ️ No user logged in');
            }
            
            return user;
        } catch (error) {
            console.error('❌ Get user failed with exception:', error);
            return null;
        }
    },
    
    // Get Session
    getSession: async function() {
        console.log('🎯 Getting session...');
        
        if (!akuraSupabaseClient) {
            console.error('❌ Supabase client not initialized');
            return null;
        }
        
        try {
            const { data: { session }, error } = await akuraSupabaseClient.auth.getSession();
            
            if (error) {
                console.error('❌ Get session failed:', error);
                return null;
            }
            
            if (session) {
                console.log('✅ Session found');
            } else {
                console.log('ℹ️ No active session');
            }
            
            return session;
        } catch (error) {
            console.error('❌ Get session failed with exception:', error);
            return null;
        }
    },
    
    // Reset Password
    resetPassword: async function(email) {
        console.log('🎯 Starting password reset...');
        console.log('📧 Email:', email);
        
        if (!akuraSupabaseClient) {
            console.error('❌ Supabase client not initialized');
            return { data: null, error: new Error('Supabase client not initialized') };
        }
        
        try {
            console.log('📤 Calling Supabase resetPasswordForEmail...');
            const { data, error } = await akuraSupabaseClient.auth.resetPasswordForEmail(email, {
                redirectTo: window.location.origin + '/reset-password.html'
            });
            
            if (error) {
                console.error('❌ Reset password failed:', error);
                return { data: null, error: error };
            }
            
            console.log('✅ Password reset email sent!');
            return { data: data, error: null };
        } catch (error) {
            console.error('❌ Reset password failed with exception:', error);
            return { data: null, error: error };
        }
    },
    
    // Update Password
    updatePassword: async function(newPassword) {
        console.log('🎯 Starting password update...');
        
        if (!akuraSupabaseClient) {
            console.error('❌ Supabase client not initialized');
            return { data: null, error: new Error('Supabase client not initialized') };
        }
        
        try {
            console.log('📤 Calling Supabase updateUser...');
            const { data, error } = await akuraSupabaseClient.auth.updateUser({
                password: newPassword
            });
            
            if (error) {
                console.error('❌ Password update failed:', error);
                return { data: null, error: error };
            }
            
            console.log('✅ Password updated successfully!');
            return { data: data, error: null };
        } catch (error) {
            console.error('❌ Password update failed with exception:', error);
            return { data: null, error: error };
        }
    }
};

console.log('✅ AKURA Auth Module Loaded');
console.log('✅ Ready:', window.AkuraAuth.isReady());