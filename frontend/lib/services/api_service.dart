import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match_state.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api/match';

  Future<MatchState?> fetchMatchStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/status')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return MatchState.fromJson(data);
      }
    } catch (e) {
      // API error or server connecting
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchScorecard() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/scorecard')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // API error
    }
    return null;
  }

  Future<bool> playSimulation() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/sim/play'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> pauseSimulation() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/sim/pause'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> stepSimulation() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/sim/step'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetSimulation() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/sim/reset'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setSpeed(double multiplier) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sim/speed'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'multiplier': multiplier}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> injectCustomBall(int runs, String extraType, String wicketType) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sim/ball'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'runs': runs,
          'extraType': extraType,
          'wicketType': wicketType,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
