import 'dart:convert';
import 'package:http/http.dart' as http;

class AICommanderService {
  static const baseUrl = "http://127.0.0.1:8000";

  static Future<dynamic> runCommander(String goal, {String? athleteId}) async {
    final response = await http.post(
      Uri.parse("$baseUrl/agent/commander"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "goal": goal,
        "athlete_id": athleteId,
      }),
    );

    return jsonDecode(response.body);
  }
}
