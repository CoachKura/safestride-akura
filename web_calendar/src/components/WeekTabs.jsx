export default function WeekTabs({ currentWeek, onWeekChange }) {
  const weeks = Array.from({ length: 12 }, (_, i) => i + 1)
  
  return (
    <div className="week-tabs">
      {weeks.map(week => (
        <button
          key={week}
          className={`week-tab ${currentWeek === week ? 'active' : ''}`}
          onClick={() => onWeekChange(week)}
        >
          Week {week}
        </button>
      ))}
    </div>
  )
}
