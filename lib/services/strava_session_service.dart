import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/strava_oauth_screen.dart';

/// Persists and restores a [StravaAuthResult] across app restarts
/// using SharedPreferences.
class StravaSessionService {
  static const _kUserId = 'ss_user_id';
  static const _kAthleteId = 'ss_strava_athlete_id';
  static const _kAccessToken = 'ss_access_token';
  static const _kRefreshToken = 'ss_refresh_token';
  static const _kAthleteJson = 'ss_athlete_json';
  static const _kIsNewUser = 'ss_is_new_user';

  /// Save a session to disk.
  static Future<void> save(StravaAuthResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId, result.userId);
    await prefs.setString(_kAthleteId, result.stravaAthleteId);
    await prefs.setString(_kAccessToken, result.accessToken);
    await prefs.setString(_kRefreshToken, result.refreshToken);
    await prefs.setString(_kAthleteJson, jsonEncode(result.athlete));
    await prefs.setBool(_kIsNewUser, result.isNewUser);
  }

  /// Load a saved session, returns null if none exists.
  static Future<StravaAuthResult?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_kUserId);
    final athleteId = prefs.getString(_kAthleteId);
    final accessToken = prefs.getString(_kAccessToken);
    if (userId == null || athleteId == null || accessToken == null) {
      return null;
    }
    final athleteRaw = prefs.getString(_kAthleteJson);
    Map<String, dynamic> athlete = {};
    if (athleteRaw != null) {
      try {
        athlete = jsonDecode(athleteRaw) as Map<String, dynamic>;
      } catch (_) {}
    }
    return StravaAuthResult(
      userId: userId,
      stravaAthleteId: athleteId,
      accessToken: accessToken,
      refreshToken: prefs.getString(_kRefreshToken) ?? '',
      athlete: athlete,
      isNewUser: prefs.getBool(_kIsNewUser) ?? false,
    );
  }

  /// Remove saved session (logout).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
    await prefs.remove(_kAthleteId);
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kAthleteJson);
    await prefs.remove(_kIsNewUser);
  }

  /// Returns true if a session is saved.
  static Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kUserId) && prefs.containsKey(_kAccessToken);
  }
}
