// Authentication guard for protected pages
function checkAuth() {
  const token = localStorage.getItem('token');

  if (!token) {
    window.location.href = '/index.html';
    return false;
  }

  try {
    const payload = JSON.parse(atob(token.split('.')[1]));
    if (payload.exp * 1000 < Date.now()) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/index.html';
      return false;
    }
  } catch (error) {
    console.error('Token validation error:', error);
    window.location.href = '/index.html';
    return false;
  }

  return true;
}

// Enforce auth on load for protected pages
if (!checkAuth()) {
  throw new Error('Unauthorized');
}
