import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class AuthService extends ChangeNotifier {
  // Rate limit protection constants
  static const String _lastSignupKey = 'last_signup_attempt';
  static const int _minSignupInterval = 60; // seconds

  final _supabase = Supabase.instance.client;
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  AuthService() {
    _user = _supabase.auth.currentUser;
    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  Future<String?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _user = response.user;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> signUp(
      String email, String password, String fullName, String role) async {
    try {
      // Check rate limit before attempting signup
      final prefs = await SharedPreferences.getInstance();
      final lastAttempt = prefs.getString(_lastSignupKey);

      if (lastAttempt != null) {
        final lastTime = DateTime.parse(lastAttempt);
        final now = DateTime.now();
        final diff = now.difference(lastTime).inSeconds;

        if (diff < _minSignupInterval) {
          final wait = _minSignupInterval - diff;
          return 'Please wait $wait seconds before trying again';
        }
      }

      _isLoading = true;
      notifyListeners();

      // Store attempt timestamp BEFORE making the call
      await prefs.setString(_lastSignupKey, DateTime.now().toIso8601String());

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': role},
      );

      _user = response.user;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      // User-friendly error for rate limits
      if (e.toString().contains('429') ||
          e.toString().toLowerCase().contains('rate limit')) {
        return 'Too many signup attempts. Please wait 1 minute and try again.';
      }
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _user = null;
    notifyListeners();
  }

  // OAuth sign in methods
  Future<User?> signInWithGoogle() async {
    try {
      final response =
          await _supabase.auth.signInWithOAuth(OAuthProvider.google);
      return response ? _supabase.auth.currentUser : null;
    } catch (e) {
      return null;
    }
  }

  Future<User?> signInWithApple() async {
    try {
      final response =
          await _supabase.auth.signInWithOAuth(OAuthProvider.apple);
      return response ? _supabase.auth.currentUser : null;
    } catch (e) {
      return null;
    }
  }

  // Third-party connections (store tokens in profile)
  Future<void> connectGarmin() => _storeThirdPartyToken('garmin');
  Future<void> connectCoros() => _storeThirdPartyToken('coros');
  Future<void> connectStrava() => _storeThirdPartyToken('strava');

  Future<void> _storeThirdPartyToken(String provider) async {
    try {
      await _supabase.auth.signInWithOAuth(OAuthProvider.values.firstWhere(
        (p) => p.name == provider,
        orElse: () => OAuthProvider.google,
      ));
      notifyListeners();
    } catch (e) {
      developer.log(e.toString());
    }
  }
}
