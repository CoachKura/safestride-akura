import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;
  String? _userEmail;
  String? _userName;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get token => _token;

  // Initialize auth state from stored token
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _userId = prefs.getString('user_id');
    _userEmail = prefs.getString('user_email');
    _userName = prefs.getString('user_name');
    
    if (_token != null) {
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      // TODO: Replace with actual Supabase auth
      // For now, simulate successful login
      
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock response
      final mockUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final mockToken = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
      final mockName = email.split('@')[0];
      
      // Store auth data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', mockToken);
      await prefs.setString('user_id', mockUserId);
      await prefs.setString('user_email', email);
      await prefs.setString('user_name', mockName);
      
      _isAuthenticated = true;
      _userId = mockUserId;
      _userEmail = email;
      _userName = mockName;
      _token = mockToken;
      
      notifyListeners();
      
      return {
        'success': true,
        'userId': mockUserId,
        'token': mockToken,
        'name': mockName,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Sign up with email and password
  Future<Map<String, dynamic>> signUp(
    String email,
    String password,
    String name,
  ) async {
    try {
      // TODO: Replace with actual Supabase auth
      // For now, simulate successful signup
      
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock response
      final mockUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final mockToken = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
      
      // Store auth data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', mockToken);
      await prefs.setString('user_id', mockUserId);
      await prefs.setString('user_email', email);
      await prefs.setString('user_name', name);
      
      _isAuthenticated = true;
      _userId = mockUserId;
      _userEmail = email;
      _userName = name;
      _token = mockToken;
      
      notifyListeners();
      
      return {
        'success': true,
        'userId': mockUserId,
        'token': mockToken,
        'name': name,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    
    _isAuthenticated = false;
    _userId = null;
    _userEmail = null;
    _userName = null;
    _token = null;
    
    notifyListeners();
  }

  // Check if token is valid
  Future<bool> validateToken() async {
    if (_token == null) return false;
    
    // TODO: Implement actual token validation with Supabase
    // For now, assume token is valid if it exists
    return true;
  }

  // Refresh token
  Future<bool> refreshToken() async {
    try {
      // TODO: Implement actual token refresh with Supabase
      // For now, simulate successful refresh
      
      final prefs = await SharedPreferences.getInstance();
      final newToken = 'refreshed_token_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('auth_token', newToken);
      
      _token = newToken;
      notifyListeners();
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
