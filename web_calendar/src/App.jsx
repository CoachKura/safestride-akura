import { useState, useEffect } from 'react'
import { supabase } from './lib/supabase'
import CalendarHeader from './components/CalendarHeader'
import WeekTabs from './components/WeekTabs'
import CalendarGrid from './components/CalendarGrid'
import BulkEditToolbar from './components/BulkEditToolbar'
import WorkoutModal from './components/WorkoutModal'
import FavoritesSidebar from './components/FavoritesSidebar'
import './styles/index.css'
import './styles/App.css'

function App() {
  const [currentMonth, setCurrentMonth] = useState(new Date())
  const [workouts, setWorkouts] = useState([])
  const [selectedWorkouts, setSelectedWorkouts] = useState([])
  const [bulkEditMode, setBulkEditMode] = useState(false)
  const [showWorkoutModal, setShowWorkoutModal] = useState(false)
  const [editingWorkout, setEditingWorkout] = useState(null)
  const [showFavorites, setShowFavorites] = useState(false)
  const [stravaActivities, setStravaActivities] = useState([])
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)
  const [signInEmail, setSignInEmail] = useState('')
  const [signInPassword, setSignInPassword] = useState('')
  const [authError, setAuthError] = useState('')
  const [signingIn, setSigningIn] = useState(false)

  useEffect(() => {
    // Initialize auth session
    checkSession()
    
    // Listen for auth state changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null)
      if (session?.user) {
        loadWorkouts()
        loadStravaActivities()
      }
    })

    return () => subscription.unsubscribe()
  }, [])

  useEffect(() => {
    // Reload data when month changes (only if authenticated)
    if (user) {
      loadWorkouts()
      loadStravaActivities()
    }
  }, [currentMonth, user])

  async function checkSession() {
    try {
      const { data: { session } } = await supabase.auth.getSession()
      setUser(session?.user ?? null)
      setLoading(false)
    } catch (error) {
      console.error('Error checking session:', error)
      setLoading(false)
    }
  }

  async function loadWorkouts() {
    if (!user) return

    try {
      const firstDay = new Date(currentMonth.getFullYear(), currentMonth.getMonth(), 1)
      const lastDay = new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1, 0)

      const { data, error } = await supabase
        .from('athlete_calendar')
        .select(`
          *,
          workout:ai_workouts(*)
        `)
        .gte('scheduled_date', firstDay.toISOString())
        .lte('scheduled_date', lastDay.toISOString())
        .order('scheduled_date', { ascending: true })

      if (error) {
        console.error('Error loading workouts:', error)
        return
      }
      
      setWorkouts(data || [])
    } catch (error) {
      console.error('Error loading workouts:', error)
    }
  }

  function generateDemoWorkouts(startDate, endDate) {
    const workouts = []
    const types = ['easy_run', 'quality_session', 'long_run', 'tempo_run', 'rest_day']
    
    for (let d = new Date(startDate); d <= endDate; d.setDate(d.getDate() + 1)) {
      if (d.getDay() !== 0 && Math.random() > 0.3) { // Skip some days
        const type = types[Math.floor(Math.random() * types.length)]
        workouts.push({
          id: `demo-${d.toISOString()}`,
          scheduled_date: d.toISOString(),
          status: Math.random() > 0.5 ? 'completed' : 'pending',
          workout: {
            workout_type: type,
            distance_km: type === 'rest_day' ? 0 : 5 + Math.random() * 10,
            duration_minutes: type === 'rest_day' ? 0 : 30 + Math.random() * 60,
            description: `Demo ${type.replace('_', ' ')} workout`,
            pace_zone: 'easy'
          }
        })
      }
    }
    
    return workouts
  }

  async function loadStravaActivities() {
    if (!user) return

    try {
      const firstDay = new Date(currentMonth.getFullYear(), currentMonth.getMonth(), 1)
      const lastDay = new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1, 0)

      const { data, error } = await supabase
        .from('gps_activities')
        .select('*')
        .eq('athlete_id', user.id)
        .gte('start_time', firstDay.toISOString())
        .lte('start_time', lastDay.toISOString())

      if (error) {
        console.error('Error loading Strava activities:', error)
        return
      }

      setStravaActivities(data || [])
    } catch (error) {
      console.error('Error loading Strava activities:', error)
    }
  }

  const handleAddWorkout = (date) => {
    setEditingWorkout({ scheduled_date: date })
    setShowWorkoutModal(true)
  }

  const handleEditWorkout = (workout) => {
    setEditingWorkout(workout)
    setShowWorkoutModal(true)
  }

  const handleCloneWeek = async (weekStart) => {
    const weekEnd = new Date(weekStart)
    weekEnd.setDate(weekEnd.getDate() + 6)

    const weekWorkouts = workouts.filter(w => {
      const wDate = new Date(w.scheduled_date)
      return wDate >= weekStart && wDate <= weekEnd
    })

    // Clone to next week
    const nextWeekStart = new Date(weekStart)
    nextWeekStart.setDate(nextWeekStart.getDate() + 7)

    for (const workout of weekWorkouts) {
      const originalDate = new Date(workout.scheduled_date)
      const newDate = new Date(nextWeekStart)
      newDate.setDate(newDate.getDate() + (originalDate.getDay() - weekStart.getDay()))

      await supabase.from('athlete_calendar').insert({
        athlete_id: user.id,
        scheduled_date: newDate.toISOString(),
        workout_id: workout.workout_id,
        status: 'pending'
      })
    }

    await loadWorkouts()
  }

  const handleBulkDelete = async () => {
    if (!selectedWorkouts.length) return

    await supabase
      .from('athlete_calendar')
      .delete()
      .in('id', selectedWorkouts)

    setSelectedWorkouts([])
    setBulkEditMode(false)
    await loadWorkouts()
  }

  if (loading) {
    return (
      <div className="loading-screen">
        <div className="spinner"></div>
        <p>Loading SafeStride Calendar...</p>
      </div>
    )
  }

  if (!user) {
    return (
      <div className="auth-screen">
        <div className="auth-card">
          <h1>🏃 SafeStride Training Calendar</h1>
          <p className="auth-subtitle">Sign in with your SafeStride account</p>
          
          <form onSubmit={async (e) => {
            e.preventDefault()
            setAuthError('')
            setSigningIn(true)
            
            try {
              const { data, error } = await supabase.auth.signInWithPassword({
                email: signInEmail,
                password: signInPassword,
              })
              
              if (error) {
                console.error('Sign in error:', error)
                if (error.message.includes('Invalid login credentials')) {
                  setAuthError('Invalid email or password. Please check your credentials.')
                } else if (error.message.includes('Email not confirmed')) {
                  setAuthError('Please confirm your email address first.')
                } else {
                  setAuthError(error.message)
                }
              } else {
                setUser(data.user)
              }
            } catch (err) {
              console.error('Sign in exception:', err)
              setAuthError('Failed to sign in. Please try again or use Demo Mode.')
            } finally {
              setSigningIn(false)
            }
          }}>
            <div className="form-group">
              <label>Email</label>
              <input
                type="email"
                value={signInEmail}
                onChange={(e) => setSignInEmail(e.target.value)}
                placeholder="your@email.com"
                required
                disabled={signingIn}
              />
            </div>
            
            <div className="form-group">
              <label>Password</label>
              <input
                type="password"
                value={signInPassword}
                onChange={(e) => setSignInPassword(e.target.value)}
                placeholder="••••••••"
                required
                disabled={signingIn}
              />
            </div>
            
            {authError && (
              <div className="auth-error">
                ⚠️ {authError}
              </div>
            )}
            
            <button type="submit" disabled={signingIn}>
              {signingIn ? 'Signing in...' : 'Sign In'}
            </button>
          </form>
          
          <p className="auth-footer">
            Use the same credentials as your SafeStride mobile app
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="app">
      <CalendarHeader
        currentMonth={currentMonth}
        onMonthChange={setCurrentMonth}
        onExportPDF={() => console.log('Export PDF')}
        onToggleFavorites={() => setShowFavorites(!showFavorites)}
        bulkEditMode={bulkEditMode}
        onToggleBulkEdit={() => {
          setBulkEditMode(!bulkEditMode)
          setSelectedWorkouts([])
        }}
      />

      <div className="calendar-container">
        <div className="calendar-main">
          {bulkEditMode && (
            <BulkEditToolbar
              selectedCount={selectedWorkouts.length}
              onDelete={handleBulkDelete}
              onCancel={() => {
                setBulkEditMode(false)
                setSelectedWorkouts([])
              }}
            />
          )}

          <CalendarGrid
            workouts={workouts}
            stravaActivities={stravaActivities}
            bulkEditMode={bulkEditMode}
            selectedWorkouts={selectedWorkouts}
            onSelectWorkout={(id) => {
              setSelectedWorkouts(prev =>
                prev.includes(id) ? prev.filter(w => w !== id) : [...prev, id]
              )
            }}
            onAddWorkout={handleAddWorkout}
            onEditWorkout={handleEditWorkout}
            onCloneWeek={handleCloneWeek}
            onWorkoutDrop={async (workoutId, newDate) => {
              await supabase
                .from('athlete_calendar')
                .update({ scheduled_date: newDate.toISOString() })
                .eq('id', workoutId)
              await loadWorkouts()
            }}
          />
        </div>

        {showFavorites && (
          <FavoritesSidebar
            onClose={() => setShowFavorites(false)}
            onApplyWorkout={async (workoutTemplate, date) => {
              await supabase.from('athlete_calendar').insert({
                athlete_id: user.id,
                scheduled_date: date.toISOString(),
                workout_id: workoutTemplate.id,
                status: 'pending'
              })
              await loadWorkouts()
            }}
          />
        )}
      </div>

      {showWorkoutModal && (
        <WorkoutModal
          workout={editingWorkout}
          onClose={() => {
            setShowWorkoutModal(false)
            setEditingWorkout(null)
          }}
          onSave={async (workoutData) => {
            if (demoMode) {
              // In demo mode, add/update in local state
              if (editingWorkout?.id) {
                setWorkouts(workouts.map(w => 
                  w.id === editingWorkout.id 
                    ? { ...w, ...workoutData, workout: workoutData }
                    : w
                ))
              } else {
                const newWorkout = {
                  id: `demo-${Date.now()}`,
                  scheduled_date: workoutData.scheduled_date,
                  status: 'pending',
                  workout: workoutData
                }
                setWorkouts([...workouts, newWorkout])
              }
            
    </div>
  )
}

export default App
