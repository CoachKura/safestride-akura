// ============================================
// AKURA SafeStride - Authentication Module
// ============================================

console.log('🚀 Loading AKURA Auth Module...');

// Supabase Configuration
const AKURA_SUPABASE_URL = 'https://yawxlwcniqfspcgefuro.supabase.co';
const AKURA_SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlhd3hsd2NuaXFmc3BjZ2VmdXJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk0OTcxODksImV4cCI6MjA4NTA3MzE4OX0.eky8ua6lEhzPcvG289wWDMWOjVGwr-bL8LLUnrzO4r4';

// Initialize Supabase Client
let akuraSupabaseClient = null;

// Initialize when script loads
(function initializeAkuraAuth() {
    console.log('🔧 Initializing AKURA Auth...');
    
    // Check if Supabase library is loaded
    if (typeof window.supabase === 'undefined') {
        console.error('❌ Supabase library not loaded!');
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
    
    // Sign Up
    signUp: async function(email, password, metadata = {}) {
        console.log('📝 Attempting signup for:', email);
        console.log('📍 Using Supabase URL:', AKURA_SUPABASE_URL);
        console.log('🔑 Key configured:', AKURA_SUPABASE_KEY ? 'YES' : 'NO');
        
        if (!akuraSupabaseClient) {
            console.error('❌ Supabase client not initialized');
            throw new Error('Supabase client not initialized. Please check your credentials.');
        }
        
        try {
            const { data, error } = await akuraSupabaseClient.auth.signUp({
                email: email,
                password: password,
                options: {
                    data: metadata
                }
            });
            
            if (error) {
                console.error('❌ Signup error from Supabase:', error);
                console.error('❌ Error message:', error.message);
                console.error('❌ Error status:', error.status);
                throw error;
            }
            
            console.log('✅ Signup successful');
            console.log('✅ User data:', data);
            return data;
        } catch (error) {
            console.error('❌ Signup failed with exception:', error);
            throw error;
        }
    },
    
    // Sign In
    signIn: async function(email, password) {
        console.log('🔐 Attempting login for:', email);
        
        if (!akuraSupabaseClient) {
            throw new Error('Supabase client not initialized');
        }
        
        try {
            const { data, error } = await akuraSupabaseClient.auth.signInWithPassword({
                email: email,
                password: password
            });
            
            if (error) {
                console.error('❌ Login error:', error);
                throw error;
            }
            
            console.log('✅ Login successful');
            return data;
        } catch (error) {
            console.error('❌ Login failed:', error);
            throw error;
        }
    },
    
    // Sign Out
    signOut: async function() {
        console.log('👋 Signing out...');
        
        if (!akuraSupabaseClient) {
            throw new Error('Supabase client not initialized');
        }
        
        try {
            const { error } = await akuraSupabaseClient.auth.signOut();
            
            if (error) {
                console.error('❌ Signout error:', error);
                throw error;
            }
            
            console.log('✅ Signed out successfully');
        } catch (error) {
            console.error('❌ Signout failed:', error);
            throw error;
        }
    },
    
    // Get Current User
    getCurrentUser: async function() {
        if (!akuraSupabaseClient) {
            return null;
        }
        
        try {
            const { data: { user }, error } = await akuraSupabaseClient.auth.getUser();
            
            if (error) {
                console.error('❌ Get user error:', error);
                return null;
            }
            
            return user;
        } catch (error) {
            console.error('❌ Get user failed:', error);
            return null;
        }
    },
    
    // Get Session
    getSession: async function() {
        if (!akuraSupabaseClient) {
            return null;
        }
        
        try {
            const { data: { session }, error } = await akuraSupabaseClient.auth.getSession();
            
            if (error) {
                console.error('❌ Get session error:', error);
                return null;
            }
            
            return session;
        } catch (error) {
            console.error('❌ Get session failed:', error);
            return null;
        }
    },
    
    // Reset Password
    resetPassword: async function(email) {
        console.log('🔑 Requesting password reset for:', email);
        
        if (!akuraSupabaseClient) {
            throw new Error('Supabase client not initialized');
        }
        
        try {
            const { data, error } = await akuraSupabaseClient.auth.resetPasswordForEmail(email, {
                redirectTo: window.location.origin + '/reset-password.html'
            });
            
            if (error) {
                console.error('❌ Reset password error:', error);
                throw error;
            }
            
            console.log('✅ Password reset email sent');
            return data;
        } catch (error) {
            console.error('❌ Reset password failed:', error);
            throw error;
        }
    },
    
    // Update Password
    updatePassword: async function(newPassword) {
        console.log('🔒 Updating password...');
        
        if (!akuraSupabaseClient) {
            throw new Error('Supabase client not initialized');
        }
        
        try {
            const { data, error } = await akuraSupabaseClient.auth.updateUser({
                password: newPassword
            });
            
            if (error) {
                console.error('❌ Update password error:', error);
                throw error;
            }
            
            console.log('✅ Password updated successfully');
            return data;
        } catch (error) {
            console.error('❌ Update password failed:', error);
            throw error;
        }
    }
};

console.log('✅ AKURA Auth Module Loaded');
console.log('✅ Ready:', window.AkuraAuth.isReady());