import { useState } from 'react'
import { format } from 'date-fns'

export default function WorkoutModal({ workout, onClose, onSave }) {
  const [formData, setFormData] = useState({
    workout_type: workout?.workout?.workout_type || 'easy_run',
    scheduled_date: workout?.scheduled_date || new Date().toISOString().split('T')[0],
    distance_km: workout?.workout?.distance_km || '',
    duration_minutes: workout?.workout?.duration_minutes || '',
    description: workout?.workout?.description || '',
    pace_zone: workout?.workout?.pace_zone || '',
    intervals: workout?.workout?.intervals || '',
    sets: workout?.workout?.sets || '',
    reps: workout?.workout?.reps || '',
    rest_seconds: workout?.workout?.rest_seconds || ''
  })

  const handleSubmit = (e) => {
    e.preventDefault()
    onSave(formData)
  }

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>{workout?.id ? 'Edit Workout' : 'Add Workout'}</h2>
          <button className="modal-close" onClick={onClose}>✕</button>
        </div>

        <form onSubmit={handleSubmit} className="workout-form">
          <div className="form-group">
            <label>Workout Type</label>
            <select
              value={formData.workout_type}
              onChange={(e) => setFormData({ ...formData, workout_type: e.target.value })}
              required
            >
              <option value="easy_run">🏃 Easy Run</option>
              <option value="quality_session">⚡ Quality Session</option>
              <option value="long_run">🏃‍♂️ Long Run</option>
              <option value="tempo_run">⚡ Tempo Run</option>
              <option value="intervals">🔥 Intervals</option>
              <option value="race">🏆 Race</option>
              <option value="cross_training">🚴 Cross Training</option>
              <option value="rest_day">🛌 Rest Day</option>
              <option value="day_off">📵 Day Off</option>
            </select>
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Date</label>
              <input
                type="date"
                value={formData.scheduled_date}
                onChange={(e) => setFormData({ ...formData, scheduled_date: e.target.value })}
                required
              />
            </div>
            <div className="form-group">
              <label>Distance (km)</label>
              <input
                type="number"
                step="0.1"
                value={formData.distance_km}
                onChange={(e) => setFormData({ ...formData, distance_km: e.target.value })}
                placeholder="e.g., 10.0"
              />
            </div>
            <div className="form-group">
              <label>Duration (min)</label>
              <input
                type="number"
                value={formData.duration_minutes}
                onChange={(e) => setFormData({ ...formData, duration_minutes: e.target.value })}
                placeholder="e.g., 60"
              />
            </div>
          </div>

          {formData.workout_type === 'intervals' && (
            <div className="form-row">
              <div className="form-group">
                <label>Sets</label>
                <input
                  type="number"
                  value={formData.sets}
                  onChange={(e) => setFormData({ ...formData, sets: e.target.value })}
                  placeholder="e.g., 3"
                />
              </div>
              <div className="form-group">
                <label>Reps per Set</label>
                <input
                  type="number"
                  value={formData.reps}
                  onChange={(e) => setFormData({ ...formData, reps: e.target.value })}
                  placeholder="e.g., 8"
                />
              </div>
              <div className="form-group">
                <label>Rest (seconds)</label>
                <input
                  type="number"
                  value={formData.rest_seconds}
                  onChange={(e) => setFormData({ ...formData, rest_seconds: e.target.value })}
                  placeholder="e.g., 90"
                />
              </div>
            </div>
          )}

          <div className="form-group">
            <label>Pace Zone</label>
            <select
              value={formData.pace_zone}
              onChange={(e) => setFormData({ ...formData, pace_zone: e.target.value })}
            >
              <option value="">Select pace zone</option>
              <option value="easy">Easy (Conversational)</option>
              <option value="moderate">Moderate (Comfortably hard)</option>
              <option value="tempo">Tempo (10K race pace)</option>
              <option value="threshold">Threshold (Hard but sustainable)</option>
              <option value="interval">Interval (5K race pace)</option>
              <option value="repetition">Repetition (Max effort)</option>
            </select>
          </div>

          <div className="form-group">
            <label>Description</label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              placeholder="Add workout notes, instructions, or goals..."
              rows="4"
            ></textarea>
          </div>

          <div className="modal-footer">
            <button type="button" className="btn-secondary" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn-primary">
              {workout?.id ? 'Update Workout' : 'Add Workout'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
