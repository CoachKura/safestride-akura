import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'services/auth_service.dart';
import 'services/strava_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/evaluation_form_screen.dart';
import 'screens/tracker_screen.dart';
import 'screens/start_run_screen.dart';
import 'screens/logger_screen.dart';
import 'screens/workout_creator_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'theme/app_theme.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: 'https://yawxlwcniqfspcgefuro.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlhd3hsd2NuaXFmc3BjZ2VmdXJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk0OTcxODksImV4cCI6MjA4NTA3MzE4OX0.eky8ua6lEhzPcvG289wWDMWOjVGwr-bL8LLUnrzO4r4',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();
  final _stravaService = StravaService();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Handle deep links when app is opened from a link
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Check if app was opened from a deep link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      developer.log('Error getting initial deep link: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    developer.log('Received deep link: $uri');

    // Handle Strava OAuth callback (localhost or custom scheme)
    bool isStravaCallback = (uri.scheme == 'http' &&
            uri.host == 'localhost' &&
            uri.path == '/strava-callback') ||
        (uri.scheme == 'safestride' && uri.host == 'strava-callback');

    if (isStravaCallback) {
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        developer.log('Strava OAuth error: $error');
      } else if (code != null) {
        developer.log('Received Strava authorization code: $code');
        _stravaService.handleAuthorizationCode(code).then((success) {
          developer
              .log('Strava connection ${success ? 'successful' : 'failed'}');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AKURA SafeStride',
      debugShowCheckedModeBanner: false,
      
      // Modern Dark Theme (Primary)
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      
      // Optional: Enable light theme for bright sunlight conditions
      // themeMode: ThemeMode.system, // Auto-switch based on device settings
      
      home: const DashboardScreen(), // Direct access for testing
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/tracker': (context) => const TrackerScreen(),
        '/start_run': (context) => const StartRunScreen(),
        '/logger': (context) => const LoggerScreen(),
        '/workout_creator': (context) => const WorkoutCreatorScreen(),
        '/history': (context) => const HistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

// Check if user has completed evaluation form
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  bool _isChecking = true;
  bool _hasCompletedAssessment = false;

  @override
  void initState() {
    super.initState();
    _checkAssessmentStatus();
  }

  Future<void> _checkAssessmentStatus() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isChecking = false);
        return;
      }

      // Check if user has completed evaluation
      final assessmentResponse = await Supabase.instance.client
          .from('aisri_assessments')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      setState(() {
        _hasCompletedAssessment = assessmentResponse != null;
        _isChecking = false;
      });
    } catch (e) {
      // If error, assume no assessment completed
      setState(() {
        _hasCompletedAssessment = false;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasCompletedAssessment) {
      return const DashboardScreen();
    } else {
      return const EvaluationFormScreen();
    }
  }
}
