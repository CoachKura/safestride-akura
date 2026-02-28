import { format, addMonths, subMonths } from 'date-fns'
import { supabase } from '../lib/supabase'

export default function CalendarHeader({ 
  currentMonth, 
  onMonthChange, 
  onExportPDF,
  onToggleFavorites,
  bulkEditMode,
  onToggleBulkEdit
}) {
  const handleSignOut = async () => {
    await supabase.auth.signOut()
    window.location.reload()
  }

  return (
    <header className="calendar-header">
      <div className="header-left">
        <h1>Athlete's Training Plan</h1>
        <p className="subtitle">12-week program for Low Risk (AISRI: 75/100)</p>
      </div>

      <div className="header-center">
        <button 
          className="month-nav-btn"
          onClick={() => onMonthChange(subMonths(currentMonth, 1))}
        >
          ←
        </button>
        <h2 className="current-month">
          {format(currentMonth, 'MMMM yyyy')}
        </h2>
        <button 
          className="month-nav-btn"
          onClick={() => onMonthChange(addMonths(currentMonth, 1))}
        >
          →
        </button>
      </div>

      <div className="header-right">
        <button 
          className={`btn-icon ${bulkEditMode ? 'active' : ''}`}
          onClick={onToggleBulkEdit}
          title="Bulk Edit Mode"
        >
          ☑️
        </button>
        <button 
          className="btn-icon"
          onClick={onToggleFavorites}
          title="Favorites"
        >
          ⭐
        </button>
        <button 
          className="btn-primary"
          onClick={onExportPDF}
        >
          📄 Export PDF
        </button>
        <button 
          className="btn-secondary"
          onClick={handleSignOut}
          title="Sign Out"
        >
          🚪 Sign Out
        </button>
      </div>
    </header>
  )
}
