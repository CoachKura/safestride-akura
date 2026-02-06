import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/workout_calendar_entry.dart';
import '../services/calendar_service.dart';
import '../widgets/workout_card.dart';
import '../widgets/gps_activity_tabs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'garmin_workout_builder_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarService _calendarService = CalendarService();
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  Map<DateTime, List<WorkoutCalendarEntry>> _workoutsByDate = {};
  WorkoutCalendarEntry? _todayWorkout;
  WorkoutCalendarEntry? _tomorrowWorkout;
  WorkoutCalendarEntry? _yesterdayWorkout;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() => _isLoading = true);
    
    try {
      // Load workouts for current month
      final workouts = await _calendarService.getWorkoutsForMonth(_focusedDay);
      
      // Load today/tomorrow/yesterday
      final today = await _calendarService.getTodayWorkout();
      final tomorrow = await _calendarService.getTomorrowWorkout();
      final yesterday = await _calendarService.getYesterdayWorkout();
      
      // Organize workouts by date
      final Map<DateTime, List<WorkoutCalendarEntry>> workoutsByDate = {};
      for (var workout in workouts) {
        final date = DateTime(
          workout.scheduledDate.year,
          workout.scheduledDate.month,
          workout.scheduledDate.day,
        );
        
        if (workoutsByDate[date] == null) {
          workoutsByDate[date] = [];
        }
        workoutsByDate[date]!.add(workout);
      }
      
      setState(() {
        _workoutsByDate = workoutsByDate;
        _todayWorkout = today;
        _tomorrowWorkout = tomorrow;
        _yesterdayWorkout = yesterday;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading workouts: $e');
      setState(() => _isLoading = false);
    }
  }

  List<WorkoutCalendarEntry> _getWorkoutsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _workoutsByDate[normalizedDay] ?? [];
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'skipped':
        return Colors.red;
      case 'rescheduled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Workout Calendar'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWorkouts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Today/Tomorrow/Yesterday Cards
                    _buildQuickAccessCards(),
                    
                    const SizedBox(height: 16),
                    
                    // Calendar Widget
                    _buildCalendar(),
                    
                    const SizedBox(height: 16),
                    
                    // Workouts for Selected Day
                    _buildSelectedDayWorkouts(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewWorkout(),
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text('Create Workout'),
      ),
    );
  }

  Widget _buildQuickAccessCards() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          // Today's Workout
          if (_todayWorkout != null)
            WorkoutCard(
              entry: _todayWorkout!,
              label: 'TODAY',
              labelColor: Colors.green,
              onComplete: () => _handleComplete(_todayWorkout!),
              onSkip: () => _handleSkip(_todayWorkout!),
              onTap: () => _showWorkoutDetails(_todayWorkout!),
            )
          else
            _buildEmptyCard('TODAY', Colors.green, 'No workout scheduled'),
          
          const SizedBox(height: 12),
          
          // Tomorrow's Workout
          if (_tomorrowWorkout != null)
            WorkoutCard(
              entry: _tomorrowWorkout!,
              label: 'TOMORROW',
              labelColor: Colors.blue,
              showActions: false,
              onTap: () => _showWorkoutDetails(_tomorrowWorkout!),
            )
          else
            _buildEmptyCard('TOMORROW', Colors.blue, 'No workout scheduled'),
          
          const SizedBox(height: 12),
          
          // Yesterday's Workout
          if (_yesterdayWorkout != null)
            WorkoutCard(
              entry: _yesterdayWorkout!,
              label: 'YESTERDAY',
              labelColor: Colors.grey,
              showActions: false,
              onTap: () => _showWorkoutDetails(_yesterdayWorkout!),
            )
          else
            _buildEmptyCard('YESTERDAY', Colors.grey, 'No workout scheduled'),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String label, Color color, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar<WorkoutCalendarEntry>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        eventLoader: _getWorkoutsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          markersMaxCount: 1,
          markerDecoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.green.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          _loadWorkouts();
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return const SizedBox();
            
            final workout = events.first as WorkoutCalendarEntry;
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 30),
              decoration: BoxDecoration(
                color: _getStatusColor(workout.status),
                shape: BoxShape.circle,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedDayWorkouts() {
    final workouts = _getWorkoutsForDay(_selectedDay ?? _focusedDay);
    
    if (workouts.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No workouts scheduled',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMMM d').format(_selectedDay ?? _focusedDay),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...workouts.map((workout) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WorkoutCard(
              entry: workout,
              onComplete: workout.isPending ? () => _handleComplete(workout) : null,
              onSkip: workout.isPending ? () => _handleSkip(workout) : null,
              onTap: () => _showWorkoutDetails(workout),
            ),
          )),
        ],
      ),
    );
  }

  void _handleComplete(WorkoutCalendarEntry workout) {
    showDialog(
      context: context,
      builder: (context) => _WorkoutCompletionDialog(
        workout: workout,
        onComplete: (duration, difficulty, pain, notes) async {
          final success = await _calendarService.markWorkoutComplete(
            calendarId: workout.id,
            durationMinutes: duration,
            difficultyRating: difficulty,
            painLevel: pain,
            notes: notes,
          );
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Workout completed! 💪')),
            );
            _loadWorkouts();
          }
        },
      ),
    );
  }
  
  void _createNewWorkout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GarminWorkoutBuilderScreen(
          scheduledDate: _selectedDay ?? DateTime.now(),
        ),
      ),
    ).then((result) {
      if (result != null) {
        _loadWorkouts();
      }
    });
  }

  void _handleSkip(WorkoutCalendarEntry workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Workout?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to skip this workout?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                // Store reason
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _calendarService.skipWorkout(workout.id, null);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Workout skipped')),
              );
              _loadWorkouts();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _showWorkoutDetails(WorkoutCalendarEntry workout) async {
    // Check if this is a GPS activity by checking if athleteNotes contains metrics
    final isGPSActivity = workout.athleteNotes != null && 
                          (workout.athleteNotes!.contains('Cadence:') || 
                           workout.athleteNotes!.contains('HR:') ||
                           workout.athleteNotes!.contains('Pace:'));
    
    if (isGPSActivity) {
      // Fetch full GPS activity data from database
      try {
        final supabase = Supabase.instance.client;
        final response = await supabase
            .from('gps_activities')
            .select()
            .eq('platform_activity_id', workout.workoutId)
            .single();
        
        if (!mounted) return;
        
        _showGPSActivitySheet(response, workout);
      } catch (e) {
        print('Error loading GPS activity: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading activity details: $e')),
        );
      }
    } else {
      // Show  planned workout details
      _showPlannedWorkoutSheet(workout);
    }
  }

  void _showPlannedWorkoutSheet(WorkoutCalendarEntry workout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  workout.workout.workoutName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.schedule,
                      '${workout.workout.estimatedDurationMinutes} min',
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.fitness_center,
                      workout.workout.workoutType,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.trending_up,
                      workout.workout.difficulty,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Exercises',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...workout.workout.exercises.map((exercise) => _buildExerciseTile(exercise)),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showGPSActivitySheet(Map<String, dynamic> activity, WorkoutCalendarEntry workout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: _buildGPSActivityDetail(activity, workout),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTile(Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (exercise.sets != null)
                Text('${exercise.sets} sets', style: TextStyle(color: Colors.grey[600])),
              if (exercise.sets != null && exercise.reps != null)
                Text(' × ', style: TextStyle(color: Colors.grey[600])),
              if (exercise.reps != null)
                Text('${exercise.reps} reps', style: TextStyle(color: Colors.grey[600])),
              if (exercise.durationSeconds != null)
                Text('${exercise.durationSeconds}s', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGPSActivityDetailSheet(Map<String, dynamic> activity, WorkoutCalendarEntry workout) {
    final distanceKm = (activity['distance_meters'] as num) / 1000;
    final durationMin = (activity['duration_seconds'] as int) / 60;
    final avgPace = activity['avg_pace'] as num?;
    final avgHR = activity['avg_heart_rate'] as num?;
    final maxHR = activity['max_heart_rate'] as num?;
    final avgCadence = activity['avg_cadence'] as num?;
    final maxCadence = activity['max_cadence'] as num?;
    final elevGain = activity['elevation_gain'] as num?;
    final elevLoss = activity['elevation_loss'] as num?;
    final calories = activity['calories'] as int?;
    final avgPower = activity['avg_watts'] as num?;
    final maxSpeed = activity['max_speed'] as num?;
    final avgStrideLength = activity['avg_stride_length'] as num?;
    final avgGroundContactTime = activity['avg_ground_contact_time'] as num?;
    final avgVerticalOscillation = activity['avg_vertical_oscillation'] as num?;
    
    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Header
              Row(
                children: [
                  const Icon(Icons.directions_run, size: 28, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.workout.workoutName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, MMMM d, y • h:mm a').format(workout.scheduledDate),
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Key Metrics Grid
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Distance',
                            '${distanceKm.toStringAsFixed(2)} km',
                            Icons.straighten,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Time',
                            '${durationMin.floor()}:${((durationMin % 1) * 60).round().toString().padLeft(2, '0')}',
                            Icons.timer,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Avg Pace',
                            avgPace != null ? '${avgPace.toStringAsFixed(2)} min/km' : 'N/A',
                            Icons.speed,
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Elevation',
                            elevGain != null ? '${elevGain.round()} m' : 'N/A',
                            Icons.terrain,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Heart Rate Section
              if (avgHR != null) ...[
                _buildSectionHeader('💓 Heart Rate'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Average', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              '${avgHR.round()} bpm',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      if (maxHR != null) ...[
                        Container(width: 1, height: 40, color: Colors.grey[300]),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Maximum', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                '${maxHR.round()} bpm',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Cadence Section
              if (avgCadence != null) ...[
                _buildSectionHeader('👟 Cadence'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Average', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              '${avgCadence.round()} spm',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                      if (maxCadence != null) ...[
                        Container(width: 1, height: 40, color: Colors.grey[300]),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Maximum', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                '${maxCadence.round()} spm',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Advanced Biomechanics
              if (avgStrideLength != null || avgGroundContactTime != null || avgVerticalOscillation != null) ...[
                _buildSectionHeader('📊 Advanced Biomechanics'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      if (avgStrideLength != null)
                        _buildDetailRow('Stride Length', '${avgStrideLength.toStringAsFixed(2)} m', Icons.height),
                      if (avgGroundContactTime != null)
                        _buildDetailRow('Ground Contact Time', '${avgGroundContactTime.round()} ms', Icons.timer_outlined),
                      if (avgVerticalOscillation != null)
                        _buildDetailRow('Vertical Oscillation', '${avgVerticalOscillation.toStringAsFixed(1)} cm', Icons.swap_vert),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Additional Metrics
              _buildSectionHeader('📈 Additional Metrics'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    if (maxSpeed != null)
                      _buildDetailRow('Max Speed', '${maxSpeed.toStringAsFixed(2)} km/h', Icons.flash_on),
                    if (elevLoss != null)
                      _buildDetailRow('Elevation Loss', '${elevLoss.round()} m', Icons.arrow_downward),
                    if (calories != null)
                      _buildDetailRow('Calories', '$calories kcal', Icons.local_fire_department),
                    if (avgPower != null)
                      _buildDetailRow('Avg Power', '${avgPower.round()} W', Icons.bolt),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.purple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGPSActivityDetail(Map<String, dynamic> activity, WorkoutCalendarEntry workout) {
    return GPSActivityTabs(activity: activity, workout: workout);
  }
}

class _WorkoutCompletionDialog extends StatefulWidget {
  final WorkoutCalendarEntry workout;
  final Function(int duration, int difficulty, int pain, String? notes) onComplete;

  const _WorkoutCompletionDialog({
    required this.workout,
    required this.onComplete,
  });

  @override
  State<_WorkoutCompletionDialog> createState() => _WorkoutCompletionDialogState();
}

class _WorkoutCompletionDialogState extends State<_WorkoutCompletionDialog> {
  int _duration = 30;
  int _difficulty = 3;
  int _pain = 0;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _duration = widget.workout.workout.estimatedDurationMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Complete Workout'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: $_duration minutes'),
            Slider(
              value: _duration.toDouble(),
              min: 5,
              max: 120,
              divisions: 23,
              label: '$_duration min',
              onChanged: (value) => setState(() => _duration = value.round()),
            ),
            const SizedBox(height: 16),
            Text('Difficulty: ${_getDifficultyLabel(_difficulty)}'),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _difficulty = index + 1),
                  icon: Icon(
                    index < _difficulty ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Text('Pain Level: $_pain/10'),
            Slider(
              value: _pain.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: '$_pain',
              onChanged: (value) => setState(() => _pain = value.round()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onComplete(
              _duration,
              _difficulty,
              _pain,
              _notesController.text.isEmpty ? null : _notesController.text,
            );
            Navigator.pop(context);
          },
          child: const Text('Complete'),
        ),
      ],
    );
  }

  String _getDifficultyLabel(int rating) {
    switch (rating) {
      case 1: return 'Very Easy';
      case 2: return 'Easy';
      case 3: return 'Moderate';
      case 4: return 'Hard';
      case 5: return 'Very Hard';
      default: return 'Moderate';
    }
  }
}
