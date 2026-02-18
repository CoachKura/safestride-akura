import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class StravaOAuthScreen extends StatefulWidget {
  const StravaOAuthScreen({super.key});

  @override
  State<StravaOAuthScreen> createState() => _StravaOAuthScreenState();
}

class _StravaOAuthScreenState extends State<StravaOAuthScreen> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    final authUrl = Uri.parse('https://www.strava.com/oauth/authorize').replace(
      queryParameters: {
        'client_id': '162971',
        'redirect_uri':
            'https://xzxnnswggwqtctcgpocr.supabase.co/auth/v1/callback',
        'response_type': 'code',
        'scope': 'read,activity:read_all,profile:read_all',
      },
    );

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith(
              'https://xzxnnswggwqtctcgpocr.supabase.co/auth/v1/callback',
            )) {
              final uri = Uri.parse(request.url);
              final code = uri.queryParameters['code'];

              if (code != null) {
                Navigator.pop(context, code);
              }

              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(authUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Strava'),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
