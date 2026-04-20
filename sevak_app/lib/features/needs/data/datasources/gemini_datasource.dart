import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sevak_app/core/config/env_config.dart';
import 'dart:typed_data';

class GeminiDatasource {
  final GenerativeModel _model;

  GeminiDatasource()
      : _model = GenerativeModel(
          model: EnvConfig.geminiModel,
          apiKey: EnvConfig.geminiApiKey,
        );

  Future<Map<String, dynamic>> analyzeNeed(String text, List<int> imageBytes) async {
    final prompt = '''
You are SevakAI, an AI for NGO volunteer coordination in India.
Analyze the following community need report and extract structured data.

Input text: $text
(An image is attached showing a handwritten form or the scene of the need)

Return ONLY valid JSON with NO markdown formatting:
{
  "location": "extracted address or landmark",
  "needType": "FOOD | MEDICAL | SHELTER | CLOTHING | OTHER",
  "urgencyScore": <number 0-100>,
  "urgencyReason": "one sentence why this score",
  "peopleAffected": <number>,
  "description": "brief 2-sentence summary"
}

Scoring rules:
- 80-100: Life-threatening (medical emergency, no food for children)
- 50-79: Urgent but not life-threatening (shelter needed, clothing shortage)
- 0-49: Important but can wait 24+ hours

If a field cannot be determined, use "UNKNOWN" for strings or 0 for numbers.
If the image contains Hindi or Urdu text, transliterate to English.
''';

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', Uint8List.fromList(imageBytes)), // Assuming jpeg from compression
      ])
    ];

    try {
      final response = await _model.generateContent(content);
      var responseText = response.text ?? '';
      
      // Clean up markdown if Gemini hallucinates code blocks
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      return jsonDecode(responseText) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Gemini extraction failed: $e');
    }
  }
}
