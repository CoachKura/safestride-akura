import { useState } from 'react'
import { 
  startOfMonth, 
  endOfMonth, 
  eachWeekOfInterval, 
  startOfWeek, 
  endOfWeek,
  eachDayOfInterval,
  format,
  isSameMonth,
  isSameDay,
  isToday
} from 'date-fns'
import { DragDropContext, Droppable, Draggable } from 'react-beautiful-dnd'
import WorkoutCard from './WorkoutCard'
import WeekSummary from './WeekSummary'

export default function CalendarGrid({ 
  currentMonth, 
  workouts, 
  stravaActivities,
  bulkEditMode,
  selectedWorkouts,
  onSelectWorkout,
  onAddWorkout,
  onEditWorkout,
  onCloneWeek,
  onWorkoutDrop 
}) {
  const monthStart = startOfMonth(currentMonth)
  const monthEnd = endOfMonth(currentMonth)
  
  const weeks = eachWeekOfInterval(
    { start: monthStart, end: monthEnd },
    { weekStartsOn: 1 } // Monday
  )

  const getDayWorkouts = (date) => {
    return workouts.filter(w => 
      isSameDay(new Date(w.scheduled_date), date)
    )
  }

  const getDayStravaActivities = (date) => {
    return stravaActivities.filter(a => 
      isSameDay(new Date(a.start_time), date)
    )
  }

  const handleDragEnd = (result) => {
    if (!result.destination) return

    const workoutId = result.draggableId
    const newDate = new Date(result.destination.droppableId)
    
    onWorkoutDrop(workoutId, newDate)
  }

  return (
    <DragDropContext onDragEnd={handleDragEnd}>
      <div className="calendar-grid">
        {/* Day Headers */}
        <div className="calendar-header-row">
          <div className="week-number-header">#</div>
          {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map(day => (
            <div key={day} className="day-header">{day}</div>
          ))}
          <div className="week-summary-header">Week Summary</div>
        </div>

        {/* Week Rows */}
        {weeks.map((weekStart, weekIndex) => {
          const weekEnd = endOfWeek(weekStart, { weekStartsOn: 1 })
          const days = eachDayOfInterval({ start: weekStart, end: weekEnd })
          
          const weekWorkouts = workouts.filter(w => {
            const wDate = new Date(w.scheduled_date)
            return wDate >= weekStart && wDate <= weekEnd
          })

          const weekStravaActivities = stravaActivities.filter(a => {
            const aDate = new Date(a.start_time)
            return aDate >= weekStart && aDate <= weekEnd
          })

          return (
            <div key={weekIndex} className="calendar-week-row">
              {/* Week Number */}
              <div className="week-number">
                Week {weekIndex + 1}
              </div>

              {/* Days */}
              {days.map(day => {
                const dayWorkouts = getDayWorkouts(day)
                const dayActivities = getDayStravaActivities(day)
                const isCurrentMonth = isSameMonth(day, currentMonth)
                const isDayToday = isToday(day)

                return (
                  <Droppable 
                    key={day.toISOString()} 
                    droppableId={day.toISOString()}
                  >
                    {(provided, snapshot) => (
                      <div
                        ref={provided.innerRef}
                        {...provided.droppableProps}
                        className={`
                          calendar-day 
                          ${!isCurrentMonth ? 'other-month' : ''}
                          ${isDayToday ? 'today' : ''}
                          ${snapshot.isDraggingOver ? 'drag-over' : ''}
                        `}
                      >
                        <div className="day-date">
                          {format(day, 'd')}
                        </div>

                        <div className="day-workouts">
                          {dayWorkouts.map((workout, index) => (
                            <Draggable
                              key={workout.id}
                              draggableId={workout.id}
                              index={index}
                              isDragDisabled={bulkEditMode}
                            >
                              {(provided, snapshot) => (
                                <div
                                  ref={provided.innerRef}
                                  {...provided.draggableProps}
                                  {...provided.dragHandleProps}
                                  style={provided.draggableProps.style}
                                >
                                  <WorkoutCard
                                    workout={workout}
                                    bulkEditMode={bulkEditMode}
                                    isSelected={selectedWorkouts.includes(workout.id)}
                                    onSelect={() => onSelectWorkout(workout.id)}
                                    onEdit={() => onEditWorkout(workout)}
                                    isDragging={snapshot.isDragging}
                                  />
                                </div>
                              )}
                            </Draggable>
                          ))}

                          {dayActivities.map(activity => (
                            <div key={activity.id} className="strava-activity-badge">
                              🏃 {activity.name}
                              <br />
                              <small>
                                {(activity.distance / 1000).toFixed(2)} km • 
                                {Math.floor(activity.moving_time / 60)} min
                              </small>
                            </div>
                          ))}

                          {provided.placeholder}
                        </div>

                        <button
                          className="add-workout-btn"
                          onClick={() => onAddWorkout(day)}
                        >
                          +
                        </button>
                      </div>
                    )}
                  </Droppable>
                )
              })}

              {/* Week Summary */}
              <WeekSummary
                workouts={weekWorkouts}
                stravaActivities={weekStravaActivities}
                weekStart={weekStart}
                onCloneWeek={() => onCloneWeek(weekStart)}
                bulkEditMode={bulkEditMode}
              />
            </div>
          )
        })}
      </div>
    </DragDropContext>
  )
}
