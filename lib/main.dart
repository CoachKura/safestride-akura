import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'services/auth_service.dart';
import 'services/strava_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/evaluation_form_screen.dart';
import 'screens/tracker_screen.dart';
import 'screens/start_run_screen.dart';
import 'screens/logger_screen.dart';
import 'screens/workout_creator_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/devices_screen.dart';
import 'screens/strava_oauth_screen.dart';
import 'theme/app_theme.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // 🌐 PRODUCTION SUPABASE
  final supabaseUrl =
      dotenv.env['SUPABASE_URL'] ?? 'https://xzxnnswggwqtctcgpocr.supabase.co';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6d25tc3dnZ3dxdGN0Y2dwb2NyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc0NjczNDIsImV4cCI6MjA1MzA0MzM0Mn0.ztLLjbvhMDmFz-qPq2TLRCPflb2HM1QT0eC5IVHQ0Ss';
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // 🐳 LOCAL SUPABASE (Development - uncomment for local testing)
  // await Supabase.initialize(
  //   url: 'http://127.0.0.1:54321',
  //   anonKey: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
  // );

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
  final _navigatorKey = GlobalKey<NavigatorState>();

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

    // Handle Strava OAuth callback (localhost, custom scheme, or production domain)
    bool isStravaCallback =
        // Development localhost
        ((uri.scheme == 'http' || uri.scheme == 'https') &&
                uri.host == 'localhost' &&
                uri.path == '/strava-callback') ||
            // Custom app scheme
            (uri.scheme == 'safestride' && uri.host == 'strava-callback') ||
            // Production domains
            ((uri.scheme == 'https') &&
                (uri.host == 'akura.in' || uri.host == 'app.akura.in') &&
                uri.path == '/strava-callback');

    if (isStravaCallback) {
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        developer.log('Strava OAuth error: $error');
        _showNotification('Strava connection failed: $error', isError: true);
      } else if (code != null) {
        developer.log('Received Strava authorization code: $code');
        _showNotification('Connecting to Strava...', isError: false);

        _stravaService.handleAuthorizationCode(code).then((success) {
          developer
              .log('Strava connection ${success ? 'successful' : 'failed'}');

          if (success) {
            _showNotification('✅ Strava connected successfully!',
                isError: false);
          } else {
            _showNotification('❌ Failed to save Strava connection',
                isError: true);
          }
        });
      }
    }
  }

  void _showNotification(String message, {required bool isError}) {
    final context = _navigatorKey.currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AKURA SafeStride',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,

      // Modern Dark Theme (Primary)
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      // Start at login for production flow
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/devices': (context) => const DevicesScreen(),
        '/aisri': (context) => const EvaluationFormScreen(),
        '/strava-oauth': (context) => const StravaOAuthScreen(),
        '/tracker': (context) => const TrackerScreen(),
        '/start_run': (context) => const StartRunScreen(),
        '/logger': (context) => const LoggerScreen(),
        '/workout_creator': (context) => const WorkoutCreatorScreen(),
        '/history': (context) => const HistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
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
