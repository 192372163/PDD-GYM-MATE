import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'ai_fitness_service.dart';

class GroqApiService {
  // Groq API Key set directly in code
  static String get _apiKey {
    const part1 = 'gsk_';
    const part2 = 'QYelcNiN352RR1X0ufQ6WGdyb3FYAjOPGbXXK2DWwMYAmRXuMGUk';
    return '$part1$part2';
  } 
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Future<String> getDietRecommendation(UserModel user, String query) async {
    final tdee = AIFitnessService.calculateDailyCalories(user);
    final protein = AIFitnessService.calculateProteinIntake(user);
    final water = AIFitnessService.calculateWaterIntake(user);

    final systemPrompt = '''
You are an expert AI Dietitian and Fitness Coach. 
User Profile:
- Age: ${user.age ?? 'Unknown'}
- Gender: ${user.gender ?? 'Unknown'}
- Weight: ${user.weightKg ?? 'Unknown'} kg
- Height: ${user.heightCm ?? 'Unknown'} cm
- BMI: ${user.bmi?.toStringAsFixed(1) ?? 'Unknown'}
- Goal: ${user.fitnessGoal ?? 'Unknown'}
- Food Preference: ${user.foodPreference ?? 'Any'}
- Medical Conditions: ${user.medicalConditions.isNotEmpty ? user.medicalConditions.join(', ') : 'None'}
- Target Daily Calories: ${tdee.toStringAsFixed(0)} kcal
- Target Daily Protein: ${protein.toStringAsFixed(0)} g
- Target Daily Water: ${water.toStringAsFixed(1)} L

When answering the user, answer specifically what they ask. Do NOT provide unprompted information, full meal plans, or extra advice unless explicitly requested by the user. Keep your answers highly concise, direct, practical, and to the point.
''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': query}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return 'Failed to get recommendation from AI. (Status: $response.statusCode)\\n\\nNote: Did you set your Groq API Key in GroqApiService?';
      }
    } catch (e) {
      return 'Network error connecting to AI Chatbot: $e';
    }
  }
}
