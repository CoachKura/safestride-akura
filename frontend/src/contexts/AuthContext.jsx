import { createContext, useContext, useState, useEffect } from 'react';
import api from '../lib/api';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [role, setRole] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check if user is logged in
    const token = localStorage.getItem('token');
    const savedRole = localStorage.getItem('userRole');
    
    if (token && savedRole) {
      setRole(savedRole);
      // Fetch user profile based on role
      fetchUserProfile(savedRole);
    } else {
      setLoading(false);
    }
  }, []);

  async function fetchUserProfile(userRole) {
    try {
      const endpoint = userRole === 'coach' ? '/coach/dashboard/stats' : '/athlete/profile';
      const { data } = await api.get(endpoint);
      setUser(data);
      setLoading(false);
    } catch (error) {
      console.error('Failed to fetch user profile:', error);
      logout();
    }
  }

  async function loginCoach(email, password) {
    const { data } = await api.post('/auth/coach/login', { email, password });
    localStorage.setItem('token', data.token);
    localStorage.setItem('userRole', 'coach');
    setUser(data.coach);
    setRole('coach');
    return data;
  }

  async function loginAthlete(email, password) {
    const { data } = await api.post('/auth/athlete/login', { email, password });
    localStorage.setItem('token', data.token);
    localStorage.setItem('userRole', 'athlete');
    setUser(data.athlete);
    setRole('athlete');
    return data;
  }

  async function signupAthlete(signupData) {
    const { data } = await api.post('/auth/athlete/signup', signupData);
    localStorage.setItem('token', data.token);
    localStorage.setItem('userRole', 'athlete');
    setUser(data.athlete);
    setRole('athlete');
    return data;
  }

  function logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('userRole');
    setUser(null);
    setRole(null);
    window.location.href = '/';
  }

  const value = {
    user,
    role,
    loading,
    loginCoach,
    loginAthlete,
    signupAthlete,
    logout,
    isAuthenticated: !!user,
    isCoach: role === 'coach',
    isAthlete: role === 'athlete'
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}
