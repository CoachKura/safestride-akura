import 'dart:convert';
import 'package:http/http.dart' as http;

class WorkoutAIService {
  static const baseUrl = "http://127.0.0.1:8001";

  static Future<dynamic> generateWorkout(String athleteId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/agent/generate-workout"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"athlete_id": athleteId}),
    );

    return jsonDecode(response.body);
  }
}
