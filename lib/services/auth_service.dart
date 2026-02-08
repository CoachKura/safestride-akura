import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class AuthService extends ChangeNotifier {
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
      _isLoading = true;
      notifyListeners();

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
