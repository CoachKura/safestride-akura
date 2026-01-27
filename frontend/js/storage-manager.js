/* =============================================================================
   AKURA STORAGE-MANAGER.JS - LocalStorage Management & Data Persistence
   ============================================================================= */

class StorageManager {
  constructor(storageKeyPrefix = 'akura') {
    this.prefix = storageKeyPrefix;
    this.checkStorageAvailable();
  }

  /**
   * Check if localStorage is available
   */
  checkStorageAvailable() {
    try {
      const test = '__storage_test__';
      localStorage.setItem(test, test);
      localStorage.removeItem(test);
      this.storageAvailable = true;
    } catch (e) {
      console.warn('localStorage not available, using fallback');
      this.storageAvailable = false;
    }
  }

  /**
   * Get prefixed key
   */
  getKey(key) {
    return `${this.prefix}_${key}`;
  }

  /**
   * ===== ASSESSMENT DRAFT MANAGEMENT =====
   */

  /**
   * Save assessment draft to localStorage
   */
  saveAssessmentDraft(stepNumber, formData) {
    if (!this.storageAvailable) return false;

    try {
      const draftData = {
        step: stepNumber,
        formData: formData,
        lastSaved: new Date().toISOString(),
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString() // 30 days
      };

      localStorage.setItem(
        this.getKey('assessment_draft'),
        JSON.stringify(draftData)
      );
      return true;
    } catch (e) {
      console.error('Error saving assessment draft:', e);
      return false;
    }
  }

  /**
   * Load assessment draft from localStorage
   */
  loadAssessmentDraft() {
    if (!this.storageAvailable) return null;

    try {
      const draftJSON = localStorage.getItem(this.getKey('assessment_draft'));
      if (!draftJSON) return null;

      const draft = JSON.parse(draftJSON);

      // Check if draft has expired
      if (new Date(draft.expiresAt) < new Date()) {
        this.clearAssessmentDraft();
        return null;
      }

      return draft;
    } catch (e) {
      console.error('Error loading assessment draft:', e);
      return null;
    }
  }

  /**
   * Clear assessment draft
   */
  clearAssessmentDraft() {
    if (!this.storageAvailable) return false;

    try {
      localStorage.removeItem(this.getKey('assessment_draft'));
      return true;
    } catch (e) {
      console.error('Error clearing assessment draft:', e);
      return false;
    }
  }

  /**
   * ===== AIFRI SCORE CACHING =====
   */

  /**
   * Save calculated AIFRI score
   */
  saveAIFRIScore(userId, scoreData) {
    if (!this.storageAvailable) return false;

    try {
      const scores = this.getAIFRIScores() || {};
      scores[userId] = {
        ...scoreData,
        calculatedAt: new Date().toISOString()
      };

      localStorage.setItem(
        this.getKey('aifri_scores'),
        JSON.stringify(scores)
      );
      return true;
    } catch (e) {
      console.error('Error saving AIFRI score:', e);
      return false;
    }
  }

  /**
   * Get AIFRI score by user ID
   */
  getAIFRIScore(userId) {
    if (!this.storageAvailable) return null;

    try {
      const scores = JSON.parse(localStorage.getItem(this.getKey('aifri_scores')) || '{}');
      return scores[userId] || null;
    } catch (e) {
      console.error('Error retrieving AIFRI score:', e);
      return null;
    }
  }

  /**
   * Get all AIFRI scores
   */
  getAIFRIScores() {
    if (!this.storageAvailable) return {};

    try {
      return JSON.parse(localStorage.getItem(this.getKey('aifri_scores')) || '{}');
    } catch (e) {
      console.error('Error retrieving AIFRI scores:', e);
      return {};
    }
  }

  /**
   * ===== WORKOUT TRACKING =====
   */

  /**
   * Save workout completion
   */
  saveWorkoutCompletion(workoutData) {
    if (!this.storageAvailable) return false;

    try {
      const history = this.getWorkoutHistory() || [];
      history.push({
        ...workoutData,
        completedAt: new Date().toISOString()
      });

      // Keep only last 90 days
      const ninetyDaysAgo = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
      const filteredHistory = history.filter(item =>
        new Date(item.completedAt) > ninetyDaysAgo
      );

      localStorage.setItem(
        this.getKey('workout_log'),
        JSON.stringify(filteredHistory)
      );
      return true;
    } catch (e) {
      console.error('Error saving workout completion:', e);
      return false;
    }
  }

  /**
   * Get workout history
   */
  getWorkoutHistory(daysBack = 90) {
    if (!this.storageAvailable) return [];

    try {
      const history = JSON.parse(localStorage.getItem(this.getKey('workout_log')) || '[]');

      if (daysBack > 0) {
        const cutoffDate = new Date(Date.now() - daysBack * 24 * 60 * 60 * 1000);
        return history.filter(item => new Date(item.completedAt) > cutoffDate);
      }

      return history;
    } catch (e) {
      console.error('Error retrieving workout history:', e);
      return [];
    }
  }

  /**
   * Get workout completion rate
   */
  getCompletionRate(daysBack = 7) {
    const history = this.getWorkoutHistory(daysBack);
    if (history.length === 0) return 0;

    const completed = history.filter(item => item.completed === true).length;
    return Math.round((completed / history.length) * 100);
  }

  /**
   * ===== USER PREFERENCES =====
   */

  /**
   * Save user preference
   */
  setPreference(key, value) {
    if (!this.storageAvailable) return false;

    try {
      const prefs = JSON.parse(localStorage.getItem(this.getKey('preferences')) || '{}');
      prefs[key] = value;
      localStorage.setItem(this.getKey('preferences'), JSON.stringify(prefs));
      return true;
    } catch (e) {
      console.error('Error saving preference:', e);
      return false;
    }
  }

  /**
   * Get user preference
   */
  getPreference(key, defaultValue = null) {
    if (!this.storageAvailable) return defaultValue;

    try {
      const prefs = JSON.parse(localStorage.getItem(this.getKey('preferences')) || '{}');
      return prefs[key] ?? defaultValue;
    } catch (e) {
      console.error('Error retrieving preference:', e);
      return defaultValue;
    }
  }

  /**
   * ===== STORAGE MANAGEMENT =====
   */

  /**
   * Check storage quota usage
   */
  checkStorageQuota() {
    if (!this.storageAvailable) {
      return { used: 0, available: 0, percentage: 0, warning: true };
    }

    try {
      let totalSize = 0;

      for (let key in localStorage) {
        if (key.startsWith(this.prefix)) {
          totalSize += localStorage[key].length + key.length;
        }
      }

      // localStorage typically has 5MB limit (5,242,880 bytes)
      const totalQuota = 5 * 1024 * 1024;
      const availableSize = totalQuota - totalSize;
      const percentage = Math.round((totalSize / totalQuota) * 100);

      return {
        used: totalSize,
        available: availableSize,
        percentage: percentage,
        warning: percentage > 80
      };
    } catch (e) {
      console.error('Error checking storage quota:', e);
      return { used: 0, available: 0, percentage: 0, warning: false };
    }
  }

  /**
   * Clear old data (older than specified days)
   */
  clearOldData(daysToKeep = 90) {
    if (!this.storageAvailable) return false;

    try {
      const cutoffDate = new Date(Date.now() - daysToKeep * 24 * 60 * 60 * 1000);

      // Clear old workout logs
      const history = this.getWorkoutHistory(daysToKeep);
      localStorage.setItem(
        this.getKey('workout_log'),
        JSON.stringify(history)
      );

      // Clear old assessment drafts
      const draft = this.loadAssessmentDraft();
      if (draft && new Date(draft.lastSaved) < cutoffDate) {
        this.clearAssessmentDraft();
      }

      return true;
    } catch (e) {
      console.error('Error clearing old data:', e);
      return false;
    }
  }

  /**
   * Export all stored data as JSON
   */
  exportAllData() {
    if (!this.storageAvailable) return null;

    try {
      const data = {
        exportedAt: new Date().toISOString(),
        assessmentDraft: this.loadAssessmentDraft(),
        aifriScores: this.getAIFRIScores(),
        workoutHistory: this.getWorkoutHistory(),
        preferences: JSON.parse(localStorage.getItem(this.getKey('preferences')) || '{}')
      };

      return JSON.stringify(data, null, 2);
    } catch (e) {
      console.error('Error exporting data:', e);
      return null;
    }
  }

  /**
   * Import data from JSON backup
   */
  importData(jsonString) {
    if (!this.storageAvailable) return false;

    try {
      const data = JSON.parse(jsonString);

      if (data.assessmentDraft) {
        localStorage.setItem(
          this.getKey('assessment_draft'),
          JSON.stringify(data.assessmentDraft)
        );
      }

      if (data.aifriScores) {
        localStorage.setItem(
          this.getKey('aifri_scores'),
          JSON.stringify(data.aifriScores)
        );
      }

      if (data.workoutHistory) {
        localStorage.setItem(
          this.getKey('workout_log'),
          JSON.stringify(data.workoutHistory)
        );
      }

      if (data.preferences) {
        localStorage.setItem(
          this.getKey('preferences'),
          JSON.stringify(data.preferences)
        );
      }

      return true;
    } catch (e) {
      console.error('Error importing data:', e);
      return false;
    }
  }

  /**
   * Clear all stored data
   */
  clearAll() {
    if (!this.storageAvailable) return false;

    try {
      for (let key in localStorage) {
        if (key.startsWith(this.prefix)) {
          localStorage.removeItem(key);
        }
      }
      return true;
    } catch (e) {
      console.error('Error clearing all data:', e);
      return false;
    }
  }

  /**
   * ===== AUTO-SAVE HELPER =====
   */

  /**
   * Debounce function for auto-save
   */
  static debounce(func, delay = 500) {
    let timeout;
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout);
        func(...args);
      };
      clearTimeout(timeout);
      timeout = setTimeout(later, delay);
    };
  }

  /**
   * Show save indicator
   */
  static showSaveIndicator(message = 'Saved', duration = 2000) {
    let indicator = document.getElementById('save-indicator');

    if (!indicator) {
      indicator = document.createElement('div');
      indicator.id = 'save-indicator';
      indicator.className = 'save-indicator';
      document.body.appendChild(indicator);
    }

    indicator.textContent = message;
    indicator.classList.add('show');

    setTimeout(() => {
      indicator.classList.remove('show');
    }, duration);
  }
}

// Export for use
if (typeof module !== 'undefined' && module.exports) {
  module.exports = StorageManager;
}
