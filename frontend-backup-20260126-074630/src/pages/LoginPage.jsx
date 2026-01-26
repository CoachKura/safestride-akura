import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { Activity, Mail, Lock, User } from 'lucide-react';

export default function LoginPage() {
  const [role, setRole] = useState('athlete'); // 'athlete' or 'coach'
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  
  const { loginCoach, loginAthlete } = useAuth();
  const navigate = useNavigate();

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      if (role === 'coach') {
        await loginCoach(email, password);
        navigate('/coach/dashboard');
      } else {
        await loginAthlete(email, password);
        navigate('/athlete/dashboard');
      }
    } catch (err) {
      setError(err.response?.data?.error || 'Login failed. Please check your credentials.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen flex">
      {/* Left side - Branding */}
      <div className="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-primary-600 to-primary-800 text-white p-12 flex-col justify-between">
        <div>
          <div className="flex items-center space-x-3 mb-8">
            <Activity className="h-10 w-10" />
            <div>
              <h1 className="text-3xl font-bold">SafeStride</h1>
              <p className="text-primary-200">by AKURA</p>
            </div>
          </div>
          
          <h2 className="text-4xl font-bold mb-6">
            Transform Your Running with Elite Coaching
          </h2>
          
          <div className="space-y-4">
            <Feature text="VDOT O2-inspired coach platform" />
            <Feature text="Auto-sync workouts to Garmin & Strava" />
            <Feature text="HR-based training with 5 zones" />
            <Feature text="7 protocol system for comprehensive training" />
            <Feature text="Chennai climate-optimized protocols" />
          </div>
        </div>
        
        <div className="text-primary-200 text-sm">
          <p>Coach Kura Balendar Sathyamoorthy</p>
          <p>coach@akura.in | @akura_safestride</p>
        </div>
      </div>

      {/* Right side - Login Form */}
      <div className="flex-1 flex items-center justify-center p-8 bg-gray-50">
        <div className="w-full max-w-md">
          {/* Mobile Logo */}
          <div className="lg:hidden flex items-center justify-center space-x-3 mb-8">
            <Activity className="h-8 w-8 text-primary-600" />
            <div>
              <h1 className="text-2xl font-bold text-gray-900">SafeStride</h1>
              <p className="text-sm text-gray-600">by AKURA</p>
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-lg p-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-6 text-center">
              Sign In to SafeStride
            </h2>

            {/* Role Selector */}
            <div className="flex rounded-lg bg-gray-100 p-1 mb-6">
              <button
                type="button"
                className={`flex-1 py-2 px-4 rounded-md font-medium transition-colors ${
                  role === 'athlete'
                    ? 'bg-white text-primary-600 shadow-sm'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
                onClick={() => setRole('athlete')}
              >
                <User className="inline h-4 w-4 mr-2" />
                Athlete
              </button>
              <button
                type="button"
                className={`flex-1 py-2 px-4 rounded-md font-medium transition-colors ${
                  role === 'coach'
                    ? 'bg-white text-primary-600 shadow-sm'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
                onClick={() => setRole('coach')}
              >
                <Activity className="inline h-4 w-4 mr-2" />
                Coach
              </button>
            </div>

            {error && (
              <div className="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg mb-4">
                {error}
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Email
                </label>
                <div className="relative">
                  <Mail className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                    placeholder={role === 'coach' ? 'coach@akura.in' : 'your.email@example.com'}
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Password
                </label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
                  <input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                    placeholder="Enter your password"
                    required
                  />
                </div>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-primary-600 text-white py-3 rounded-lg hover:bg-primary-700 font-semibold transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {loading ? (
                  <span className="flex items-center justify-center">
                    <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2"></div>
                    Signing in...
                  </span>
                ) : (
                  `Sign in as ${role === 'coach' ? 'Coach' : 'Athlete'}`
                )}
              </button>
            </form>

            <div className="mt-6 text-center">
              {role === 'athlete' ? (
                <p className="text-sm text-gray-600">
                  Don't have an account?{' '}
                  <Link to="/signup" className="text-primary-600 hover:text-primary-700 font-medium">
                    Sign up with invite
                  </Link>
                </p>
              ) : (
                <p className="text-sm text-gray-600">
                  For coach account access, contact{' '}
                  <a href="mailto:coach@akura.in" className="text-primary-600 hover:text-primary-700 font-medium">
                    coach@akura.in
                  </a>
                </p>
              )}
            </div>

            <div className="mt-6 pt-6 border-t border-gray-200 text-center">
              <Link to="/" className="text-sm text-gray-600 hover:text-gray-900">
                ← Back to home
              </Link>
            </div>
          </div>

          {/* Test Credentials (Development only) */}
          {import.meta.env.DEV && (
            <div className="mt-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg text-sm">
              <p className="font-semibold text-yellow-800 mb-2">🧪 Test Credentials:</p>
              <div className="text-yellow-700 space-y-1">
                <p><strong>Coach:</strong> coach@akura.in / [set password in DB]</p>
                <p><strong>Athlete:</strong> Use invite link from coach</p>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function Feature({ text }) {
  return (
    <div className="flex items-start space-x-2">
      <svg className="h-6 w-6 text-primary-300 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
      </svg>
      <span>{text}</span>
    </div>
  );
}
