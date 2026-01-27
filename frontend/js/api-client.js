/* =============================================================================
   AKURA API-CLIENT.JS - Backend API Integration Layer
   ============================================================================= */

class AkuraAPI {
  constructor(baseURL = 'https://safestride-backend-cave.onrender.com/api', authToken = null) {
    this.baseURL = baseURL;
    this.authToken = authToken;
    this.timeout = 30000; // 30 second timeout
  }

  /**
   * Set authentication token
   */
  setAuthToken(token) {
    this.authToken = token;
    if (token) {
      localStorage.setItem('akura_auth_token', token);
    }
  }

  /**
   * Get authentication token
   */
  getAuthToken() {
    return this.authToken || localStorage.getItem('akura_auth_token');
  }

  /**
   * Clear authentication
   */
  clearAuth() {
    this.authToken = null;
    localStorage.removeItem('akura_auth_token');
  }

  /**
   * Generic fetch wrapper with error handling
   */
  async request(endpoint, options = {}) {
    const url = `${this.baseURL}${endpoint}`;
    const token = this.getAuthToken();

    const headers = {
      'Content-Type': 'application/json',
      ...options.headers
    };

    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.timeout);

      const response = await fetch(url, {
        ...options,
        headers,
        signal: controller.signal
      });

      clearTimeout(timeoutId);

      // Handle non-JSON responses
      let data;
      const contentType = response.headers.get('content-type');
      if (contentType && contentType.includes('application/json')) {
        data = await response.json();
      } else {
        data = await response.text();
      }

      // Handle error responses
      if (!response.ok) {
        this.handleError(response.status, data);
      }

      return data;
    } catch (error) {
      if (error.name === 'AbortError') {
        throw new Error('Request timeout - please try again');
      }
      throw error;
    }
  }

  /**
   * Handle API errors
   */
  handleError(status, data) {
    let message = 'An error occurred';

    switch (status) {
      case 400:
        message = data.message || 'Invalid request - please check your data';
        break;
      case 401:
        this.clearAuth();
        message = 'Session expired - please log in again';
        window.location.href = '/login.html';
        break;
      case 403:
        message = 'You do not have permission to access this resource';
        break;
      case 404:
        message = 'Resource not found';
        break;
      case 500:
        message = 'Server error - please try again later';
        break;
      case 503:
        message = 'Service temporarily unavailable';
        break;
      default:
        message = `HTTP ${status}: ${data.message || 'Unknown error'}`;
    }

    const error = new Error(message);
    error.status = status;
    error.data = data;
    throw error;
  }

  /**
   * ===== AUTHENTICATION =====
   */

  async login(email, password) {
    const data = await this.request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password })
    });

    if (data.token) {
      this.setAuthToken(data.token);
    }

    return data;
  }

  async register(userData) {
    const data = await this.request('/auth/register', {
      method: 'POST',
      body: JSON.stringify(userData)
    });

    if (data.token) {
      this.setAuthToken(data.token);
    }

    return data;
  }

  async logout() {
    try {
      await this.request('/auth/logout', { method: 'POST' });
    } finally {
      this.clearAuth();
    }
    return { success: true };
  }

  /**
   * ===== ASSESSMENT =====
   */

  /**
   * Submit complete assessment (9 steps)
   */
  async submitAssessment(assessmentData) {
    const data = await this.request('/assessments', {
      method: 'POST',
      body: JSON.stringify(assessmentData)
    });

    // Cache result locally
    const storage = new StorageManager();
    if (data.aifriScore) {
      storage.saveAIFRIScore(data.assessmentId, data.aifriScore);
    }

    return data;
  }

  /**
   * Get assessment by ID
   */
  async getAssessment(assessmentId) {
    return this.request(`/assessments/${assessmentId}`);
  }

  /**
   * Get user's assessments
   */
  async getUserAssessments() {
    return this.request('/assessments');
  }

  /**
   * Update assessment (partial)
   */
  async updateAssessment(assessmentId, partialData) {
    return this.request(`/assessments/${assessmentId}`, {
      method: 'PATCH',
      body: JSON.stringify(partialData)
    });
  }

  /**
   * Delete assessment
   */
  async deleteAssessment(assessmentId) {
    return this.request(`/assessments/${assessmentId}`, {
      method: 'DELETE'
    });
  }

  /**
   * ===== TRAINING PROTOCOLS =====
   */

  /**
   * Get training protocol by ID
   */
  async getTrainingProtocol(protocolId) {
    return this.request(`/protocols/${protocolId}`);
  }

  /**
   * Get all protocols for user
   */
  async getUserProtocols() {
    return this.request('/protocols');
  }

  /**
   * Get protocol week by ID
   */
  async getProtocolWeek(protocolId, weekNumber) {
    return this.request(`/protocols/${protocolId}/weeks/${weekNumber}`);
  }

  /**
   * Get protocol week workouts
   */
  async getWeekWorkouts(protocolId, weekNumber) {
    return this.request(`/protocols/${protocolId}/weeks/${weekNumber}/workouts`);
  }

  /**
   * ===== WORKOUTS =====
   */

  /**
   * Get today's workout
   */
  async getTodayWorkout() {
    return this.request('/workouts/today');
  }

  /**
   * Get all user workouts
   */
  async getUserWorkouts(limit = 50, offset = 0) {
    const params = new URLSearchParams({ limit, offset });
    return this.request(`/workouts?${params}`);
  }

  /**
   * Get workout by ID
   */
  async getWorkout(workoutId) {
    return this.request(`/workouts/${workoutId}`);
  }

  /**
   * Submit workout feedback
   */
  async submitWorkoutFeedback(workoutId, feedbackData) {
    const data = await this.request(`/workouts/${workoutId}/feedback`, {
      method: 'POST',
      body: JSON.stringify(feedbackData)
    });

    // Cache locally
    const storage = new StorageManager();
    storage.saveWorkoutCompletion({
      workoutId,
      ...feedbackData
    });

    return data;
  }

  /**
   * Mark workout complete
   */
  async completeWorkout(workoutId) {
    return this.request(`/workouts/${workoutId}/complete`, {
      method: 'POST'
    });
  }

  /**
   * ===== COACH DASHBOARD =====
   */

  /**
   * Get all athletes for coach
   */
  async getCoachAthletes(coachId) {
    return this.request(`/coaches/${coachId}/athletes`);
  }

  /**
   * Get athlete details
   */
  async getAthleteDetails(athleteId) {
    return this.request(`/athletes/${athleteId}`);
  }

  /**
   * Get athlete's AIFRI score history
   */
  async getAthleteScoreHistory(athleteId) {
    return this.request(`/athletes/${athleteId}/scores`);
  }

  /**
   * Get athlete's workout history
   */
  async getAthleteWorkoutHistory(athleteId, limit = 30) {
    return this.request(`/athletes/${athleteId}/workouts?limit=${limit}`);
  }

  /**
   * Update athlete profile
   */
  async updateAthlete(athleteId, profileData) {
    return this.request(`/athletes/${athleteId}`, {
      method: 'PATCH',
      body: JSON.stringify(profileData)
    });
  }

  /**
   * Add note to athlete
   */
  async addAthleteNote(athleteId, noteText) {
    return this.request(`/athletes/${athleteId}/notes`, {
      method: 'POST',
      body: JSON.stringify({ content: noteText })
    });
  }

  /**
   * ===== USER PROFILE =====
   */

  /**
   * Get current user profile
   */
  async getCurrentUser() {
    return this.request('/users/me');
  }

  /**
   * Update user profile
   */
  async updateProfile(profileData) {
    return this.request('/users/me', {
      method: 'PATCH',
      body: JSON.stringify(profileData)
    });
  }

  /**
   * Change password
   */
  async changePassword(currentPassword, newPassword) {
    return this.request('/users/password', {
      method: 'POST',
      body: JSON.stringify({ currentPassword, newPassword })
    });
  }

  /**
   * ===== STATISTICS =====
   */

  /**
   * Get user statistics
   */
  async getUserStats() {
    return this.request('/stats/user');
  }

  /**
   * Get category statistics (norms)
   */
  async getCategoryStats(category) {
    return this.request(`/stats/category/${category}`);
  }

  /**
   * Get performance trends
   */
  async getPerformanceTrends(days = 30) {
    return this.request(`/stats/trends?days=${days}`);
  }

  /**
   * ===== HEALTH CHECK =====
   */

  /**
   * Check API health
   */
  async checkHealth() {
    try {
      const response = await fetch(`${this.baseURL}/health`, {
        method: 'GET'
      });
      return response.ok;
    } catch {
      return false;
    }
  }

  /**
   * Check if API is available (offline detection)
   */
  async isOnline() {
    return this.checkHealth();
  }
}

// Initialize global API client
const akuraAPI = new AkuraAPI();

// Export for use
if (typeof module !== 'undefined' && module.exports) {
  module.exports = AkuraAPI;
}
