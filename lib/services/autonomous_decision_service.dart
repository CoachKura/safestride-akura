import 'dart:convert';
import 'package:http/http.dart' as http;

class AutonomousDecisionService {
  static const baseUrl = "http://192.168.1.10:8001";

  static Future<dynamic> runDecision(String athleteId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/agent/autonomous-decision"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"athlete_id": athleteId}),
    );

    return jsonDecode(response.body);
  }
}
