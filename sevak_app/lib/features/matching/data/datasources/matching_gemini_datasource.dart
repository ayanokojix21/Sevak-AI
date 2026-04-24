import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/config/env_config.dart';

class MatchingGeminiDatasource {
  final GenerativeModel _model;

  MatchingGeminiDatasource()
      : _model = GenerativeModel(
          model: EnvConfig.geminiModel,
          apiKey: EnvConfig.geminiApiKey,
        );

  /// Prompt 2/3 — select best volunteer from a pool.
  /// [crossNgo] flag changes the prompt wording for multi-NGO pools.
  Future<Map<String, dynamic>> matchVolunteer({
    required String needType,
    required double lat,
    required double lng,
    required int urgencyScore,
    required String description,
    required List<Map<String, dynamic>> volunteersJson,
    bool crossNgo = false,
  }) async {
    final scope = crossNgo ? 'MULTIPLE NGOS' : 'your NGO';
    final prompt = '''
You are SevakAI's volunteer matching engine.

COMMUNITY NEED:
- Type: $needType
- Location: ($lat, $lng)
- Urgency score: $urgencyScore/100
- Description: $description

AVAILABLE VOLUNTEERS FROM $scope:
${jsonEncode(volunteersJson)}

Select the single BEST volunteer. Priority: 1) Skill match, 2) Closest distance, 3) Fewest active tasks.

Return ONLY valid JSON with NO markdown:
{
  "matchedVolunteerUid": "<uid>",
  "reason": "<one sentence${crossNgo ? " mentioning their source NGO" : ""}>",
  "estimatedDistanceKm": <number>
}
''';

    debugPrint('[MatchingGemini] Calling Gemini for ${volunteersJson.length} volunteers (crossNgo=$crossNgo)');

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      var text = response.text ?? '';
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[MatchingGemini] ERROR: $e');
      throw Exception('Gemini matching failed: $e');
    }
  }
}
