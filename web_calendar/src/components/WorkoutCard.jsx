export default function WorkoutCard({ 
  workout, 
  bulkEditMode, 
  isSelected, 
  onSelect, 
  onEdit,
  isDragging 
}) {
  const workoutTypeConfig = {
    'easy_run': { color: '#4A90E2', label: 'Easy Run', icon: '🏃' },
    'quality_session': { color: '#9B59B6', label: 'Quality', icon: '⚡' },
    'long_run': { color: '#3498DB', label: 'Long Run', icon: '🏃‍♂️' },
    'tempo_run': { color: '#E74C3C', label: 'Tempo', icon: '⚡' },
    'intervals': { color: '#F39C12', label: 'Intervals', icon: '🔥' },
    'race': { color: '#E67E22', label: 'Race', icon: '🏆' },
    'cross_training': { color: '#16A085', label: 'Cross Training', icon: '🚴' },
    'rest_day': { color: '#27AE60', label: 'Rest', icon: '🛌' },
    'day_off': { color: '#95A5A6', label: 'Day Off', icon: '📵' }
  }

  const workoutType = workout.workout?.workout_type || 'easy_run'
  const config = workoutTypeConfig[workoutType] || workoutTypeConfig.easy_run

  const distance = workout.workout?.distance_km
  const duration = workout.workout?.duration_minutes

  return (
    <div 
      className={`
        workout-card 
        ${bulkEditMode ? 'bulk-mode' : ''}
        ${isSelected ? 'selected' : ''}
        ${isDragging ? 'dragging' : ''}
        ${workout.status === 'completed' ? 'completed' : ''}
      `}
      style={{ borderLeft: `4px solid ${config.color}` }}
      onClick={bulkEditMode ? onSelect : onEdit}
    >
      {bulkEditMode && (
        <input
          type="checkbox"
          checked={isSelected}
          onChange={onSelect}
          className="bulk-select-checkbox"
          onClick={(e) => e.stopPropagation()}
        />
      )}

      <div className="workout-card-header">
        <span className="workout-type-badge" style={{ backgroundColor: config.color }}>
          {config.icon} {config.label}
        </span>
        {workout.status === 'completed' && (
          <span className="completion-badge">✓</span>
        )}
      </div>

      <div className="workout-card-body">
        {distance && (
          <div className="workout-metric">
            <span className="metric-label">Distance:</span>
            <span className="metric-value">{distance} km</span>
          </div>
        )}
        {duration && (
          <div className="workout-metric">
            <span className="metric-label">Duration:</span>
            <span className="metric-value">{duration} min</span>
          </div>
        )}
        {workout.workout?.description && (
          <p className="workout-description">
            {workout.workout.description.slice(0, 60)}
            {workout.workout.description.length > 60 ? '...' : ''}
          </p>
        )}
      </div>

      {workout.workout?.pace_zone && (
        <div className="workout-pace-zone">
          Pace: {workout.workout.pace_zone}
        </div>
      )}
    </div>
  )
}
