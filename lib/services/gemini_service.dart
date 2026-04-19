import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static Future<String> generateResponse(String prompt) async {
    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{"parts": [{"text": prompt}]}]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['candidates'][0]['content']['parts'][0]['text'];
        return answer.trim();
      } else {
        return "AI temporarily unavailable. Could not fetch generated answer.";
      }
    } catch (e) {
      return "AI temporarily unavailable.";
    }
  }
}
