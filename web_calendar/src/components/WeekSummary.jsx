export default function WeekSummary({ 
  workouts, 
  stravaActivities, 
  weekStart, 
  onCloneWeek,
  bulkEditMode 
}) {
  // Calculate planned distance
  const plannedDistance = workouts.reduce((sum, w) => {
    return sum + (w.workout?.distance_km || 0)
  }, 0)

  // Calculate completed distance from Strava activities
  const completedDistance = stravaActivities.reduce((sum, a) => {
    return sum + (a.distance / 1000) // Convert meters to km
  }, 0)

  const completionPercentage = plannedDistance > 0 
    ? Math.round((completedDistance / plannedDistance) * 100)
    : 0

  return (
    <div className="week-summary">
      <div className="week-summary-mileage">
        <div className="mileage-progress-circle">
          <svg viewBox="0 0 36 36" className="circular-chart">
            <path
              className="circle-bg"
              d="M18 2.0845
                a 15.9155 15.9155 0 0 1 0 31.831
                a 15.9155 15.9155 0 0 1 0 -31.831"
            />
            <path
              className="circle"
              strokeDasharray={`${completionPercentage}, 100`}
              d="M18 2.0845
                a 15.9155 15.9155 0 0 1 0 31.831
                a 15.9155 15.9155 0 0 1 0 -31.831"
            />
          </svg>
          <div className="percentage-text">{completionPercentage}%</div>
        </div>

        <div className="mileage-details">
          <div className="mileage-row">
            <span className="mileage-label">Completed:</span>
            <span className="mileage-value">{completedDistance.toFixed(1)} km</span>
          </div>
          <div className="mileage-row">
            <span className="mileage-label">Planned:</span>
            <span className="mileage-value">{plannedDistance.toFixed(1)} km</span>
          </div>
        </div>
      </div>

      <div className="week-stats">
        <div className="stat">
          <span className="stat-value">{workouts.length}</span>
          <span className="stat-label">Workouts</span>
        </div>
        <div className="stat">
          <span className="stat-value">
            {workouts.filter(w => w.status === 'completed').length}
          </span>
          <span className="stat-label">Completed</span>
        </div>
      </div>

      {!bulkEditMode && (
        <button 
          className="clone-week-btn"
          onClick={onCloneWeek}
          title="Clone this week to next week"
        >
          📋 Clone Week
        </button>
      )}

      {bulkEditMode && (
        <div className="bulk-week-checkbox">
          <input type="checkbox" id={`week-${weekStart}`} />
          <label htmlFor={`week-${weekStart}`}>Select Week</label>
        </div>
      )}
    </div>
  )
}
