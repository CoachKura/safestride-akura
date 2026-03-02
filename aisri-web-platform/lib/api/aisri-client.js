/**
 * AISRi AI Engine Client
 * Wrapper for FastAPI endpoints at api.akura.in
 */

const AISRI_API_BASE_URL = 'https://api.akura.in'

class AISRiClient {
  constructor() {
    this.baseUrl = AISRI_API_BASE_URL
  }

  /**
   * Predict injury risk for an athlete
   * @param {string} athleteId - Athlete UUID
   * @returns {Promise<Object>} Injury risk prediction
   */
  async predictInjuryRisk(athleteId) {
    return this._post('/predict-injury-risk', { athlete_id: athleteId })
  }

  /**
   * Predict performance metrics
   * @param {string} athleteId - Athlete UUID
   * @returns {Promise<Object>} Performance prediction
   */
  async predictPerformance(athleteId) {
    return this._post('/predict-performance', { athlete_id: athleteId })
  }

  /**
   * Generate personalized training plan
   * @param {string} athleteId - Athlete UUID
   * @returns {Promise<Object>} Training plan
   */
  async generateTrainingPlan(athleteId) {
    return this._post('/generate-training-plan', { athlete_id: athleteId })
  }

  /**
   * Get autonomous AI decision/advice
   * @param {string} athleteId - Athlete UUID
   * @param {string} context - Optional context message
   * @returns {Promise<Object>} AI decision/advice
   */
  async getAutonomousDecision(athleteId, context = '') {
    return this._post('/agent/autonomous-decision', {
      athlete_id: athleteId,
      context: context
    })
  }

  /**
   * Internal POST method
   * @private
   */
  async _post(endpoint, body) {
    const response = await fetch(`${this.baseUrl}${endpoint}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    })

    if (!response.ok) {
      throw new Error(`AISRi API error: ${response.status} ${response.statusText}`)
    }

    return response.json()
  }
}

// Export singleton instance
export const aisriClient = new AISRiClient()
