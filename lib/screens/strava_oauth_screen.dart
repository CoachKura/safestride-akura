import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'strava_stats_screen.dart';
import '../services/strava_session_service.dart';

/// Result returned by [StravaOAuthScreen] on successful auth.
class StravaAuthResult {
  final String userId;
  final String stravaAthleteId;
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> athlete;
  final bool isNewUser;

  const StravaAuthResult({
    required this.userId,
    required this.stravaAthleteId,
    required this.accessToken,
    required this.refreshToken,
    required this.athlete,
    this.isNewUser = true,
  });
}

class StravaOAuthScreen extends StatefulWidget {
  const StravaOAuthScreen({super.key});

  @override
  State<StravaOAuthScreen> createState() => _StravaOAuthScreenState();
}

class _StravaOAuthScreenState extends State<StravaOAuthScreen> {
  late final WebViewController _controller;
  bool _loading = false;
  String _loadingMessage = 'Connecting to Strava…';
  String _subMessage = '';

  // Production API — override via SAFESTRIDE_STRAVA_API_URL in .env
  static String get _apiUrl =>
      dotenv.env['SAFESTRIDE_STRAVA_API_URL'] ?? 'https://api.akura.in';

  // For mobile WebView OAuth, use localhost (which is in Strava allowed domains)
  // This allows the WebView to intercept the callback before it tries to navigate externally
  static const String _redirectUri = 'http://localhost/strava-callback';

  @override
  void initState() {
    super.initState();
    final authUrl = Uri.parse('https://www.strava.com/oauth/authorize').replace(
      queryParameters: {
        'client_id': dotenv.env['STRAVA_CLIENT_ID'] ?? '162971',
        'redirect_uri': _redirectUri,
        'response_type': 'code',
        'approval_prompt': 'auto',
        'scope': 'read,activity:read,activity:read_all,profile:read_all',
      },
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest req) {
            if (req.url.startsWith(_redirectUri)) {
              final uri = Uri.parse(req.url);
              final code = uri.queryParameters['code'];
              final error = uri.queryParameters['error'];
              if (error != null) {
                Navigator.pop(context, null);
                return NavigationDecision.prevent;
              }
              if (code != null) {
                _exchangeCode(code);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(authUrl);
  }

  Future<void> _exchangeCode(String code) async {
    setState(() {
      _loading = true;
      _loadingMessage = 'Signing you in…';
      _subMessage = 'Exchanging authorization code';
    });

    try {
      // Step 1: Exchange code for tokens directly with Strava
      // IMPORTANT: redirect_uri must match the one used during authorization
      final tokenResp = await http.post(
        Uri.parse('https://www.strava.com/oauth/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client_id': dotenv.env['STRAVA_CLIENT_ID'] ?? '162971',
          'client_secret': dotenv.env['STRAVA_CLIENT_SECRET'],
          'code': code,
          'grant_type': 'authorization_code',
          'redirect_uri': _redirectUri, // MUST match authorization request
        }),
      );

      if (tokenResp.statusCode != 200) {
        throw Exception('Token exchange failed: ${tokenResp.body}');
      }

      final tokenData = jsonDecode(tokenResp.body) as Map<String, dynamic>;
      final accessToken = tokenData['access_token'] as String;
      final refreshToken = tokenData['refresh_token'] as String;
      final athlete = tokenData['athlete'] as Map<String, dynamic>;
      final stravaAthleteId = athlete['id'].toString();

      setState(() {
        _loadingMessage = 'Creating your profile…';
        _subMessage = 'Setting up your account';
      });

      // Step 2: Get current Supabase user or create one
      final supabaseClient = Supabase.instance.client;
      final currentUser = supabaseClient.auth.currentUser;

      String userId;
      bool isNewUser = false;

      if (currentUser != null) {
        // User already logged in with email
        userId = currentUser.id;
      } else {
        // Create new user with Strava email
        final email =
            athlete['email'] as String? ?? '$stravaAthleteId@strava.user';
        final password =
            'strava_$stravaAthleteId\_${DateTime.now().millisecondsSinceEpoch}';

        try {
          final authResp = await supabaseClient.auth.signUp(
            email: email,
            password: password,
          );
          userId = authResp.user!.id;
          isNewUser = true;
        } catch (e) {
          // User might already exist, try to sign in
          final authResp = await supabaseClient.auth.signInWithPassword(
            email: email,
            password: password,
          );
          userId = authResp.user!.id;
        }
      }

      setState(() {
        _loadingMessage = 'Saving Strava connection…';
        _subMessage = 'Almost done!';
      });

      // Step 3: Save to database
      await supabaseClient.from('athletes').upsert({
        'id': userId,
        'strava_athlete_id': stravaAthleteId,
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'firstname': athlete['firstname'],
        'lastname': athlete['lastname'],
        'profile_photo': athlete['profile'],
        'city': athlete['city'],
        'state': athlete['state'],
        'country': athlete['country'],
        'sex': athlete['sex'],
        'weight': athlete['weight'],
        'updated_at': DateTime.now().toIso8601String(),
      });

      final result = StravaAuthResult(
        userId: userId,
        stravaAthleteId: stravaAthleteId,
        accessToken: accessToken,
        refreshToken: refreshToken,
        athlete: athlete,
        isNewUser: isNewUser,
      );

      // Persist session for auto-login
      await StravaSessionService.save(result);

      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
        Navigator.pop(context, null);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect Strava')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      _loadingMessage,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    if (_subMessage.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _subMessage,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
