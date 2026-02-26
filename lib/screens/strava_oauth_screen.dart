import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Result returned by [StravaOAuthScreen] on successful auth.
class StravaAuthResult {
  final String userId;
  final String accessToken;
  final Map<String, dynamic> athlete;

  const StravaAuthResult({
    required this.userId,
    required this.accessToken,
    required this.athlete,
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

  // Production API — override via SAFESTRIDE_STRAVA_API_URL in .env
  static String get _apiUrl =>
      dotenv.env['SAFESTRIDE_STRAVA_API_URL'] ??
      'https://safestride-oauth.onrender.com';

  // Strava app has `www.akura.in` registered as callback domain
  static const String _redirectUri = 'https://www.akura.in/strava-callback';

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
    });
    try {
      final resp = await http.post(
        Uri.parse('$_apiUrl/api/strava-signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code}),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final result = StravaAuthResult(
          userId: data['user_id'] as String,
          accessToken: data['access_token'] as String,
          athlete: data['athlete'] as Map<String, dynamic>,
        );
        if (mounted) Navigator.pop(context, result);
      } else {
        final detail = (jsonDecode(resp.body) as Map?)?['detail'] ?? resp.body;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign-in failed: $detail')),
          );
          Navigator.pop(context, null);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
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
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
