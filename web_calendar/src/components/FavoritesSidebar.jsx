import { useState, useEffect } from 'react'
import { supabase } from '../lib/supabase'

export default function FavoritesSidebar({ onClose, onApplyWorkout }) {
  const [favorites, setFavorites] = useState([])
  const [folders, setFolders] = useState(['All Workouts', 'Easy Runs', 'Quality Sessions', 'Long Runs'])
  const [activeFolder, setActiveFolder] = useState('All Workouts')
  const [searchTerm, setSearchTerm] = useState('')

  useEffect(() => {
    loadFavorites()
  }, [])

  async function loadFavorites() {
    const { data } = await supabase
      .from('workout_templates')
      .select('*')
      .order('name')
    
    setFavorites(data || [])
  }

  const filteredFavorites = favorites.filter(fav => {
    const matchesSearch = fav.name?.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesFolder = activeFolder === 'All Workouts' || fav.category === activeFolder
    return matchesSearch && matchesFolder
  })

  return (
    <div className="favorites-sidebar">
      <div className="sidebar-header">
        <h3>Favorite Workouts</h3>
        <button className="close-btn" onClick={onClose}>✕</button>
      </div>

      <div className="sidebar-search">
        <input
          type="text"
          placeholder="Search workouts..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="search-input"
        />
      </div>

      <div className="sidebar-folders">
        {folders.map(folder => (
          <button
            key={folder}
            className={`folder-btn ${activeFolder === folder ? 'active' : ''}`}
            onClick={() => setActiveFolder(folder)}
          >
            📁 {folder}
          </button>
        ))}
      </div>

      <div className="sidebar-favorites-list">
        {filteredFavorites.length === 0 ? (
          <div className="empty-state">
            <p>No favorite workouts yet</p>
            <small>Save workouts from the calendar to access them quickly</small>
          </div>
        ) : (
          filteredFavorites.map(fav => (
            <div key={fav.id} className="favorite-item">
              <div className="favorite-info">
                <h4>{fav.name}</h4>
                <p>{fav.description}</p>
                <div className="favorite-meta">
                  {fav.distance_km && <span>{fav.distance_km} km</span>}
                  {fav.duration_minutes && <span>{fav.duration_minutes} min</span>}
                </div>
              </div>
              <button 
                className="apply-btn"
                onClick={() => {
                  const date = prompt('Apply to date (YYYY-MM-DD):')
                  if (date) onApplyWorkout(fav, new Date(date))
                }}
              >
                Apply →
              </button>
            </div>
          ))
        )}
      </div>

      <div className="sidebar-footer">
        <button className="btn-secondary full-width">
          + New Template
        </button>
      </div>
    </div>
  )
}
