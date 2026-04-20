import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static int _currentKeyIndex = 0;
  static final List<String> _keys = [
    dotenv.env['GEMINI_API_KEY'] ?? '',
    dotenv.env['GEMINI_API_KEY_1'] ?? '',
    dotenv.env['GEMINI_API_KEY_2'] ?? '',
    dotenv.env['GEMINI_API_KEY_3'] ?? '',
  ].where((k) => k.isNotEmpty).toList();

  static String get _activeKey {
    if (_keys.isEmpty) return '';
    final key = _keys[_currentKeyIndex];
    _currentKeyIndex = (_currentKeyIndex + 1) % _keys.length;
    return key;
  }

  static Future<String> chat({
    required String userMessage,
    required String hospitalContext,
  }) async {
    final key = _activeKey;
    if (key.isEmpty) return 'AI Error: Missing API Key(s) in .env';
    
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: key,
        // v1beta is often the default, specify v1 if needed via safetySettings or other config
      );

      final prompt = '''
You are RapidCare AI, a hospital emergency coordination assistant. 
Answer ONLY about hospital operations. Be brief and direct.

Current hospital data:
$hospitalContext

Staff question: $userMessage
''';
      
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to process request.';
    } catch (e) {
      print('Gemini chat error (key index $_currentKeyIndex): $e');
      if (e.toString().contains('429')) {
         return 'AI rate limited. Retrying next key...';
      }
      return 'AI unavailable. Check network or API limits.';
    }
  }

  static Future<String> analyzeClinical({
    required String patientData,
  }) async {
    final key = _activeKey;
    if (key.isEmpty) return 'Analysis Error: Missing API Key';

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: key,
      );

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
    } catch (e) {
      print('Gemini analyzeClinical error: $e');
      return 'AI unreachable for clinical analysis. Try again later.';
    }
  }
}
