import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static List<String> get _keys => [
    dotenv.env['GEMINI_API_KEY'] ?? '',
    dotenv.env['GEMINI_API_KEY_1'] ?? '',
    dotenv.env['GEMINI_API_KEY_2'] ?? '',
    dotenv.env['GEMINI_API_KEY_3'] ?? '',
  ].where((k) => k.isNotEmpty).toList();

  static int _currentKeyIndex = 0;

  /// Helper to execute an AI call with automatic key rotation on failure.
  static Future<T> _executeWithRetry<T>(
    Future<T> Function(GenerativeModel model) action,
  ) async {
    if (_keys.isEmpty) throw Exception('Missing API Key(s) in .env');

    int attempts = 0;
    Object? lastError;

    while (attempts < _keys.length) {
      final key = _keys[_currentKeyIndex];
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: key,
      );

      try {
        return await action(model);
      } catch (e) {
        lastError = e;
        print('Gemini Error (Key Index: $_currentKeyIndex, Attempt: ${attempts + 1}): $e');
        
        // Rotate to next key for next attempt
        _currentKeyIndex = (_currentKeyIndex + 1) % _keys.length;
        attempts++;
        
        // If it's a rate limit or server error, we retry. 
        // If it's a bad request (e.g. safety blocks), retrying might not help but we do it anyway for robustness.
      }
    }

    throw Exception('AI exhausted all available API keys. Last error: $lastError');
  }

  static Future<String> chat({
    required String userMessage,
    required String hospitalContext,
  }) async {
    try {
      return await _executeWithRetry((model) async {
        final prompt = '''
You are RapidCare AI, a hospital emergency coordination assistant. 
Answer ONLY about hospital operations. Be brief and direct.

Current hospital data:
$hospitalContext

Staff question: $userMessage
''';
        
        final response = await model.generateContent([Content.text(prompt)]);
        return response.text ?? 'Unable to process request.';
      });
    } catch (e) {
      return 'AI currently unavailable: ${e.toString()}';
    }
  }

  static Future<String> analyzeClinical({
    required String patientData,
  }) async {
    try {
      return await _executeWithRetry((model) async {
        final prompt = '''
You are a senior medical consultant. Analyze the following patient data and provide a structured synthesis.

FORMAT REQUIREMENTS:
Use exactly 4 sections separated by "---SECTION---".
Section 1: Differential Diagnoses (Top 3 with rationale)
Section 2: Immediate Interventions (Next 4 hours)
Section 3: Priority Monitoring (Vitals/Labs frequency)
Section 4: Discharge/Transfer Criteria

PATIENT DATA:
$patientData

Provide clinical, professional, and concise output.
''';

        final response = await model.generateContent([Content.text(prompt)]);
        return response.text ?? 'Analysis failed.';
      });
    } catch (e) {
      return 'AI clinical analysis failed: ${e.toString()}';
    }
  }
}
