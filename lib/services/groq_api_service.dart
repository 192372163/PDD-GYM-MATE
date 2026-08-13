import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class GroqApiService {
  // Configurable server endpoint URL (defaults to localhost:3000 backend server)
  static String get _serverEndpoint {
    const customEndpoint = String.fromEnvironment('BACKEND_SERVER_URL');
    if (customEndpoint.isNotEmpty) {
      return '$customEndpoint/api/groq/chat';
    }
    return 'http://localhost:3000/api/groq/chat';
  }

  /// Sends user query along with user profile and session context to backend NLP + Groq pipeline.
  Future<String> getDietRecommendation(UserModel user, String query, {List<Map<String, String>>? history}) async {
    try {
      final userProfileJson = {
        'uid': user.uid,
        'name': user.name,
        'email': user.email,
        'age': user.age,
        'gender': user.gender,
        'weightKg': user.weightKg,
        'heightCm': user.heightCm,
        'bmi': user.bmi,
        'fitnessGoal': user.fitnessGoal,
        'experienceLevel': user.experienceLevel,
        'foodPreference': user.foodPreference,
        'dailyActivity': user.dailyActivity,
        'medicalConditions': user.medicalConditions,
      };

      final payloadMessages = <Map<String, String>>[];
      if (history != null && history.isNotEmpty) {
        payloadMessages.addAll(history);
      }
      payloadMessages.add({'role': 'user', 'content': query});

      final response = await http.post(
        Uri.parse(_serverEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'userProfile': userProfileJson,
          'sessionId': user.uid.isNotEmpty ? user.uid : 'guest_session',
          'messages': payloadMessages,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'] ?? 'No response received from AI server.';
      } else {
        return 'Failed to get recommendation from AI Server. (Status: ${response.statusCode})\n\nNote: Make sure the server backend is running on port 3000 with GROQ_API_KEY set in .env.';
      }
    } catch (e) {
      return 'Network error connecting to AI Backend Server: $e';
    }
  }
}
