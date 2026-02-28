export default function BulkEditToolbar({ selectedCount, onDelete, onCancel }) {
  return (
    <div className="bulk-edit-toolbar">
      <div className="bulk-edit-info">
        <span className="selected-count">{selectedCount} workouts selected</span>
      </div>
      
      <div className="bulk-edit-actions">
        <button className="btn-secondary" onClick={onCancel}>
          Cancel
        </button>
        <button 
          className="btn-danger" 
          onClick={onDelete}
          disabled={selectedCount === 0}
        >
          🗑️ Delete Selected
        </button>
        <button 
          className="btn-primary"
          disabled={selectedCount === 0}
        >
          ⭐ Save as Template
        </button>
      </div>
    </div>
  )
}
