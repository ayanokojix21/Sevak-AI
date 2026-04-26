import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/env_config.dart';
import '../../../../core/constants/app_constants.dart';

/// AI-powered volunteer matching datasource.
///
/// Architecture: **Groq Primary (openai/gpt-oss-120b)** → Gemini Fallback.
/// Uses the strongest reasoning model for optimal volunteer selection.
class MatchingAiDatasource {
  late final GenerativeModel _geminiModel;

  MatchingAiDatasource() {
    _geminiModel = GenerativeModel(
      model: EnvConfig.geminiModel,
      apiKey: EnvConfig.geminiApiKey,
    );
  }

  /// Selects the best volunteer from a pre-scored pool.
  /// [crossNgo] flag adjusts the prompt for multi-NGO matching.
  Future<Map<String, dynamic>> matchVolunteer({
    required String needType,
    required double lat,
    required double lng,
    required int urgencyScore,
    required String description,
    required List<Map<String, dynamic>> volunteersJson,
    required int requiredVolunteerCount,
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
- Required Volunteers: $requiredVolunteerCount

AVAILABLE VOLUNTEERS FROM $scope (pre-scored by the system):
${jsonEncode(volunteersJson)}

CRITICAL LOAD BALANCING RULES:
1. You MUST select up to $requiredVolunteerCount volunteers. If there are fewer available, select all of them.
2. Prioritize volunteers with lower `activeTasks` and higher `preScore`.
3. DO NOT assign the same volunteer repeatedly if others with comparable skills and distance are available and idle (activeTasks = 0).

Return ONLY valid JSON with NO markdown in this format:
{
  "matchedVolunteerUids": ["<uid1>", "<uid2>"],
  "reason": "<one sentence explaining the selection and load balancing rationale${crossNgo ? " mentioning source NGOs" : ""}>"
}
''';

    debugPrint('[MatchingAI] Matching ${volunteersJson.length} volunteers (crossNgo=$crossNgo)');

    try {
      // Primary: Groq reasoning model
      final apiKey = EnvConfig.groqApiKey;
      if (apiKey.isEmpty) throw Exception('GROQ_API_KEY not configured');

      debugPrint('[MatchingAI] → Groq ${EnvConfig.groqReasoningModel}');
      final response = await http.post(
        Uri.parse('${EnvConfig.groqBaseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': EnvConfig.groqReasoningModel,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.1,
        }),
      ).timeout(AppConstants.aiRequestTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = json['choices'] as List<dynamic>;
        final msgMap = (choices[0] as Map<String, dynamic>)['message'] as Map<String, dynamic>;
        final text = msgMap['content'] as String;
        return _parseJson(text);
      } else {
        throw Exception('Groq HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[MatchingAI] Groq failed: $e → Gemini fallback');
      try {
        final response = await _geminiModel.generateContent([Content.text(prompt)]);
        final text = response.text ?? '';
        return _parseJson(text);
      } catch (e2) {
        debugPrint('[MatchingAI] Gemini fallback also failed: $e2');
        throw Exception('All AI providers failed for volunteer matching.');
      }
    }
  }

  Map<String, dynamic> _parseJson(String text) {
    final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }
}
