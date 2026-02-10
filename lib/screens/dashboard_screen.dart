import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/calendar_service.dart';
import '../services/aisri_calculator_service.dart';
import '../services/training_phase_manager.dart';
import '../services/ai_workout_generator_service.dart';
import '../models/workout_calendar_entry.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/aisri_dashboard_widget.dart';
import '../theme/dashboard_colors.dart';
import 'tracker_screen.dart';
import 'workout_creator_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart' as profile;
import 'assessment_screen.dart';
import 'evaluation_form_screen.dart';
import 'body_measurements_screen.dart';
import 'injuries_screen.dart';
import 'goals_screen.dart';
import 'athlete_goals_screen.dart';
import 'kura_coach_calendar_screen.dart';
import 'admin_batch_generation_screen.dart';
import 'start_run_screen.dart';
import 'safety_gates_screen.dart';
import 'workout_history_screen.dart';
import 'structured_workout_list_screen.dart';
import 'garmin_device_screen.dart';
import 'dart:developer' as developer;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _DashboardHome(
          onNavigate: (index) => setState(() => _currentIndex = index)),
      const CalendarScreen(),
      const TrackerScreen(),
      const WorkoutCreatorScreen(),
      const profile.ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _DashboardHome extends StatefulWidget {
  final Function(int) onNavigate;

  const _DashboardHome({required this.onNavigate});

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  final CalendarService _calendarService = CalendarService();
  String userName = 'Athlete';
  double AISRIScore = 0.0;
  int currentStreak = 0;
  double weeklyDistance = 0.0;
  bool isLoading = true;
  WorkoutCalendarEntry? todayWorkout;
  WorkoutCalendarEntry? tomorrowWorkout;
  
  // AISRI System Data
  Map<String, dynamic>? _AISRIData;
  Map<String, dynamic>? _trainingPhase;
  final bool _showFullAISRI = false;

  // GPS Activity Data for Fitness Metrics
  int todaySteps = 0;
  double todayDistance = 0.0;
  int todayCalories = 0;
  int avgHeartRate = 0;
  List<double> weeklySteps = List.filled(7, 0.0);

  // Pillar scores
  Map<String, int> pillarScores = {
    'adaptability': 0,
    'injury_risk': 0,
    'fatigue': 0,
    'recovery': 0,
    'intensity': 0,
    'consistency': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadGPSActivityData();
    _loadAISRIData(); // Load AISRI data for 6-pillar visualization
  }

  Future<void> _loadUserData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        developer.log(
            '⚠️ WARNING: No authenticated user found! Using mock data for testing...');
        setState(() {
          userName = 'KURA SATHYAMOORTHY';
          AISRIScore = 52.0;
          pillarScores = {
            'adaptability': 65,
            'injury_risk': 45,
            'fatigue': 58,
            'recovery': 52,
            'intensity': 48,
            'consistency': 62,
          };
          currentStreak = 5;
          weeklyDistance = 27.2;
          isLoading = false;
        });
        return;
      }

      developer.log('🔍 DEBUG: Loading dashboard data for user: $userId');

      // Fetch today's and tomorrow's workouts
      todayWorkout = await _calendarService.getTodayWorkout();
      tomorrowWorkout = await _calendarService.getTomorrowWorkout();

      // Fetch user name from profiles
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('name')
          .eq('id', userId)
          .maybeSingle();

      developer.log('🔍 DEBUG: Profile response: $profileResponse');

      // Fetch AISRI score from latest assessment
      final AISRIResponse = await Supabase.instance.client
          .from('AISRI_assessments')
          .select(
              'total_score, AISRI_score, risk_level, pillar_adaptability, pillar_injury_risk, pillar_fatigue, pillar_recovery, pillar_intensity, pillar_consistency')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      developer.log('🔍 DEBUG: AISRI response: $AISRIResponse');

      if (AISRIResponse == null) {
        developer.log('⚠️ WARNING: No AISRI assessment found for user!');
      } else {
        developer.log('✅ Total Score: ${AISRIResponse['total_score']}');
        developer.log('✅ AISRI Score: ${AISRIResponse['AISRI_score']}');
        developer.log('✅ Risk Level: ${AISRIResponse['risk_level']}');
        developer.log(
            '✅ Pillar Adaptability: ${AISRIResponse['pillar_adaptability']}');
        developer.log(
            '✅ Pillar Injury Risk: ${AISRIResponse['pillar_injury_risk']}');
        developer.log('✅ Pillar Fatigue: ${AISRIResponse['pillar_fatigue']}');
        developer.log('✅ Pillar Recovery: ${AISRIResponse['pillar_recovery']}');
        developer
            .log('✅ Pillar Intensity: ${AISRIResponse['pillar_intensity']}');
        developer.log(
            '✅ Pillar Consistency: ${AISRIResponse['pillar_consistency']}');
      }

      // Calculate current streak from GPS activities
      final gpsActivitiesResponse = await Supabase.instance.client
          .from('gps_activities')
          .select('start_time, distance_meters')
          .eq('user_id', userId)
          .order('start_time', ascending: false)
          .limit(30);

      // Calculate weekly distance from GPS activities (last 7 days)
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final weeklyResponse = await Supabase.instance.client
          .from('gps_activities')
          .select('distance_meters')
          .eq('user_id', userId)
          .gte('start_time', weekAgo.toIso8601String());

      setState(() {
        userName = profileResponse?['name'] ?? 'Athlete';
        // Use AISRI_score if total_score is null
        AISRIScore =
            ((AISRIResponse?['total_score'] ?? AISRIResponse?['AISRI_score']) ??
                    0.0)
                .toDouble();

        // Update pillar scores
        pillarScores = {
          'adaptability': AISRIResponse?['pillar_adaptability'] ?? 0,
          'injury_risk': AISRIResponse?['pillar_injury_risk'] ?? 0,
          'fatigue': AISRIResponse?['pillar_fatigue'] ?? 0,
          'recovery': AISRIResponse?['pillar_recovery'] ?? 0,
          'intensity': AISRIResponse?['pillar_intensity'] ?? 0,
          'consistency': AISRIResponse?['pillar_consistency'] ?? 0,
        };

        currentStreak = _calculateStreakFromGPS(gpsActivitiesResponse);
        weeklyDistance = _calculateTotalDistanceFromGPS(weeklyResponse);
        isLoading = false;
      });

      developer.log('✅ Dashboard state updated! AISRI Score: $AISRIScore');
      developer.log('✅ Pillar scores: $pillarScores');
    } catch (e, stackTrace) {
      developer.log('❌ ERROR loading user data: $e');
      developer.log('Stack trace: $stackTrace');
      setState(() => isLoading = false);
    }
  }

  int _calculateStreakFromGPS(List<dynamic> activities) {
    if (activities.isEmpty) return 0;

    int streak = 0;
    DateTime today = DateTime.now();
    DateTime checkDate = DateTime(today.year, today.month, today.day);

    for (var activity in activities) {
      DateTime activityDate = DateTime.parse(activity['start_time']);
      DateTime activityDay =
          DateTime(activityDate.year, activityDate.month, activityDate.day);

      if (activityDay.isAtSameMomentAs(checkDate) ||
          activityDay.isBefore(checkDate)) {
        if (activityDay.difference(checkDate).inDays.abs() <= streak + 1) {
          if (!activityDay.isAtSameMomentAs(checkDate)) {
            streak++;
            checkDate = activityDay;
          }
        } else {
          break;
        }
      }
    }

    return streak;
  }

  double _calculateTotalDistanceFromGPS(List<dynamic> activities) {
    return activities.fold(
        0.0,
        (sum, a) =>
            sum + ((a['distance_meters'] ?? 0.0) as num).toDouble() / 1000);
  }

  Future<void> _loadGPSActivityData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        // Use mock data for testing
        setState(() {
          todaySteps = 8234;
          todayDistance = 6.2;
          todayCalories = 450;
          avgHeartRate = 142;
          weeklySteps = [5200, 7800, 6500, 8200, 4300, 9100, 8234];
        });
        return;
      }

      // Fetch today's activities
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final todayResponse = await Supabase.instance.client
          .from('gps_activities')
          .select('distance_meters, calories, avg_heart_rate')
          .eq('user_id', userId)
          .gte('start_time', startOfDay.toIso8601String());

      // Fetch weekly activities (last 7 days)
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final weeklyResponse = await Supabase.instance.client
          .from('gps_activities')
          .select('distance_meters, start_time')
          .eq('user_id', userId)
          .gte('start_time', weekAgo.toIso8601String())
          .order('start_time', ascending: true);

      // Calculate today's metrics
      double totalDistance = 0.0;
      int totalCalories = 0;
      List<int> heartRates = [];

      for (var activity in todayResponse) {
        totalDistance +=
            ((activity['distance_meters'] ?? 0.0) as num).toDouble();
        totalCalories += ((activity['calories'] ?? 0) as num).toInt();
        final hr = activity['avg_heart_rate'];
        if (hr != null && hr > 0) {
          heartRates.add((hr as num).toInt());
        }
      }

      // Calculate weekly steps (distance-based approximation: 1km ≈ 1312 steps)
      List<double> steps = List.filled(7, 0.0);
      for (var activity in weeklyResponse) {
        final activityDate = DateTime.parse(activity['start_time']);
        final dayIndex = today.difference(activityDate).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          final distance =
              ((activity['distance_meters'] ?? 0.0) as num).toDouble();
          steps[6 - dayIndex] +=
              (distance / 1000) * 1312; // Convert km to steps
        }
      }

      setState(() {
        todaySteps = ((totalDistance / 1000) * 1312).toInt();
        todayDistance = totalDistance / 1000;
        todayCalories = totalCalories;
        avgHeartRate = heartRates.isEmpty
            ? 0
            : (heartRates.reduce((a, b) => a + b) / heartRates.length).toInt();
        weeklySteps = steps;
      });
    } catch (e) {
      developer.log('Error loading GPS activity data: $e');
      // Keep default/mock values on error
    }
  }

  String _getAISRIRiskLevel() {
    if (AISRIScore >= 70) return 'Low Risk';
    if (AISRIScore >= 40) return 'Moderate';
    return 'High Risk';
  }

  Future<void> _loadAISRIData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch user profile for age and body metrics
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('date_of_birth, weight_kg, height_cm')
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse == null) return;

      // Calculate age
      final dobStr = profileResponse['date_of_birth'];
      if (dobStr == null) return;
      
      final dob = DateTime.parse(dobStr);
      final age = DateTime.now().difference(dob).inDays ~/ 365;
      final weightKg = profileResponse['weight_kg'] ?? 70.0;
      final heightCm = profileResponse['height_cm'] ?? 170.0;

      // Fetch recent workouts for load calculation
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final workoutsResponse = await Supabase.instance.client
          .from('workouts')
          .select('distance_km, duration_minutes, created_at')
          .eq('user_id', userId)
          .gte('created_at', thirtyDaysAgo.toIso8601String())
          .order('created_at', ascending: false);

      // Calculate total lifetime km for phase tracking
      final allWorkoutsResponse = await Supabase.instance.client
          .from('workouts')
          .select('distance_km')
          .eq('user_id', userId);

      final totalKm = (allWorkoutsResponse as List).fold<double>(
          0.0, (sum, w) => sum + ((w['distance_km'] ?? 0.0) as num).toDouble());

      // Fetch injury history
      final injuriesResponse = await Supabase.instance.client
          .from('injuries')
          .select('injury_name, severity, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Fetch latest assessment data (if available)
      final assessmentResponse = await Supabase.instance.client
          .from('AISRI_assessments')
          .select('assessment_data')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // Fetch sleep data (placeholder - would come from health integration)
      final sleepData = {
        'hours': 7.5,
        'quality': 8,
      };

      // Calculate AISRI score
      final AISRIResult = AISRICalculatorService.calculateAISRIScore(
        age: age,
        weightKg: weightKg,
        heightCm: heightCm,
        recentWorkouts: {
          'workouts': workoutsResponse,
        },
        injuryHistory: {
          'injuries': injuriesResponse,
        },
        sleepData: sleepData,
        assessmentData: assessmentResponse?['assessment_data'] ?? {},
        subjectiveFeel: 7, // Default to 7/10
      );

      // Get current training phase
      final trainingPhase = TrainingPhaseManager.getCurrentPhase(totalKm);

      setState(() {
        _AISRIData = AISRIResult;
        _trainingPhase = trainingPhase;
      });
    } catch (e) {
      developer.log('Error loading AISRI data: $e');
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          // Navigate to login screen - you may need to adjust this route
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error logging out: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(
          child: CircularProgressIndicator(
            color: Colors.deepPurple,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header with More Menu
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.purple.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Welcome back, $userName! 👋',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                            ),
                          ),
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'profile':
                                widget.onNavigate(4); // Navigate to Profile
                                break;
                              case 'workout_history':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const WorkoutHistoryScreen(),
                                  ),
                                );
                                break;
                              case 'kura_coach_goals':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AthleteGoalsScreen(),
                                  ),
                                );
                                break;
                              case 'kura_coach_calendar':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const KuraCoachCalendarScreen(),
                                  ),
                                );
                                break;
                              case 'structured_workouts':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        StructuredWorkoutListScreen(),
                                  ),
                                );
                                break;
                              case 'admin_batch_generation':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AdminBatchGenerationScreen(),
                                  ),
                                );
                                break;
                              case 'garmin_device':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const GarminDeviceScreen(),
                                  ),
                                );
                                break;
                              case 'assessment':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AssessmentScreen(),
                                  ),
                                );
                                break;
                              case 'evaluation':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EvaluationFormScreen(),
                                  ),
                                );
                                break;
                              case 'measurements':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const BodyMeasurementsScreen(),
                                  ),
                                );
                                break;
                              case 'injuries':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const InjuriesScreen(),
                                  ),
                                );
                                break;
                              case 'manual_training':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const WorkoutCreatorScreen(),
                                  ),
                                );
                                break;
                              case 'logout':
                                _handleLogout();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'profile',
                              child: Row(
                                children: [
                                  Icon(Icons.person, color: Colors.deepPurple),
                                  SizedBox(width: 12),
                                  Text('Profile'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'workout_history',
                              child: Row(
                                children: [
                                  Icon(Icons.history,
                                      color: Colors.deepPurple),
                                  SizedBox(width: 12),
                                  Text('Workout History'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'kura_coach_goals',
                              child: Row(
                                children: [
                                  Icon(Icons.emoji_events,
                                      color: Colors.blue),
                                  SizedBox(width: 12),
                                  Text('Kura Coach Goals',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'kura_coach_calendar',
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_month,
                                      color: Colors.blue),
                                  SizedBox(width: 12),
                                  Text('Kura Coach Calendar',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'structured_workouts',
                              child: Row(
                                children: [
                                  Icon(Icons.format_list_numbered,
                                      color: Colors.blue),
                                  SizedBox(width: 12),
                                  Text('Structured Workouts',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'manual_training',
                              child: Row(
                                children: [
                                  Icon(Icons.fitness_center,
                                      color: Colors.green),
                                  SizedBox(width: 12),
                                  Text('Manual Training',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'admin_batch_generation',
                              child: Row(
                                children: [
                                  Icon(Icons.admin_panel_settings,
                                      color: Colors.purple),
                                  SizedBox(width: 12),
                                  Text('Admin: Generate Plans',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'garmin_device',
                              child: Row(
                                children: [
                                  Icon(Icons.watch, color: Colors.deepPurple),
                                  SizedBox(width: 12),
                                  Text('Garmin Device'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'assessment',
                              child: Row(
                                children: [
                                  Icon(Icons.assignment,
                                      color: Colors.deepPurple),
                                  SizedBox(width: 12),
                                  Text('Assessment'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'evaluation',
                              child: Row(
                                children: [
                                  Icon(Icons.checklist,
                                      color: Colors.deepPurple),
                                  SizedBox(width: 12),
                                  Text('Evaluation Form'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'measurements',
                              child: Row(
                                children: [
                                  Icon(Icons.straighten,
                                      color: Colors.deepPurple),
                                  SizedBox(width: 12),
                                  Text('Body Measurements'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'injuries',
                              child: Row(
                                children: [
                                  Icon(Icons.healing,
                                      color: Colors.deepPurple),
                                  SizedBox(width: 12),
                                  Text('Injuries'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text('Logout',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Today ${now.day}.${now.month.toString().padLeft(2, '0')}.${now.year}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Assessment Not Complete Reminder Card
              if (AISRIScore == 0.0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade300, width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 48,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '⚠️ Assessment Not Complete',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete your AISRI evaluation to unlock personalized training insights.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          widget.onNavigate(1); // Navigate to Calendar
                        },
                        icon: const Icon(Icons.assignment),
                        label: const Text('Start Evaluation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Today's Activity Card
              if (todayWorkout != null) ...[
                _buildTodayActivityCard(context, todayWorkout!),
                const SizedBox(height: 20),
              ],

              // Tomorrow's Planned Workout Card
              if (tomorrowWorkout != null) ...[
                _buildTomorrowWorkoutCard(context, tomorrowWorkout!),
                const SizedBox(height: 20),
              ],

              // AISRI Dashboard Widget - Full 6-Pillar Visualization
              if (_AISRIData != null && _trainingPhase != null) ...[
                AISRIDashboardWidget(
                  aisriData: _AISRIData!,
                  trainingPhase: _trainingPhase!,
                  onViewDetails: () {
                    if (_AISRIData!['safety_gates'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SafetyGatesScreen(
                            aisriData: _AISRIData!,
                            safetyGates: _AISRIData!['safety_gates'],
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
              ] else if (AISRIScore > 0.0) ...[
                // Fallback to simple AISRI card if full data not available
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AssessmentScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade400, Colors.deepPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'AISRI Score',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AISRIScore.toStringAsFixed(0),
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getAISRIRiskLevel(),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Fitness Metrics - Compact Circular Progress
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Activity',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCompactMetric(
                          icon: Icons.directions_walk,
                          value: todaySteps,
                          label: 'Steps',
                          goal: 10000,
                          color1: DashboardColors.stepsGradient[0],
                          color2: DashboardColors.stepsGradient[1],
                        ),
                        _buildCompactMetric(
                          icon: Icons.map,
                          value: todayDistance.toStringAsFixed(1),
                          label: 'km',
                          goal: 10,
                          goalValue: todayDistance,
                          color1: DashboardColors.distanceGradient[0],
                          color2: DashboardColors.distanceGradient[1],
                        ),
                        _buildCompactMetric(
                          icon: Icons.local_fire_department,
                          value: todayCalories,
                          label: 'Cal',
                          goal: 600,
                          color1: DashboardColors.caloriesGradient[0],
                          color2: DashboardColors.caloriesGradient[1],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Current Streak',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$currentStreak days',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const Text(' 🔥', style: TextStyle(fontSize: 24)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'This Week',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  '${weeklyDistance.toStringAsFixed(1)} km',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('📈', style: TextStyle(fontSize: 20)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Weekly Activity Chart
              Text(
                'Weekly Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildWeeklyStepsChart(),
              ),
              const SizedBox(height: 24),

              // Pillar Scores Section
              if (pillarScores.values.any((score) => score > 0)) ...[
                Text(
                  'Performance Pillars',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _PillarBar(
                        label: 'Adaptability',
                        score: pillarScores['adaptability']!,
                        icon: Icons.trending_up,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _PillarBar(
                        label: 'Injury Risk',
                        score: pillarScores['injury_risk']!,
                        icon: Icons.healing,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _PillarBar(
                        label: 'Fatigue',
                        score: pillarScores['fatigue']!,
                        icon: Icons.battery_charging_full,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _PillarBar(
                        label: 'Recovery',
                        score: pillarScores['recovery']!,
                        icon: Icons.bedtime,
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 12),
                      _PillarBar(
                        label: 'Intensity',
                        score: pillarScores['intensity']!,
                        icon: Icons.flash_on,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      _PillarBar(
                        label: 'Consistency',
                        score: pillarScores['consistency']!,
                        icon: Icons.calendar_today,
                        color: Colors.teal,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StartRunScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.directions_run, size: 24),
                      label: const Text('Start Run'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EvaluationFormScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.assignment, color: Colors.deepPurple),
                      label: const Text('Start Evaluation',
                          style: TextStyle(color: Colors.deepPurple)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.deepPurple, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quick Access Cards
              Text(
                'Quick Access',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _QuickAccessCard(
                      icon: Icons.fitness_center,
                      label: 'AISRI',
                      subtitle: 'Assessment',
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AssessmentScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAccessCard(
                      icon: Icons.calculate,
                      label: 'AISRI',
                      subtitle: 'Calculator',
                      color: Colors.green,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EvaluationFormScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAccessCard(
                      icon: Icons.phone,
                      label: 'Call',
                      subtitle: 'AISRI',
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EvaluationFormScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickAccessCard(
                      icon: Icons.monitor_weight,
                      label: 'Body',
                      subtitle: 'Tracking',
                      color: Colors.purple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BodyMeasurementsScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAccessCard(
                      icon: Icons.healing,
                      label: 'Injuries',
                      subtitle: 'Log',
                      color: Colors.red,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InjuriesScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAccessCard(
                      icon: Icons.emoji_events,
                      label: 'Goals',
                      subtitle: 'Dashboard',
                      color: Colors.amber,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GoalsScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyStepsChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxSteps = weeklySteps.reduce((a, b) => a > b ? a : b);
    const minBarHeight = 20.0;

    return Column(
      children: [
        // Chart
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final height = maxSteps > 0
                  ? (weeklySteps[index] / maxSteps * 120)
                      .clamp(minBarHeight, 120.0)
                  : minBarHeight;
              final isToday = index == 6;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Value label
                      if (weeklySteps[index] > 0)
                        Text(
                          '${(weeklySteps[index] / 1000).toStringAsFixed(1)}k',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Bar
                      Container(
                        height: height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isToday
                                ? DashboardColors.stepsGradient
                                : [Colors.grey[300]!, Colors.grey[400]!],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        // Day labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final isToday = index == 6;
            return Expanded(
              child: Text(
                days[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isToday ? Colors.deepPurple : Colors.grey[600],
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCompactMetric({
    required IconData icon,
    required dynamic value,
    required String label,
    required num goal,
    double? goalValue,
    required Color color1,
    required Color color2,
  }) {
    final numValue = goalValue ??
        (value is int
            ? value.toDouble()
            : (value is String
                ? double.tryParse(value) ?? 0.0
                : value as double));
    final progress = goal > 0 ? (numValue / goal).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color1),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color1, size: 24),
                  const SizedBox(height: 2),
                  Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTodayActivityCard(
      BuildContext context, WorkoutCalendarEntry workout) {
    // Check if it's a GPS activity
    final isGPSActivity = workout.athleteNotes?.contains('km') ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.teal.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'Today\'s Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isGPSActivity ? 'COMPLETED' : 'PLANNED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            workout.workout.workoutName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _ActivityMetric(
                icon: Icons.schedule,
                value: '${workout.workout.estimatedDurationMinutes}',
                unit: 'min',
              ),
              if (workout.athleteNotes?.contains('km') ?? false)
                _ActivityMetric(
                  icon: Icons.directions_run,
                  value: workout.athleteNotes!.split('•')[0].trim(),
                  unit: '',
                ),
              if (workout.athleteNotes?.contains('bpm') ?? false)
                _ActivityMetric(
                  icon: Icons.favorite,
                  value: workout.athleteNotes!
                      .split('HR:')[1]
                      .split('•')[0]
                      .trim(),
                  unit: '',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            workout.workout.workoutType.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTomorrowWorkoutCard(
      BuildContext context, WorkoutCalendarEntry workout) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: Colors.deepPurple, size: 24),
              const SizedBox(width: 8),
              Text(
                'Tomorrow\'s Workout',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            workout.workout.workoutName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            workout.workout.workoutType.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${workout.workout.estimatedDurationMinutes} min',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.fitness_center, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${workout.workout.exercises.length} exercises',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          if (workout.athleteNotes != null &&
              workout.athleteNotes!.length > 20) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      workout.athleteNotes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showTodayWorkoutSuggestion() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      final suggestion = await AIWorkoutGeneratorService.suggestTodayWorkout();
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text('Today\'s Suggestion'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    suggestion['type'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      suggestion['intensity'].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSuggestionRow(Icons.straighten, 
                      '${suggestion['suggested_distance']} km'),
                  const SizedBox(height: 8),
                  _buildSuggestionRow(Icons.timer, 
                      '${suggestion['suggested_duration']} minutes'),
                  const SizedBox(height: 8),
                  _buildSuggestionRow(Icons.favorite, 
                      '${suggestion['hr_zone_min']}-${suggestion['hr_zone_max']} bpm'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      suggestion['rationale'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    suggestion['description'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to start run screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StartRunScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Workout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating suggestion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSuggestionRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

class _ActivityMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;

  const _ActivityMetric({
    required this.icon,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        if (unit.isNotEmpty) ...[
          const SizedBox(width: 2),
          Text(
            unit,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillarBar extends StatelessWidget {
  final String label;
  final int score;
  final IconData icon;
  final Color color;

  const _PillarBar({
    required this.label,
    required this.score,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const Spacer(),
            Text(
              '$score',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
