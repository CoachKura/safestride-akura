/// API Configuration for SafeStride
///
/// Update these URLs with your actual Render service URLs after deployment
class ApiConfig {
  // TODO: Replace with your actual Render service URLs
  // Get these from: https://dashboard.render.com/

  /// Main API service (port 8000)
  /// Example: 'https://safestride-api.onrender.com'
  static const String apiBaseUrl = 'YOUR_RENDER_API_URL_HERE';

  /// OAuth service (port 8002)
  /// Example: 'https://safestride-oauth.onrender.com'
  static const String oauthBaseUrl = 'YOUR_RENDER_OAUTH_URL_HERE';

  /// Webhook service (port 8001) - used for activity sync
  /// Example: 'https://safestride-webhooks.onrender.com'
  static const String webhookBaseUrl = 'YOUR_RENDER_WEBHOOK_URL_HERE';

  // API Endpoints
  static const String signupEndpoint = '/api/signup';
  static const String raceAnalysisEndpoint = '/api/race-analysis';
  static const String fitnessEndpoint = '/api/fitness';
  static const String workoutsEndpoint = '/api/workouts';
  static const String abilityEndpoint = '/api/ability';

  // OAuth Endpoints
  static const String stravaAuthEndpoint = '/strava/auth';
  static const String stravaCallbackEndpoint = '/strava/callback';

  // Webhook Endpoints
  static const String activityWebhookEndpoint = '/webhook';

  // Environment check
  static bool get isConfigured =>
      !apiBaseUrl.contains('YOUR_RENDER') &&
      !oauthBaseUrl.contains('YOUR_RENDER') &&
      !webhookBaseUrl.contains('YOUR_RENDER');

  // Full URLs
  static String get signup => '$apiBaseUrl$signupEndpoint';
  static String get raceAnalysis => '$apiBaseUrl$raceAnalysisEndpoint';
  static String get fitness => '$apiBaseUrl$fitnessEndpoint';
  static String get workouts => '$apiBaseUrl$workoutsEndpoint';
  static String get ability => '$apiBaseUrl$abilityEndpoint';
  static String get stravaAuth => '$oauthBaseUrl$stravaAuthEndpoint';
  static String get stravaCallback => '$oauthBaseUrl$stravaCallbackEndpoint';
}
