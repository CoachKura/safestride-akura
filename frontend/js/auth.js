// SafeStride authentication guard with single-check flag to prevent redirect loops
const AUTH_CHECK_KEY = 'auth_checked';
const TOKEN_KEY = 'safestride_token';
const USER_KEY = 'safestride_user';

function checkAuth() {
  // Only check once per page load
  if (sessionStorage.getItem(AUTH_CHECK_KEY)) {
    return true;
  }

  const token = localStorage.getItem(TOKEN_KEY);

  if (!token) {
    // Only redirect if we're not already on the homepage
    if (!window.location.pathname.includes('index.html') && window.location.pathname !== '/') {
      sessionStorage.setItem(AUTH_CHECK_KEY, 'true');
      window.location.href = '/index.html';
      return false;
    }
  }

  try {
    const payload = JSON.parse(atob(token.split('.')[1]));
    if (payload.exp * 1000 < Date.now()) {
      localStorage.removeItem(TOKEN_KEY);
      localStorage.removeItem(USER_KEY);
      window.location.href = '/index.html';
      return false;
    }
  } catch (error) {
    console.error('Token validation error:', error);
    window.location.href = '/index.html';
    return false;
  }

  // Mark as checked for this page load
  sessionStorage.setItem(AUTH_CHECK_KEY, 'true');
  return true;
}

// Enforce auth on protected pages only
(function enforceAuthGuard() {
  const protectedPages = ['athlete-dashboard', 'coach-dashboard', 'athlete-devices'];
  const currentPath = window.location.pathname;

  if (protectedPages.some(page => currentPath.includes(page))) {
    checkAuth();
  }
})();
