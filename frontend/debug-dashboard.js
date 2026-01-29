// ============================================
// AKURA SafeStride - Dashboard Debug Helper
// ============================================
// Add this to browser console to debug dashboard data loading issues

async function debugDashboard() {
    console.log('🔍 DASHBOARD DEBUG UTILITY');
    console.log('='.repeat(50));
    
    // Check AkuraAuth
    console.log('\n1️⃣ Checking AkuraAuth Module...');
    if (!window.AkuraAuth) {
        console.error('❌ AkuraAuth not available!');
        return;
    }
    console.log('✅ AkuraAuth available');
    console.log('   Ready:', window.AkuraAuth.isReady());
    
    // Get current user
    console.log('\n2️⃣ Getting current user...');
    const user = await window.AkuraAuth.getCurrentUser();
    if (!user) {
        console.error('❌ No user logged in!');
        return;
    }
    console.log('✅ User authenticated');
    console.log('   ID:', user.id);
    console.log('   Email:', user.email);
    console.log('   Full object:', user);
    
    // Get Supabase client
    console.log('\n3️⃣ Getting Supabase client...');
    let supabase = null;
    try {
        supabase = window.AkuraAuth.getClient();
        console.log('✅ Supabase client available');
    } catch (e) {
        console.error('❌ Failed to get Supabase client:', e.message);
        return;
    }
    
    // Query profiles table
    console.log('\n4️⃣ Querying profiles table...');
    const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single();
    
    if (profileError) {
        console.error('❌ Profile query failed:', profileError);
    } else {
        console.log('✅ Profile found:');
        console.log(profile);
    }
    
    // Query assessments table
    console.log('\n5️⃣ Querying assessments table...');
    const { data: assessments, error: assessmentError } = await supabase
        .from('assessments')
        .select('*')
        .eq('athlete_id', user.id)
        .order('created_at', { ascending: false })
        .limit(5);
    
    if (assessmentError) {
        console.error('❌ Assessment query failed:', assessmentError);
    } else {
        console.log('✅ Found', assessments.length, 'assessment(s):');
        assessments.forEach((a, i) => {
            console.log(`   [${i}]`, {
                id: a.id,
                aifri_score: a.aifri_score,
                risk_level: a.risk_level,
                created_at: a.created_at
            });
        });
    }
    
    // Query workouts table
    console.log('\n6️⃣ Querying workouts table...');
    const { data: workouts, error: workoutError } = await supabase
        .from('workouts')
        .select('*')
        .eq('athlete_id', user.id)
        .order('scheduled_date', { ascending: false })
        .limit(5);
    
    if (workoutError) {
        console.error('❌ Workout query failed:', workoutError);
    } else {
        console.log('✅ Found', workouts.length, 'workout(s):');
        workouts.forEach((w, i) => {
            console.log(`   [${i}]`, {
                id: w.id,
                scheduled_date: w.scheduled_date,
                completed: w.completed
            });
        });
    }
    
    console.log('\n' + '='.repeat(50));
    console.log('✅ DEBUG COMPLETE');
}

// Usage: paste this entire script into browser console, then run:
// debugDashboard()

console.log('📌 Dashboard Debug Helper loaded');
console.log('   Usage: debugDashboard()');
