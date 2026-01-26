import { Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';

// Pages
import HomePage from './pages/HomePage';
import LoginPage from './pages/LoginPage';
import SignupPage from './pages/SignupPage';
import CoachDashboard from './pages/coach/Dashboard';
import CoachAthletes from './pages/coach/Athletes';
import CoachCalendar from './pages/coach/Calendar';
import CoachInvite from './pages/coach/Invite';
import AthleteDashboard from './pages/athlete/Dashboard';
import AthleteWorkouts from './pages/athlete/Workouts';
import AthleteDevices from './pages/athlete/Devices';
import AthleteProfile from './pages/athlete/Profile';

// Protected Route Component
function ProtectedRoute({ children, requireRole }) {
  const { loading, isAuthenticated, role } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (requireRole && role !== requireRole) {
    return <Navigate to="/" replace />;
  }

  return children;
}

function App() {
  return (
    <AuthProvider>
      <Routes>
        {/* Public Routes */}
        <Route path="/" element={<HomePage />} />
        <Route path="/login" element={<LoginPage />} />
        <Route path="/signup" element={<SignupPage />} />

        {/* Coach Routes */}
        <Route
          path="/coach/dashboard"
          element={
            <ProtectedRoute requireRole="coach">
              <CoachDashboard />
            </ProtectedRoute>
          }
        />
        <Route
          path="/coach/athletes"
          element={
            <ProtectedRoute requireRole="coach">
              <CoachAthletes />
            </ProtectedRoute>
          }
        />
        <Route
          path="/coach/calendar"
          element={
            <ProtectedRoute requireRole="coach">
              <CoachCalendar />
            </ProtectedRoute>
          }
        />
        <Route
          path="/coach/invite"
          element={
            <ProtectedRoute requireRole="coach">
              <CoachInvite />
            </ProtectedRoute>
          }
        />

        {/* Athlete Routes */}
        <Route
          path="/athlete/dashboard"
          element={
            <ProtectedRoute requireRole="athlete">
              <AthleteDashboard />
            </ProtectedRoute>
          }
        />
        <Route
          path="/athlete/workouts"
          element={
            <ProtectedRoute requireRole="athlete">
              <AthleteWorkouts />
            </ProtectedRoute>
          }
        />
        <Route
          path="/athlete/devices"
          element={
            <ProtectedRoute requireRole="athlete">
              <AthleteDevices />
            </ProtectedRoute>
          }
        />
        <Route
          path="/athlete/profile"
          element={
            <ProtectedRoute requireRole="athlete">
              <AthleteProfile />
            </ProtectedRoute>
          }
        />

        {/* Strava OAuth Callback */}
        <Route path="/auth/strava/callback" element={<StravaCallback />} />

        {/* 404 */}
        <Route path="*" element={<NotFound />} />
      </Routes>
    </AuthProvider>
  );
}

// Strava OAuth callback handler
function StravaCallback() {
  // This will be handled by AthleteDevices page
  return <Navigate to="/athlete/devices" replace />;
}

// 404 Page
function NotFound() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="text-center">
        <h1 className="text-6xl font-bold text-gray-900 mb-4">404</h1>
        <p className="text-xl text-gray-600 mb-8">Page not found</p>
        <a
          href="/"
          className="inline-block px-6 py-3 bg-primary-600 text-white rounded-lg hover:bg-primary-700"
        >
          Go Home
        </a>
      </div>
    </div>
  );
}

export default App;
